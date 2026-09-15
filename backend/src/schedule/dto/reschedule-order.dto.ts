import { IsNotEmpty, Matches } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class RescheduleOrderDto {
  @ApiProperty({
    description: 'Target delivery date in YYYY-MM-DD (preserves current slot)',
    example: '2026-09-19',
  })
  @IsNotEmpty()
  @Matches(/^\d{4}-\d{2}-\d{2}$/, { message: 'date must be in YYYY-MM-DD format' })
  date: string;
}
