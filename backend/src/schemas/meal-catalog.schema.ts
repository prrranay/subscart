import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

export type MealCatalogDocument = MealCatalog & Document;

@Schema({ timestamps: true })
export class MealCatalog {
  _id: Types.ObjectId;

  @Prop({ required: true, trim: true })
  name: string;

  @Prop({ required: true, trim: true })
  imageUrl: string;

  @Prop({ required: true, min: 0 })
  calories: number;

  @Prop({ required: true, min: 0 })
  protein: number;

  @Prop({ required: true, min: 0 })
  carbs: number;

  @Prop({ required: true, min: 0 })
  fat: number;

  @Prop({ required: true, default: 'Bowls & Salads' })
  category: string;

  @Prop({ required: true, default: true })
  available: boolean;

  @Prop({ default: '' })
  description: string;

  @Prop({ type: [String], default: [] })
  dietaryTags: string[]; // e.g. ['Gluten-Free', 'High Protein', 'Keto', 'Vegan']

  @Prop({ default: false })
  isChefSpecial: boolean;

  createdAt: Date;
  updatedAt: Date;
}

export const MealCatalogSchema = SchemaFactory.createForClass(MealCatalog);
