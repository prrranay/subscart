import { Controller, Get, Param } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse } from '@nestjs/swagger';
import { MealCatalogService } from './meal-catalog.service';

@ApiTags('Meals')
@Controller('meals')
export class MealCatalogController {
  constructor(private readonly mealCatalogService: MealCatalogService) {}

  @Get()
  @ApiOperation({ summary: 'Get all available meals for swap' })
  @ApiResponse({ status: 200, description: 'List of available meals returned successfully.' })
  async getAvailableMeals() {
    const meals = await this.mealCatalogService.findAllAvailable();
    return {
      statusCode: 200,
      data: meals,
    };
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get meal by ID' })
  async getMealById(@Param('id') id: string) {
    const meal = await this.mealCatalogService.findById(id);
    return {
      statusCode: 200,
      data: meal,
    };
  }
}
