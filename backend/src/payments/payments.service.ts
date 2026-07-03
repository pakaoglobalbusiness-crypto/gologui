import {
  BadRequestException,
  ForbiddenException,
  Inject,
  Injectable,
  NotFoundException,
  UnauthorizedException,
} from '@nestjs/common';
import { PrismaService } from '../prisma.service';
import { BookingsService } from '../bookings/bookings.service';
import { PaymentProvider } from './providers/payment-provider';
import { PAYMENT_METHODS } from '../common/constants';

// L'agrégateur réel (PayDunya) ou simulé est choisi par PAYMENT_PROVIDER.
// En mode mock, initiate() confirme automatiquement après 2 s pour
// fluidifier les démos ; en prod, c'est le webhook signé de l'agrégateur
// qui confirme.
@Injectable()
export class PaymentsService {
  constructor(
    private prisma: PrismaService,
    private bookings: BookingsService,
    @Inject('PAYMENT_PROVIDER') private provider: PaymentProvider,
  ) {}

  async initiate(renterId: string, bookingId: string, method: string) {
    if (!PAYMENT_METHODS.includes(method as any)) {
      throw new BadRequestException(`Moyen de paiement inconnu : ${method}`);
    }
    const booking = await this.prisma.booking.findUnique({
      where: { id: bookingId },
      include: { listing: true },
    });
    if (!booking) throw new NotFoundException('Réservation introuvable');
    if (booking.renterId !== renterId) throw new ForbiddenException();
    if (booking.status !== 'accepted') {
      throw new BadRequestException(
        'La réservation doit être acceptée par le propriétaire avant paiement',
      );
    }

    const reference = `sy_${bookingId.slice(-6)}_${Date.now()}`;
    const renter = await this.prisma.user.findUniqueOrThrow({ where: { id: renterId } });
    const { aggregatorRef, paymentUrl } = await this.provider.initiate({
      reference,
      amountFcfa: booking.totalPriceFcfa,
      method,
      description: `Location « ${booking.listing.title} »`,
      customerPhone: renter.phone,
    });

    const payment = await this.prisma.payment.create({
      data: {
        bookingId,
        method,
        aggregatorRef,
        amountFcfa: booking.totalPriceFcfa,
        kind: 'rental',
        status: 'initiated',
      },
    });

    if (this.provider.name === 'mock') {
      setTimeout(() => {
        this.handleWebhook(aggregatorRef, 'confirmed', { mock: true }).catch((e) =>
          console.error('[Paiement mock] échec confirmation auto:', e.message),
        );
      }, 2000);
    }

    return {
      paymentId: payment.id,
      aggregatorRef,
      amountFcfa: booking.totalPriceFcfa,
      method,
      paymentUrl,
      status: 'initiated',
    };
  }

  assertWebhookAuthentic(headers: Record<string, string>, rawBody: string) {
    if (!this.provider.verifyWebhook(headers, rawBody)) {
      throw new UnauthorizedException('Signature du webhook invalide');
    }
  }

  async handleWebhook(aggregatorRef: string, status: string, payload: unknown) {
    const payment = await this.prisma.payment.findUnique({
      where: { aggregatorRef },
    });
    if (!payment) throw new NotFoundException('Référence inconnue');
    if (payment.status === 'confirmed') return { ok: true, alreadyProcessed: true };

    await this.prisma.payment.update({
      where: { id: payment.id },
      data: { status, webhookPayload: JSON.stringify(payload ?? {}) },
    });

    if (status === 'confirmed' && payment.kind === 'rental') {
      await this.bookings.markPaid(payment.bookingId);
      console.log(
        `[Notif mock] Paiement ${aggregatorRef} confirmé — réservation ${payment.bookingId} payée, fonds séquestrés`,
      );
    }
    return { ok: true };
  }

  async status(renterId: string, paymentId: string) {
    const payment = await this.prisma.payment.findUnique({
      where: { id: paymentId },
      include: { booking: true },
    });
    if (!payment) throw new NotFoundException();
    if (payment.booking.renterId !== renterId) throw new ForbiddenException();
    return {
      id: payment.id,
      status: payment.status,
      bookingStatus: payment.booking.status,
    };
  }

  async myPayouts(ownerId: string) {
    return this.prisma.payout.findMany({
      where: { ownerId },
      include: { booking: { include: { listing: { select: { title: true } } } } },
      orderBy: { createdAt: 'desc' },
    });
  }
}
