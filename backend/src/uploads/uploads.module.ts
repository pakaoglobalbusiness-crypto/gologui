import { Module } from '@nestjs/common';
import { UploadsController } from './uploads.controller';
import { PrismaService } from '../prisma.service';

@Module({
  controllers: [UploadsController],
  providers: [PrismaService],
})
export class UploadsModule {}
