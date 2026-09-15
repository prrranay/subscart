import { IsOptional, Matches } from 'class-validator';
import { ApiPropertyOptional } from '@nestjs/swagger';

export class GetScheduleQueryDto {
  @ApiPropertyOptional({
    description: 'Start date in user local timezone (YYYY-MM-DD)',
    example: '2026-09-14',
  })
  @IsOptional()
  @Matches(/^\d{4}-\d{2}-\d{2}$/, { message: 'startDate must be in YYYY-MM-DD format' })
  startDate?: string;

  @ApiPropertyOptional({
    description: 'End date in user local timezone (YYYY-MM-DD)',
    example: '2026-09-20',
  })
  @IsOptional()
  @Matches(/^\d{4}-\d{2}-\d{2}$/, { message: 'endDate must be in YYYY-MM-DD format' })
  endDate?: string;
}
