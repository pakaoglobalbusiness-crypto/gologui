import {
  Body,
  Controller,
  Get,
  Param,
  Patch,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { AuthGuard, CurrentUser } from '../auth/auth.guard';
import { ListingsService } from './listings.service';
import {
  CreateListingDto,
  SearchListingsDto,
  SetAvailabilityDto,
  UpdateListingDto,
} from './listings.dto';

@Controller('listings')
export class ListingsController {
  constructor(private listings: ListingsService) {}

  // Public : recherche et consultation (F2, F3)
  @Get()
  search(@Query() dto: SearchListingsDto) {
    return this.listings.search(dto);
  }

  @Get('mine')
  @UseGuards(AuthGuard)
  mine(@CurrentUser() user: any) {
    return this.listings.myListings(user.id);
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.listings.findOne(id);
  }

  @Get(':id/availability')
  availability(
    @Param('id') id: string,
    @Query('from') from?: string,
    @Query('to') to?: string,
  ) {
    return this.listings.getAvailability(id, from, to);
  }

  // Propriétaire (F10, F11)
  @Post()
  @UseGuards(AuthGuard)
  create(@CurrentUser() user: any, @Body() dto: CreateListingDto) {
    return this.listings.create(user.id, dto);
  }

  @Patch(':id')
  @UseGuards(AuthGuard)
  update(@CurrentUser() user: any, @Param('id') id: string, @Body() dto: UpdateListingDto) {
    return this.listings.update(user.id, id, dto);
  }

  @Post(':id/availability')
  @UseGuards(AuthGuard)
  setAvailability(
    @CurrentUser() user: any,
    @Param('id') id: string,
    @Body() dto: SetAvailabilityDto,
  ) {
    return this.listings.setAvailability(user.id, id, dto.dates, dto.status);
  }
}
