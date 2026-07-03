import { randomBytes } from 'crypto';
import { extname, join } from 'path';
import {
  BadRequestException,
  Controller,
  Post,
  Req,
  UploadedFile,
  UseGuards,
  UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { diskStorage } from 'multer';
import { AuthGuard } from '../auth/auth.guard';

// Upload de photos (annonces, KYC, états des lieux, chat).
// Dev : stockage disque local dans ./uploads, servi statiquement sur
// /uploads. Prod : remplacer diskStorage par un storage S3 (multer-s3)
// et renvoyer l'URL CDN — le contrat de l'endpoint ne change pas.
export const UPLOADS_DIR = join(process.cwd(), 'uploads');

const ALLOWED = ['.jpg', '.jpeg', '.png', '.webp', '.pdf'];

@Controller('uploads')
export class UploadsController {
  @Post()
  @UseGuards(AuthGuard)
  @UseInterceptors(
    FileInterceptor('file', {
      storage: diskStorage({
        destination: UPLOADS_DIR,
        filename: (_req, file, cb) => {
          const ext = extname(file.originalname).toLowerCase() || '.jpg';
          cb(null, `${Date.now()}_${randomBytes(6).toString('hex')}${ext}`);
        },
      }),
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
  upload(@Req() req: any, @UploadedFile() file?: Express.Multer.File) {
    if (!file) throw new BadRequestException('Aucun fichier reçu (champ « file »)');
    const base = `${req.protocol}://${req.get('host')}`;
    return { url: `${base}/uploads/${file.filename}`, size: file.size };
  }
}
