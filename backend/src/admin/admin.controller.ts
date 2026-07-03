import {
  Body,
  Controller,
  Get,
  Param,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import {
  IsBoolean,
  IsIn,
  IsInt,
  IsNotEmpty,
  IsOptional,
  IsString,
  Min,
} from 'class-validator';
import { AuthGuard, CurrentUser, Roles } from '../auth/auth.guard';
import { AdminService } from './admin.service';

class ModerateDto {
  @IsIn(['approve', 'reject', 'suspend']) decision!: 'approve' | 'reject' | 'suspend';
}

class KycDecisionDto {
  @IsIn(['approve', 'reject']) decision!: 'approve' | 'reject';
}

class BlockDto {
  @IsBoolean() blocked!: boolean;
}

class ResolveDisputeDto {
  @IsIn(['resolved', 'rejected']) decision!: 'resolved' | 'rejected';
  @IsString() @IsNotEmpty() resolution!: string;
  @IsOptional() @IsInt() @Min(0) refundFcfa?: number;
}

@Controller('admin')
@UseGuards(AuthGuard)
@Roles('admin')
export class AdminController {
  constructor(private admin: AdminService) {}

  @Get('stats')
  stats() {
    return this.admin.stats();
  }

  @Get('listings/moderation')
  moderation() {
    return this.admin.listingsToModerate();
  }

  @Post('listings/:id/moderate')
  moderate(@Param('id') id: string, @Body() dto: ModerateDto) {
    return this.admin.moderateListing(id, dto.decision);
  }

  @Get('kyc/pending')
  pendingKyc() {
    return this.admin.pendingKyc();
  }

  @Post('kyc/:docId/review')
  reviewKyc(
    @CurrentUser() user: any,
    @Param('docId') docId: string,
    @Body() dto: KycDecisionDto,
  ) {
    return this.admin.reviewKyc(docId, user.id, dto.decision);
  }

  @Get('users')
  users(@Query('q') q?: string) {
    return this.admin.users(q);
  }

  @Post('users/:id/block')
  block(@Param('id') id: string, @Body() dto: BlockDto) {
    return this.admin.setUserBlocked(id, dto.blocked);
  }

  @Get('disputes')
  disputes() {
    return this.admin.openDisputes();
  }

  @Post('disputes/:id/resolve')
  resolve(@Param('id') id: string, @Body() dto: ResolveDisputeDto) {
    return this.admin.resolveDispute(id, dto.decision, dto.resolution, dto.refundFcfa);
  }
}
