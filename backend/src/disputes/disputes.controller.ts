import { Body, Controller, Get, Post, UseGuards } from '@nestjs/common';
import { IsNotEmpty, IsString } from 'class-validator';
import { AuthGuard, CurrentUser } from '../auth/auth.guard';
import { DisputesService } from './disputes.service';

class OpenDisputeDto {
  @IsString() @IsNotEmpty() bookingId!: string;
  @IsString() @IsNotEmpty() reason!: string;
}

@Controller('disputes')
@UseGuards(AuthGuard)
export class DisputesController {
  constructor(private disputes: DisputesService) {}

  @Post()
  open(@CurrentUser() user: any, @Body() dto: OpenDisputeDto) {
    return this.disputes.open(user.id, dto.bookingId, dto.reason);
  }

  @Get('mine')
  mine(@CurrentUser() user: any) {
    return this.disputes.mine(user.id);
  }
}
