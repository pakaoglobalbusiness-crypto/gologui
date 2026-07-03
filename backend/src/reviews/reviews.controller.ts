import { Body, Controller, Get, Param, Post, UseGuards } from '@nestjs/common';
import { IsInt, IsNotEmpty, IsOptional, IsString, Max, Min } from 'class-validator';
import { AuthGuard, CurrentUser } from '../auth/auth.guard';
import { ReviewsService } from './reviews.service';

class CreateReviewDto {
  @IsString() @IsNotEmpty() bookingId!: string;
  @IsInt() @Min(1) @Max(5) rating!: number;
  @IsOptional() @IsString() comment?: string;
}

@Controller('reviews')
export class ReviewsController {
  constructor(private reviews: ReviewsService) {}

  @Post()
  @UseGuards(AuthGuard)
  create(@CurrentUser() user: any, @Body() dto: CreateReviewDto) {
    return this.reviews.create(user.id, dto.bookingId, dto.rating, dto.comment);
  }

  @Get('listing/:listingId')
  forListing(@Param('listingId') listingId: string) {
    return this.reviews.forListing(listingId);
  }
}
