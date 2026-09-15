import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';
import { SubscriptionStatus } from '../common/enums/subscription-status.enum';

export type SubscriptionDocument = Subscription & Document;

@Schema({ _id: false })
export class CutoffTime {
  @Prop({ required: true, default: 20, min: 0, max: 23 })
  hour: number;

  @Prop({ required: true, default: 30, min: 0, max: 59 })
  minute: number;
}

export const CutoffTimeSchema = SchemaFactory.createForClass(CutoffTime);

@Schema({ timestamps: true })
export class Subscription {
  _id: Types.ObjectId;

  @Prop({ type: Types.ObjectId, ref: 'User', required: true, index: true })
  userId: Types.ObjectId;

  @Prop({ required: true, trim: true, default: 'Healthy Plan • 6 Days' })
  name: string;

  @Prop({
    type: String,
    enum: Object.values(SubscriptionStatus),
    default: SubscriptionStatus.ACTIVE,
  })
  status: SubscriptionStatus;

  @Prop({ type: CutoffTimeSchema, default: () => ({ hour: 20, minute: 30 }) })
  cutoffTime: CutoffTime;

  createdAt: Date;
  updatedAt: Date;
}

export const SubscriptionSchema = SchemaFactory.createForClass(Subscription);
