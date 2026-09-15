import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { MongooseModule } from '@nestjs/mongoose';
import { ScheduleModule } from './schedule/schedule.module';
import { SubscriptionModule } from './subscription/subscription.module';
import { MealCatalogModule } from './meal-catalog/meal-catalog.module';
import { CutoffModule } from './cutoff/cutoff.module';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath: ['.env', '.env.example'],
    }),
    MongooseModule.forRootAsync({
      imports: [ConfigModule],
      useFactory: async (configService: ConfigService) => ({
        uri: configService.get<string>(
          'MONGODB_URI',
          'mongodb://127.0.0.1:27017/suscart',
        ),
      }),
      inject: [ConfigService],
    }),
    CutoffModule,
    MealCatalogModule,
    SubscriptionModule,
    ScheduleModule,
  ],
})
export class AppModule {}
