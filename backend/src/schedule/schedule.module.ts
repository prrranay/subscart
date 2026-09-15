import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { ConfigModule } from '@nestjs/config';
import { ScheduledOrder, ScheduledOrderSchema } from '../schemas/scheduled-order.schema';
import { User, UserSchema } from '../schemas/user.schema';
import { Subscription, SubscriptionSchema } from '../schemas/subscription.schema';
import { ScheduleService } from './schedule.service';
import { ScheduleController } from './schedule.controller';
import { CutoffModule } from '../cutoff/cutoff.module';
import { SubscriptionModule } from '../subscription/subscription.module';
import { MealCatalogModule } from '../meal-catalog/meal-catalog.module';

@Module({
  imports: [
    ConfigModule,
    CutoffModule,
    SubscriptionModule,
    MealCatalogModule,
    MongooseModule.forFeature([
      { name: ScheduledOrder.name, schema: ScheduledOrderSchema },
      { name: User.name, schema: UserSchema },
      { name: Subscription.name, schema: SubscriptionSchema },
    ]),
  ],
  controllers: [ScheduleController],
  providers: [ScheduleService],
  exports: [ScheduleService],
})
export class ScheduleModule {}
