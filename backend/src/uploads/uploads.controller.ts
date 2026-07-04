import { extname, join } from 'path';
import {
  BadRequestException,
  Controller,
  Get,
  NotFoundException,
  Param,
  Post,
  Req,
  Res,
  UploadedFile,
  UseGuards,
  UseInterceptors,
} from '@nestjs/common';
import { SkipThrottle } from '@nestjs/throttler';
import type { Response } from 'express';
import { FileInterceptor } from '@nestjs/platform-express';
import { memoryStorage } from 'multer';
import { AuthGuard } from '../auth/auth.guard';
import { PrismaService } from '../prisma.service';

// Upload de photos (annonces, KYC, états des lieux, profil, chat).
// Les fichiers sont stockés dans PostgreSQL (table UploadedFile) : ils
// SURVIVENT aux redéploiements, contrairement au disque éphémère de Render.
// Pour une montée en charge : migrer vers S3/R2 (le contrat ne change pas).
export const UPLOADS_DIR = join(process.cwd(), 'uploads'); // conservé pour compat

const ALLOWED = ['.jpg', '.jpeg', '.png', '.webp', '.pdf'];
const MIME: Record<string, string> = {
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.png': 'image/png',
  '.webp': 'image/webp',
  '.pdf': 'application/pdf',
};

@Controller()
export class UploadsController {
  constructor(private prisma: PrismaService) {}

  @Post('uploads')
  @UseGuards(AuthGuard)
  @UseInterceptors(
    FileInterceptor('file', {
      storage: memoryStorage(),
      limits: { fileSize: 8 * 1024 * 1024 }, // 8 Mo
      fileFilter: (_req, file, cb) => {
        const ext = extname(file.originalname).toLowerCase();
        cb(
          ALLOWED.includes(ext)
            ? null
            : new BadRequestException(`Format non accepté : ${ext}`),
          ALLOWED.includes(ext),
        );
      },
    }),
  )
  async upload(@Req() req: any, @UploadedFile() file?: Express.Multer.File) {
    if (!file) throw new BadRequestException('Aucun fichier reçu (champ « file »)');
    const ext = extname(file.originalname).toLowerCase() || '.jpg';
    const saved = await this.prisma.uploadedFile.create({
      data: {
        mimeType: MIME[ext] ?? 'application/octet-stream',
        data: new Uint8Array(file.buffer),
      },
      select: { id: true },
    });
    const base = `${req.protocol}://${req.get('host')}`;
    return { url: `${base}/api/v1/files/${saved.id}`, size: file.size };
  }

  // Lecture publique d'un fichier stocké (image d'annonce, avatar…).
  // SkipThrottle : une galerie charge plusieurs images d'un coup.
  @Get('files/:id')
  @SkipThrottle()
  async serve(@Param('id') id: string, @Res() res: Response) {
    const f = await this.prisma.uploadedFile.findUnique({ where: { id } });
    if (!f) throw new NotFoundException('Fichier introuvable');
    res.setHeader('Content-Type', f.mimeType);
    res.setHeader('Cache-Control', 'public, max-age=31536000, immutable');
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.send(f.data);
  }
}
