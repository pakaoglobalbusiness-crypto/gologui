import { Body, Controller, Get, Param, Post, UseGuards } from '@nestjs/common';
import { IsNotEmpty, IsOptional, IsString } from 'class-validator';
import { AuthGuard, CurrentUser } from '../auth/auth.guard';
import { MessagesService } from './messages.service';

class SendMessageDto {
  @IsString() @IsNotEmpty() body!: string;
  @IsOptional() @IsString() photoUrl?: string;
}

@Controller('conversations')
@UseGuards(AuthGuard)
export class MessagesController {
  constructor(private messages: MessagesService) {}

  @Get()
  mine(@CurrentUser() user: any) {
    return this.messages.myConversations(user.id);
  }

  @Get(':id/messages')
  getMessages(@CurrentUser() user: any, @Param('id') id: string) {
    return this.messages.getMessages(user.id, id);
  }

  @Post(':id/messages')
  send(@CurrentUser() user: any, @Param('id') id: string, @Body() dto: SendMessageDto) {
    return this.messages.send(user.id, id, dto.body, dto.photoUrl);
  }
}
