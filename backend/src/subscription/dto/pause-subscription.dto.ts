import { IsBoolean } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class PauseSubscriptionDto {
  @ApiProperty({ description: 'True to pause subscription, false to resume/activate', example: true })
  @IsBoolean()
  paused: boolean;
}
