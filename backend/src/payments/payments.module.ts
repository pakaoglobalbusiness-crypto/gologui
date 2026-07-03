import { Module } from '@nestjs/common';
import { BookingsModule } from '../bookings/bookings.module';
import { PaymentsController } from './payments.controller';
import { PaymentsService } from './payments.service';
import { MockPaymentProvider } from './providers/mock.provider';
import { PayDunyaProvider } from './providers/paydunya.provider';

@Module({
  imports: [BookingsModule],
  controllers: [PaymentsController],
  providers: [
    PaymentsService,
    {
      provide: 'PAYMENT_PROVIDER',
      useFactory: () =>
        (process.env.PAYMENT_PROVIDER ?? 'mock') === 'paydunya'
          ? new PayDunyaProvider()
          : new MockPaymentProvider(),
    },
  ],
})
export class PaymentsModule {}
