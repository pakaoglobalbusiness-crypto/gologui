import { Injectable, Logger } from '@nestjs/common';

// Envoi de SMS (OTP, notifications de réservation). Fournisseur choisi par
// SMS_PROVIDER : mock (dev) | orange (Orange SMS API Sénégal) | twilio.
// En mode mock, le message est simplement loggé et l'OTP est renvoyé dans
// la réponse API pour permettre les tests sans compte opérateur.
@Injectable()
export class SmsService {
  private readonly logger = new Logger(SmsService.name);
  private orangeToken?: { value: string; expiresAt: number };

  get provider(): string {
    return process.env.SMS_PROVIDER ?? 'mock';
  }

  get isMock(): boolean {
    return this.provider === 'mock';
  }

  async send(to: string, message: string): Promise<void> {
    switch (this.provider) {
      case 'orange':
        return this.sendOrange(to, message);
      case 'twilio':
        return this.sendTwilio(to, message);
      default:
        this.logger.log(`[SMS mock] → ${to} : ${message}`);
    }
  }

  // Orange SMS API (https://developer.orange.com/apis/sms-sn)
  private async sendOrange(to: string, message: string): Promise<void> {
    if (!this.orangeToken || this.orangeToken.expiresAt < Date.now()) {
      const auth = Buffer.from(
        `${process.env.ORANGE_SMS_CLIENT_ID}:${process.env.ORANGE_SMS_CLIENT_SECRET}`,
      ).toString('base64');
      const res = await fetch('https://api.orange.com/oauth/v3/token', {
        method: 'POST',
        headers: {
          Authorization: `Basic ${auth}`,
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: 'grant_type=client_credentials',
      });
      const data = (await res.json()) as { access_token: string; expires_in: number };
      this.orangeToken = {
        value: data.access_token,
        expiresAt: Date.now() + (data.expires_in - 60) * 1000,
      };
    }
    const sender = process.env.ORANGE_SMS_SENDER ?? '';
    const res = await fetch(
      `https://api.orange.com/smsmessaging/v1/outbound/tel%3A%2B${encodeURIComponent(
        sender.replace('+', ''),
      )}/requests`,
      {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${this.orangeToken.value}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          outboundSMSMessageRequest: {
            address: `tel:${to}`,
            senderAddress: `tel:${sender}`,
            outboundSMSTextMessage: { message },
          },
        }),
      },
    );
    if (!res.ok) {
      this.logger.error(`Orange SMS a échoué (${res.status}) pour ${to}`);
    }
  }

  private async sendTwilio(to: string, message: string): Promise<void> {
    const sid = process.env.TWILIO_ACCOUNT_SID;
    const auth = Buffer.from(`${sid}:${process.env.TWILIO_AUTH_TOKEN}`).toString('base64');
    const res = await fetch(
      `https://api.twilio.com/2010-04-01/Accounts/${sid}/Messages.json`,
      {
        method: 'POST',
        headers: {
          Authorization: `Basic ${auth}`,
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: new URLSearchParams({
          To: to,
          From: process.env.TWILIO_FROM ?? '',
          Body: message,
        }).toString(),
      },
    );
    if (!res.ok) {
      this.logger.error(`Twilio a échoué (${res.status}) pour ${to}`);
    }
  }
}
