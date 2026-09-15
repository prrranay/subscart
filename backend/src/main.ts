import { NestFactory } from '@nestjs/core';
import { ValidationPipe, Logger } from '@nestjs/common';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import { AppModule } from './app.module';
import { GlobalHttpExceptionFilter } from './common/filters/http-exception.filter';

async function bootstrap() {
  const logger = new Logger('Bootstrap');
  const app = await NestFactory.create(AppModule);

  // Enable CORS for Flutter Web, Android Emulator (10.0.2.2), iOS Simulator & Physical Devices
  app.enableCors({
    origin: '*',
    methods: 'GET,HEAD,PUT,PATCH,POST,DELETE,OPTIONS',
    allowedHeaders: 'Content-Type, Accept, Authorization',
  });

  // Global Exception Filter
  app.useGlobalFilters(new GlobalHttpExceptionFilter());

  // Global Validation Pipe for DTOs
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      transform: true,
      forbidNonWhitelisted: true,
      transformOptions: {
        enableImplicitConversion: true,
      },
    }),
  );

  // Swagger OpenAPI Documentation
  const config = new DocumentBuilder()
    .setTitle('Subscart Meal Subscription API')
    .setDescription(
      'Production-grade Subscription Meal Management System with Timezone-Safe Cutoff Engine (Luxon, IANA Timezone, Mongoose).',
    )
    .setVersion('1.0')
    .addTag('Schedule', 'Scheduled orders, Skip, Swap, Move, Reschedule, Undo')
    .addTag('Subscription', 'Subscription management and Pause/Resume toggle')
    .addTag('Meals', 'Meal catalog lookup for swaps')
    .build();

  const document = SwaggerModule.createDocument(app, config);
  SwaggerModule.setup('api/docs', app, document);

  const port = process.env.PORT || 3000;
  await app.listen(port, '0.0.0.0');
  logger.log(`🚀 Subscart Backend is running on: http://0.0.0.0:${port} (LAN: http://192.168.1.36:${port})`);
  logger.log(`📚 Swagger Documentation is available at: http://192.168.1.36:${port}/api/docs`);
}

bootstrap();
