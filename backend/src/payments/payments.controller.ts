import { Body, Controller, Get, Param, Post, UseGuards } from '@nestjs/common';
import { IsIn, IsNotEmpty, IsObject, IsOptional, IsString } from 'class-validator';
import { AuthGuard, CurrentUser } from '../auth/auth.guard';
import { PaymentsService } from './payments.service';
import { PAYMENT_METHODS } from '../common/constants';

class InitiatePaymentDto {
  @IsString() @IsNotEmpty() bookingId!: string;
  @IsIn(PAYMENT_METHODS as unknown as string[]) method!: string;
}

class WebhookDto {
  @IsString() @IsNotEmpty() aggregatorRef!: string;
  @IsIn(['confirmed', 'failed']) status!: string;
  @IsOptional() @IsObject() payload?: Record<string, unknown>;
}

@Controller('payments')
export class PaymentsController {
  constructor(private payments: PaymentsService) {}

  @Post('initiate')
  @UseGuards(AuthGuard)
  initiate(@CurrentUser() user: any, @Body() dto: InitiatePaymentDto) {
    return this.payments.initiate(user.id, dto.bookingId, dto.method);
  }

  // Webhook agrégateur — non authentifié par JWT ; en prod, vérifier la
  // signature HMAC de l'agrégateur.
  @Post('webhook')
  webhook(@Body() dto: WebhookDto) {
    return this.payments.handleWebhook(dto.aggregatorRef, dto.status, dto.payload);
  }

  @Get('payouts/mine')
  @UseGuards(AuthGuard)
  myPayouts(@CurrentUser() user: any) {
    return this.payments.myPayouts(user.id);
  }

  @Get(':id/status')
  @UseGuards(AuthGuard)
  status(@CurrentUser() user: any, @Param('id') id: string) {
    return this.payments.status(user.id, id);
  }
}
