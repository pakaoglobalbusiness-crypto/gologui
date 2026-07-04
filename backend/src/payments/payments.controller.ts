import {
  BadRequestException,
  Body,
  Controller,
  Get,
  Param,
  Post,
  Req,
  UseGuards,
} from '@nestjs/common';
import {
  IsIn,
  IsInt,
  IsNotEmpty,
  IsObject,
  IsOptional,
  IsString,
  Min,
} from 'class-validator';
import { AuthGuard, CurrentUser } from '../auth/auth.guard';
import { PaymentsService } from './payments.service';
import { PAYMENT_METHODS } from '../common/constants';

class InitiatePaymentDto {
  @IsString() @IsNotEmpty() bookingId!: string;
  @IsIn(PAYMENT_METHODS as unknown as string[]) method!: string;
}

class WithdrawalDto {
  @IsInt() @Min(1000) amountFcfa!: number;
  @IsIn(['wave', 'orange_money', 'bank']) method!: string;
  @IsString() @IsNotEmpty() account!: string;
  @IsString() @IsNotEmpty() name!: string;
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

  // Webhook générique (format interne, utilisé par le mode mock et les tests).
  @Post('webhook')
  webhook(@Req() req: any, @Body() dto: WebhookDto) {
    this.payments.assertWebhookAuthentic(req.headers, JSON.stringify(dto));
    return this.payments.handleWebhook(dto.aggregatorRef, dto.status, dto.payload);
  }

  // IPN PayDunya (https://developers.paydunya.com — « Instant Payment
  // Notification ») : POST form-encodé { data: { invoice: { token },
  // status: 'completed'|'cancelled'|'failed', hash } }. Le hash (SHA-512 de
  // la master key) est vérifié par le provider. C'est cette URL qu'il faut
  // mettre dans PAYMENT_CALLBACK_URL.
  @Post('webhook/paydunya')
  webhookPaydunya(@Req() req: any, @Body() body: Record<string, any>) {
    this.payments.assertWebhookAuthentic(req.headers, JSON.stringify(body));
    const data = body?.data ?? body;
    const token: string | undefined = data?.invoice?.token;
    if (!token) throw new BadRequestException('Token de facture PayDunya absent');
    const status = data?.status === 'completed' ? 'confirmed' : 'failed';
    return this.payments.handleWebhook(token, status, body);
  }

  @Get('payouts/mine')
  @UseGuards(AuthGuard)
  myPayouts(@CurrentUser() user: any) {
    return this.payments.myPayouts(user.id);
  }

  // Portefeuille : solde + retraits
  @Get('balance')
  @UseGuards(AuthGuard)
  balance(@CurrentUser() user: any) {
    return this.payments.balance(user.id);
  }

  @Post('withdrawals')
  @UseGuards(AuthGuard)
  withdraw(@CurrentUser() user: any, @Body() dto: WithdrawalDto) {
    return this.payments.requestWithdrawal(
      user.id,
      dto.amountFcfa,
      dto.method,
      dto.account,
      dto.name,
    );
  }

  @Get('withdrawals/mine')
  @UseGuards(AuthGuard)
  myWithdrawals(@CurrentUser() user: any) {
    return this.payments.myWithdrawals(user.id);
  }

  @Get(':id/status')
  @UseGuards(AuthGuard)
  status(@CurrentUser() user: any, @Param('id') id: string) {
    return this.payments.status(user.id, id);
  }
}
