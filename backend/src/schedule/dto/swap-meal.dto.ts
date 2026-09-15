import { IsNotEmpty, IsString } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class SwapMealDto {
  @ApiProperty({
    description: 'Target MealCatalog ID to swap to',
    example: '6640c1a2f1839a5840d8a202',
  })
  @IsNotEmpty()
  @IsString()
  mealId: string;
}
