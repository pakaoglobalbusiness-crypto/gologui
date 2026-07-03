import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma.service';

// Back-office (F19–F21) : modération, KYC, litiges, blocages, statistiques
@Injectable()
export class AdminService {
  constructor(private prisma: PrismaService) {}

  listingsToModerate() {
    return this.prisma.listing.findMany({
      where: { status: 'in_moderation' },
      include: {
        photos: true,
        villaDetails: true,
        carDetails: true,
        owner: { select: { id: true, name: true, phone: true, kycStatus: true } },
      },
      orderBy: { createdAt: 'asc' },
    });
  }

  async moderateListing(id: string, decision: 'approve' | 'reject' | 'suspend') {
    const status =
      decision === 'approve' ? 'published' : decision === 'suspend' ? 'suspended' : 'draft';
    const listing = await this.prisma.listing.update({ where: { id }, data: { status } });
    console.log(`[Notif mock] Annonce ${id} → ${status}, propriétaire notifié`);
    return listing;
  }

  pendingKyc() {
    return this.prisma.kycDocument.findMany({
      where: { status: 'pending' },
      include: { user: { select: { id: true, name: true, phone: true } } },
      orderBy: { createdAt: 'asc' },
    });
  }

  async reviewKyc(docId: string, adminId: string, decision: 'approve' | 'reject') {
    const doc = await this.prisma.kycDocument.update({
      where: { id: docId },
      data: {
        status: decision === 'approve' ? 'approved' : 'rejected',
        verifiedBy: adminId,
        verifiedAt: new Date(),
      },
    });
    // L'utilisateur passe "verified" quand plus aucun document n'est en attente
    // et qu'au moins un est approuvé ; "rejected" si un document est refusé.
    const docs = await this.prisma.kycDocument.findMany({ where: { userId: doc.userId } });
    const kycStatus = docs.some((d) => d.status === 'rejected')
      ? 'rejected'
      : docs.some((d) => d.status === 'pending')
        ? 'pending'
        : 'verified';
    await this.prisma.user.update({ where: { id: doc.userId }, data: { kycStatus } });
    return doc;
  }

  users(q?: string) {
    return this.prisma.user.findMany({
      where: q
        ? { OR: [{ phone: { contains: q } }, { name: { contains: q } }] }
        : undefined,
      orderBy: { createdAt: 'desc' },
      take: 100,
    });
  }

  setUserBlocked(id: string, blocked: boolean) {
    return this.prisma.user.update({ where: { id }, data: { blocked } });
  }

  openDisputes() {
    return this.prisma.dispute.findMany({
      where: { status: 'open' },
      include: {
        booking: {
          include: {
            listing: { select: { title: true, ownerId: true } },
            renter: { select: { id: true, name: true, phone: true } },
          },
        },
        openedBy: { select: { id: true, name: true } },
      },
      orderBy: { createdAt: 'asc' },
    });
  }

  async resolveDispute(
    id: string,
    decision: 'resolved' | 'rejected',
    resolution: string,
    refundFcfa?: number,
  ) {
    const dispute = await this.prisma.dispute.findUnique({
      where: { id },
      include: { booking: { include: { payments: true } } },
    });
    if (!dispute) throw new NotFoundException('Litige introuvable');

    if (refundFcfa && refundFcfa > 0) {
      const method = dispute.booking.payments[0]?.method ?? 'wave';
      await this.prisma.payment.create({
        data: {
          bookingId: dispute.bookingId,
          method,
          aggregatorRef: `dispute_refund_${id}_${Date.now()}`,
          amountFcfa: refundFcfa,
          kind: 'refund',
          status: 'confirmed',
        },
      });
    }
    if (dispute.booking.status === 'disputed') {
      await this.prisma.booking.update({
        where: { id: dispute.bookingId },
        data: { status: decision === 'resolved' ? 'completed' : 'cancelled' },
      });
    }
    return this.prisma.dispute.update({
      where: { id },
      data: { status: decision, resolution, resolvedAt: new Date() },
    });
  }

  async stats() {
    const [users, listings, published, bookings, confirmedPayments, disputes] =
      await Promise.all([
        this.prisma.user.count(),
        this.prisma.listing.count(),
        this.prisma.listing.count({ where: { status: 'published' } }),
        this.prisma.booking.count(),
        this.prisma.payment.findMany({
          where: { status: 'confirmed', kind: 'rental' },
          select: { amountFcfa: true, booking: { select: { commissionFcfa: true, listing: { select: { city: true } } } } },
        }),
        this.prisma.dispute.count({ where: { status: 'open' } }),
      ]);

    const gmvFcfa = confirmedPayments.reduce((s, p) => s + p.amountFcfa, 0);
    const commissionFcfa = confirmedPayments.reduce(
      (s, p) => s + p.booking.commissionFcfa,
      0,
    );
    const byCity: Record<string, number> = {};
    for (const p of confirmedPayments) {
      const city = p.booking.listing.city;
      byCity[city] = (byCity[city] ?? 0) + p.amountFcfa;
    }
    const topCities = Object.entries(byCity)
      .sort((a, b) => b[1] - a[1])
      .map(([city, gmv]) => ({ city, gmvFcfa: gmv }));

    return {
      users,
      listings,
      publishedListings: published,
      bookings,
      paidBookings: confirmedPayments.length,
      gmvFcfa,
      commissionFcfa,
      openDisputes: disputes,
      topCities,
    };
  }
}
