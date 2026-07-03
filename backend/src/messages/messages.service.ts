import {
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../prisma.service';

// Messagerie liée à une réservation (F6). Le numéro de téléphone reste masqué :
// seule la conversation interne permet le contact avant confirmation (spec §7).
@Injectable()
export class MessagesService {
  constructor(private prisma: PrismaService) {}

  private async assertParticipant(conversationId: string, userId: string) {
    const conv = await this.prisma.conversation.findUnique({
      where: { id: conversationId },
      include: { booking: { include: { listing: true } } },
    });
    if (!conv) throw new NotFoundException('Conversation introuvable');
    if (conv.booking.renterId !== userId && conv.booking.listing.ownerId !== userId) {
      throw new ForbiddenException();
    }
    return conv;
  }

  async myConversations(userId: string) {
    return this.prisma.conversation.findMany({
      where: {
        booking: {
          OR: [{ renterId: userId }, { listing: { ownerId: userId } }],
        },
      },
      include: {
        booking: {
          include: {
            listing: { select: { id: true, title: true, type: true, ownerId: true } },
            renter: { select: { id: true, name: true, photoUrl: true } },
          },
        },
        messages: { orderBy: { createdAt: 'desc' }, take: 1 },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  async getMessages(userId: string, conversationId: string) {
    await this.assertParticipant(conversationId, userId);
    await this.prisma.message.updateMany({
      where: { conversationId, senderId: { not: userId }, readAt: null },
      data: { readAt: new Date() },
    });
    return this.prisma.message.findMany({
      where: { conversationId },
      include: { sender: { select: { id: true, name: true, photoUrl: true } } },
      orderBy: { createdAt: 'asc' },
    });
  }

  async send(userId: string, conversationId: string, body: string, photoUrl?: string) {
    await this.assertParticipant(conversationId, userId);
    const message = await this.prisma.message.create({
      data: { conversationId, senderId: userId, body, photoUrl },
      include: { sender: { select: { id: true, name: true, photoUrl: true } } },
    });
    console.log(`[Notif mock] Push nouveau message dans ${conversationId}`);
    return message;
  }
}
