import { Controller, Post, Body, Get } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { ApiTags, ApiOperation, ApiResponse } from '@nestjs/swagger';
import { SubscriptionService } from './subscription.service';
import { PauseSubscriptionDto } from './dto/pause-subscription.dto';

@ApiTags('Subscription')
@Controller('subscription')
export class SubscriptionController {
  private readonly demoUserId: string;

  constructor(
    private readonly subscriptionService: SubscriptionService,
    private readonly configService: ConfigService,
  ) {
    this.demoUserId = this.configService.get<string>(
      'DEMO_USER_ID',
      '6640c1a2f1839a5840d8a101',
    );
  }

  @Get()
  @ApiOperation({ summary: 'Get current user subscription details' })
  async getSubscription() {
    const sub = await this.subscriptionService.getSubscriptionForUser(this.demoUserId);
    return {
      statusCode: 200,
      data: sub,
    };
  }

  @Post('pause')
  @ApiOperation({ summary: 'Pause or resume meal subscription' })
  @ApiResponse({ status: 200, description: 'Subscription status updated.' })
  async pauseSubscription(@Body() dto: PauseSubscriptionDto) {
    const sub = await this.subscriptionService.setPauseStatus(
      this.demoUserId,
      dto.paused,
    );
    return {
      statusCode: 200,
      message: dto.paused
        ? 'Subscription paused successfully.'
        : 'Subscription resumed successfully.',
      data: sub,
    };
  }
}
