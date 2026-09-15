import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { CutoffService } from './cutoff.service';

@Module({
  imports: [ConfigModule],
  providers: [CutoffService],
  exports: [CutoffService],
})
export class CutoffModule {}
