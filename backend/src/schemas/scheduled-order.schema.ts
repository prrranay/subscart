import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';
import { MealSlot } from '../common/enums/meal-slot.enum';
import { OrderStatus } from '../common/enums/order-status.enum';

export type ScheduledOrderDocument = ScheduledOrder & Document;

@Schema({ timestamps: true, versionKey: '__v' })
export class ScheduledOrder {
  _id: Types.ObjectId;

  @Prop({ type: Types.ObjectId, ref: 'User', required: true, index: true })
  userId: Types.ObjectId;

  @Prop({ type: Types.ObjectId, ref: 'Subscription', required: true, index: true })
  subscriptionId: Types.ObjectId;

  // Local calendar date in user's timezone: YYYY-MM-DD
  @Prop({ required: true, trim: true, match: /^\d{4}-\d{2}-\d{2}$/, index: true })
  deliveryDate: string;

  @Prop({ type: Types.ObjectId, ref: 'MealCatalog', required: true })
  mealId: Types.ObjectId;

  @Prop({
    type: String,
    enum: Object.values(MealSlot),
    required: true,
  })
  slot: MealSlot;

  @Prop({
    type: String,
    enum: Object.values(OrderStatus),
    default: OrderStatus.SCHEDULED,
    index: true,
  })
  status: OrderStatus;

  // History tracking for fully functional backend Undo
  @Prop({ type: Types.ObjectId, ref: 'MealCatalog', default: null })
  previousMealId: Types.ObjectId | null;

  @Prop({ type: String, default: null })
  previousDate: string | null;

  @Prop({ type: String, enum: Object.values(MealSlot), default: null })
  previousSlot: MealSlot | null;

  @Prop({ type: String, enum: Object.values(OrderStatus), default: null })
  previousStatus: OrderStatus | null;

  @Prop({ type: String, default: null })
  cutoffAtUtc: string | null;

  @Prop({ default: 1 })
  version: number;

  createdAt: Date;
  updatedAt: Date;
}

export const ScheduledOrderSchema = SchemaFactory.createForClass(ScheduledOrder);

// Optimized compound indexes for fast query resolution and conflict validation
ScheduledOrderSchema.index({ userId: 1, deliveryDate: 1 });
ScheduledOrderSchema.index({ subscriptionId: 1, deliveryDate: 1 });
ScheduledOrderSchema.index({ userId: 1, deliveryDate: 1, slot: 1 });
