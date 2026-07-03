import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../prisma.service';

// Litiges (F20, module 9) : ouverture par une des parties, arbitrage admin
@Injectable()
export class DisputesService {
  constructor(private prisma: PrismaService) {}

  async open(userId: string, bookingId: string, reason: string) {
    const booking = await this.prisma.booking.findUnique({
      where: { id: bookingId },
      include: { listing: true },
    });
    if (!booking) throw new NotFoundException('Réservation introuvable');
    if (booking.renterId !== userId && booking.listing.ownerId !== userId) {
      throw new ForbiddenException();
    }
    if (!['paid', 'ongoing', 'completed'].includes(booking.status)) {
      throw new BadRequestException('Litige possible uniquement sur une location payée');
    }

    const dispute = await this.prisma.dispute.create({
      data: { bookingId, openedById: userId, reason },
    });
    if (booking.status !== 'completed') {
      await this.prisma.booking.update({
        where: { id: bookingId },
        data: { status: 'disputed' },
      });
    }
    console.log(`[Notif mock] Litige ouvert sur ${bookingId} — équipe support alertée`);
    return dispute;
  }

  async mine(userId: string) {
    return this.prisma.dispute.findMany({
      where: {
        booking: { OR: [{ renterId: userId }, { listing: { ownerId: userId } }] },
      },
      include: { booking: { include: { listing: { select: { title: true } } } } },
      orderBy: { createdAt: 'desc' },
    });
  }
}
