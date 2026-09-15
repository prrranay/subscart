import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { MealCatalog, MealCatalogDocument } from '../schemas/meal-catalog.schema';
import { ApiException } from '../common/exceptions/api.exception';
import { ErrorCode } from '../common/enums/error-code.enum';

@Injectable()
export class MealCatalogService {
  constructor(
    @InjectModel(MealCatalog.name)
    private readonly mealModel: Model<MealCatalogDocument>,
  ) {}

  async findAllAvailable(): Promise<MealCatalogDocument[]> {
    return this.mealModel.find({ available: true }).sort({ isChefSpecial: -1, name: 1 }).exec();
  }

  async findById(id: string | Types.ObjectId): Promise<MealCatalogDocument> {
    if (!Types.ObjectId.isValid(id)) {
      throw new ApiException(ErrorCode.MEAL_NOT_FOUND, `Invalid meal ID format.`);
    }
    const meal = await this.mealModel.findById(id).exec();
    if (!meal) {
      throw new ApiException(ErrorCode.MEAL_NOT_FOUND, `Meal with ID ${id} was not found.`);
    }
    return meal;
  }

  async validateMealAvailable(id: string | Types.ObjectId): Promise<MealCatalogDocument> {
    const meal = await this.findById(id);
    if (!meal.available) {
      throw new ApiException(
        ErrorCode.MEAL_UNAVAILABLE,
        `Selected meal "${meal.name}" is currently unavailable for swapping.`,
      );
    }
    return meal;
  }
}
