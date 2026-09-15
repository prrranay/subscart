import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { MealCatalog, MealCatalogSchema } from '../schemas/meal-catalog.schema';
import { MealCatalogService } from './meal-catalog.service';
import { MealCatalogController } from './meal-catalog.controller';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: MealCatalog.name, schema: MealCatalogSchema },
    ]),
  ],
  controllers: [MealCatalogController],
  providers: [MealCatalogService],
  exports: [MealCatalogService],
})
export class MealCatalogModule {}
