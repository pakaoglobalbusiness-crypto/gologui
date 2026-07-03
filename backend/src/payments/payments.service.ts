import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../prisma.service';
import { BookingsService } from '../bookings/bookings.service';
import { PAYMENT_METHODS } from '../common/constants';

// Agrégateur de paiement SIMULÉ (PayDunya/CinetPay/Paystack en prod).
// initiate() renvoie une référence + une URL de paiement fictive ;
// le webhook /payments/webhook simule la confirmation de l'agrégateur.
// En mode mock (PAYMENT_PROVIDER=mock, défaut), initiate() confirme
// automatiquement après 2 s pour fluidifier les démos.
@Injectable()
export class PaymentsService {
  constructor(
    private prisma: PrismaService,
    private bookings: BookingsService,
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

    const ref = `sy_${bookingId.slice(-6)}_${Date.now()}`;
    const payment = await this.prisma.payment.create({
      data: {
        bookingId,
        method,
        aggregatorRef: ref,
        amountFcfa: booking.totalPriceFcfa,
        kind: 'rental',
        status: 'initiated',
      },
    });

    if ((process.env.PAYMENT_PROVIDER ?? 'mock') === 'mock') {
      setTimeout(() => {
        this.handleWebhook(ref, 'confirmed', { mock: true }).catch((e) =>
          console.error('[Paiement mock] échec confirmation auto:', e.message),
        );
      }, 2000);
    }

    return {
      paymentId: payment.id,
      aggregatorRef: ref,
      amountFcfa: booking.totalPriceFcfa,
      method,
      // En prod : URL de redirection PayDunya/CinetPay ou push USSD Wave/OM
      paymentUrl: `https://pay.mock.sunuyeuf.sn/checkout/${ref}`,
      status: 'initiated',
    };
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
