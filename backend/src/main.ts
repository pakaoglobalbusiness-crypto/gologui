import { mkdirSync } from 'fs';
import { NestFactory } from '@nestjs/core';
import { NestExpressApplication } from '@nestjs/platform-express';
import { ValidationPipe } from '@nestjs/common';
import helmet from 'helmet';
import { json } from 'express';
import { AppModule } from './app.module';
import { UPLOADS_DIR } from './uploads/uploads.controller';

async function bootstrap() {
  if (process.env.NODE_ENV === 'production' && !process.env.JWT_SECRET) {
    throw new Error('JWT_SECRET est obligatoire en production');
  }
  const app = await NestFactory.create<NestExpressApplication>(AppModule);
  app.setGlobalPrefix('api/v1');
  // Derrière le proxy Render : req.protocol doit refléter X-Forwarded-Proto
  // (sinon les URLs d'upload sont générées en http:// et bloquées en https).
  app.set('trust proxy', 1);
  mkdirSync(UPLOADS_DIR, { recursive: true });
  app.useStaticAssets(UPLOADS_DIR, {
    prefix: '/uploads',
    // CORS explicite : Flutter web (CanvasKit) charge les images via fetch
    setHeaders: (res) => res.setHeader('Access-Control-Allow-Origin', '*'),
  });
  app.use(helmet({ crossOriginResourcePolicy: { policy: 'cross-origin' } }));
  app.use(json({ limit: '2mb' }));
  app.enableCors({ origin: process.env.CORS_ORIGINS?.split(',') ?? true });
  app.useGlobalPipes(new ValidationPipe({ whitelist: true, transform: true }));
  const port = process.env.PORT ?? 3000;
  await app.listen(port);
  console.log(`Gologui API démarrée sur http://localhost:${port}/api/v1`);
}
bootstrap();
