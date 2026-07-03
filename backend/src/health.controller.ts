import { Controller, Get, Inject } from '@nestjs/common';
import { PaymentProvider } from './payments/providers/payment-provider';

// Diagnostic public : quel fournisseur de paiement/SMS est actif.
// Aucune donnée sensible — uniquement les noms, jamais les clés.
@Controller('health')
export class HealthController {
  constructor(@Inject('PAYMENT_PROVIDER') private payment: PaymentProvider) {}

  @Get()
  health() {
    return {
      status: 'ok',
      paymentProvider: this.payment.name,
      paydunyaMode: this.payment.name === 'paydunya' ? process.env.PAYDUNYA_MODE : undefined,
      smsProvider: process.env.SMS_PROVIDER ?? 'mock',
      paymentProviderRaw: process.env.PAYMENT_PROVIDER ?? '(non défini)',
      paydunyaKeysPresent: {
        masterKey: !!process.env.PAYDUNYA_MASTER_KEY,
        privateKey: !!process.env.PAYDUNYA_PRIVATE_KEY,
        token: !!process.env.PAYDUNYA_TOKEN,
      },
    };
  }
}
