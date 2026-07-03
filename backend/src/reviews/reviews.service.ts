import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../prisma.service';

// Avis bidirectionnels après la fin de la location (F8, module 7)
@Injectable()
export class ReviewsService {
  constructor(private prisma: PrismaService) {}

  async create(authorId: string, bookingId: string, rating: number, comment?: string) {
    const booking = await this.prisma.booking.findUnique({
      where: { id: bookingId },
      include: { listing: true },
    });
    if (!booking) throw new NotFoundException('Réservation introuvable');
    if (booking.status !== 'completed') {
      throw new BadRequestException('Avis possible uniquement après la fin de la location');
    }

    const isRenter = booking.renterId === authorId;
    const isOwner = booking.listing.ownerId === authorId;
    if (!isRenter && !isOwner) throw new ForbiddenException();
    const targetId = isRenter ? booking.listing.ownerId : booking.renterId;

    const existing = await this.prisma.review.findUnique({
      where: { bookingId_authorId: { bookingId, authorId } },
    });
    if (existing) throw new ConflictException('Avis déjà déposé');

    const review = await this.prisma.review.create({
      data: { bookingId, authorId, targetId, rating, comment },
    });

    // Recalcul des moyennes (utilisateur cible + annonce si avis du locataire)
    const targetAgg = await this.prisma.review.aggregate({
      where: { targetId },
      _avg: { rating: true },
      _count: true,
    });
    await this.prisma.user.update({
      where: { id: targetId },
      data: {
        avgRating: Math.round((targetAgg._avg.rating ?? 0) * 10) / 10,
        ratingCount: targetAgg._count,
      },
    });

    if (isRenter) {
      const listingAgg = await this.prisma.review.aggregate({
        where: {
          booking: { listingId: booking.listingId },
          authorId: { not: booking.listing.ownerId },
        },
        _avg: { rating: true },
        _count: true,
      });
      await this.prisma.listing.update({
        where: { id: booking.listingId },
        data: {
          avgRating: Math.round((listingAgg._avg.rating ?? 0) * 10) / 10,
          ratingCount: listingAgg._count,
        },
      });
    }
    return review;
  }

  async forListing(listingId: string) {
    return this.prisma.review.findMany({
      where: {
        booking: { listingId },
        author: { listings: { none: { id: listingId } } }, // avis des locataires uniquement
      },
      include: { author: { select: { name: true, photoUrl: true } } },
      orderBy: { createdAt: 'desc' },
    });
  }
}
