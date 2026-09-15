import {
  Controller,
  Get,
  Patch,
  Param,
  Body,
  Query,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { ApiTags, ApiOperation, ApiResponse, ApiParam } from '@nestjs/swagger';
import { ScheduleService } from './schedule.service';
import { GetScheduleQueryDto } from './dto/get-schedule-query.dto';
import { SwapMealDto } from './dto/swap-meal.dto';
import { MoveOrderDto } from './dto/move-order.dto';
import { RescheduleOrderDto } from './dto/reschedule-order.dto';

@ApiTags('Schedule')
@Controller('schedule')
export class ScheduleController {
  private readonly demoUserId: string;

  constructor(
    private readonly scheduleService: ScheduleService,
    private readonly configService: ConfigService,
  ) {
    this.demoUserId = this.configService.get<string>(
      'DEMO_USER_ID',
      '6640c1a2f1839a5840d8a101',
    );
  }

  @Get()
  @ApiOperation({ summary: 'Get meal schedule for user within date range' })
  @ApiResponse({ status: 200, description: 'Schedule data retrieved successfully.' })
  async getSchedule(@Query() query: GetScheduleQueryDto) {
    const schedule = await this.scheduleService.getSchedule(
      this.demoUserId,
      query.startDate,
      query.endDate,
    );
    return {
      statusCode: 200,
      data: schedule,
    };
  }

  @Patch(':id/skip')
  @ApiOperation({ summary: 'Skip a scheduled meal order' })
  @ApiParam({ name: 'id', description: 'ScheduledOrder ID' })
  async skipOrder(@Param('id') id: string) {
    const updated = await this.scheduleService.skipOrder(this.demoUserId, id);
    return {
      statusCode: 200,
      message: 'Meal order skipped successfully.',
      data: updated,
    };
  }

  @Patch(':id/swap')
  @ApiOperation({ summary: 'Swap a scheduled meal with an alternative meal' })
  @ApiParam({ name: 'id', description: 'ScheduledOrder ID' })
  async swapMeal(@Param('id') id: string, @Body() dto: SwapMealDto) {
    const updated = await this.scheduleService.swapMeal(
      this.demoUserId,
      id,
      dto.mealId,
    );
    return {
      statusCode: 200,
      message: 'Meal swapped successfully.',
      data: updated,
    };
  }

  @Patch(':id/move')
  @ApiOperation({ summary: 'Move a meal to another date and time slot' })
  @ApiParam({ name: 'id', description: 'ScheduledOrder ID' })
  async moveOrder(@Param('id') id: string, @Body() dto: MoveOrderDto) {
    const updated = await this.scheduleService.moveOrder(
      this.demoUserId,
      id,
      dto.date,
      dto.slot,
    );
    return {
      statusCode: 200,
      message: `Meal moved successfully to ${dto.date} (${dto.slot}).`,
      data: updated,
    };
  }

  @Patch(':id/reschedule')
  @ApiOperation({ summary: 'Reschedule meal to another date (preserving current slot)' })
  @ApiParam({ name: 'id', description: 'ScheduledOrder ID' })
  async rescheduleOrder(@Param('id') id: string, @Body() dto: RescheduleOrderDto) {
    const updated = await this.scheduleService.rescheduleOrder(
      this.demoUserId,
      id,
      dto.date,
    );
    return {
      statusCode: 200,
      message: `Meal rescheduled successfully to ${dto.date}.`,
      data: updated,
    };
  }

  @Patch(':id/undo')
  @ApiOperation({ summary: 'Undo the last action on a scheduled meal order' })
  @ApiParam({ name: 'id', description: 'ScheduledOrder ID' })
  async undoOrder(@Param('id') id: string) {
    const updated = await this.scheduleService.undoOrder(this.demoUserId, id);
    return {
      statusCode: 200,
      message: 'Action reverted successfully.',
      data: updated,
    };
  }
}
