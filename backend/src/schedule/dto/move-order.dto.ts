import { IsEnum, IsNotEmpty, Matches } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';
import { MealSlot } from '../../common/enums/meal-slot.enum';

export class MoveOrderDto {
  @ApiProperty({
    description: 'Target delivery date in YYYY-MM-DD',
    example: '2026-09-18',
  })
  @IsNotEmpty()
  @Matches(/^\d{4}-\d{2}-\d{2}$/, { message: 'date must be in YYYY-MM-DD format' })
  date: string;

  @ApiProperty({
    description: 'Target meal slot',
    enum: MealSlot,
    example: MealSlot.LUNCH,
  })
  @IsNotEmpty()
  @IsEnum(MealSlot, { message: 'slot must be one of: breakfast, lunch, dinner' })
  slot: MealSlot;
}
