import mongoose, { Types } from 'mongoose';
import { DateTime } from 'luxon';
import * as dotenv from 'dotenv';
import { UserSchema } from './schemas/user.schema';
import { SubscriptionSchema } from './schemas/subscription.schema';
import { MealCatalogSchema } from './schemas/meal-catalog.schema';
import { ScheduledOrderSchema } from './schemas/scheduled-order.schema';
import { SubscriptionStatus } from './common/enums/subscription-status.enum';
import { MealSlot } from './common/enums/meal-slot.enum';
import { OrderStatus } from './common/enums/order-status.enum';

dotenv.config();

const MONGODB_URI =
  process.env.MONGODB_URI || 'mongodb://127.0.0.1:27017/suscart';
const DEMO_USER_ID =
  process.env.DEMO_USER_ID || '6640c1a2f1839a5840d8a101';
const USER_TIMEZONE =
  process.env.DEFAULT_TIMEZONE || 'Asia/Kolkata';

// Model definitions for direct seeding script
const UserModel = mongoose.model('User', UserSchema);
const SubscriptionModel = mongoose.model('Subscription', SubscriptionSchema);
const MealCatalogModel = mongoose.model('MealCatalog', MealCatalogSchema);
const ScheduledOrderModel = mongoose.model('ScheduledOrder', ScheduledOrderSchema);

export async function seedDatabase() {
  console.log('Connecting to MongoDB at:', MONGODB_URI);
  await mongoose.connect(MONGODB_URI);
  console.log('Connected to MongoDB successfully.');

  // Clean existing seed collections
  console.log('Clearing existing collections...');
  await UserModel.deleteMany({});
  await SubscriptionModel.deleteMany({});
  await MealCatalogModel.deleteMany({});
  await ScheduledOrderModel.deleteMany({});

  // 1. Seed Demo User
  console.log('Seeding demo user...');
  const user = await UserModel.create({
    _id: new Types.ObjectId(DEMO_USER_ID),
    name: 'Pranay Kumar',
    timezone: USER_TIMEZONE,
  });
  console.log(`Created User: ${user.name} (${user._id}) with timezone ${user.timezone}`);

  // 2. Seed Subscription
  console.log('Seeding subscription...');
  const subscription = await SubscriptionModel.create({
    userId: user._id,
    name: 'Healthy Plan • 6 Days',
    status: SubscriptionStatus.ACTIVE,
    cutoffTime: {
      hour: 20,
      minute: 30,
    },
  });
  console.log(`Created Subscription: ${subscription.name} (Cutoff: ${subscription.cutoffTime.hour}:${subscription.cutoffTime.minute})`);

  // 3. Seed Meal Catalog (8+ gourmet healthy meals)
  console.log('Seeding meal catalog...');
  const mealsData = [
    {
      _id: new Types.ObjectId('6640c1a2f1839a5840d8a201'),
      name: 'Moroccan Dream Salad',
      imageUrl:
        'https://lh3.googleusercontent.com/aida-public/AB6AXuAh3T1mRZl2_z69jnaiJpgpra9JVA9bc34w9e142QP81yo-PMGEui5Cgf5Kp_0t-n7eOKPmVb-9DJKQp1l52lTHDOYIKTJsRzEEiPnAw90VC04S0bKagn-55JmFzk_k8ZUnPqiU-dHXXry-3fHbz5nxrRdl3Qh1QnwqKOHRpPUk8T8oPocevvpM2h7son1LvktN0Bxw33bDyT-2afpAU3I808of180GlnxthpFt92joSygpApY_UsU2',
      calories: 384,
      protein: 13,
      carbs: 50,
      fat: 14,
      category: 'Bowls & Salads',
      available: true,
      isChefSpecial: true,
      description: 'Spiced chickpeas, roasted cumin carrots, heirloom quinoa & citrus tahini.',
      dietaryTags: ['Gluten-Free', 'High Fiber', 'Vegan'],
    },
    {
      _id: new Types.ObjectId('6640c1a2f1839a5840d8a202'),
      name: 'Teriyaki Salmon Poke Bowl',
      imageUrl:
        'https://lh3.googleusercontent.com/aida-public/AB6AXuB_7kjtiLlilwthdOSzkGgKf3eQzlr3xS7vYzUh8y4TVI8-7deSd3E8tOqTKhncMUpmfZ6vv_Fjzt8cGgFZOQb5N7wdZMS5L-jHAdLiZAE1KXheo9hyq_Hv9Crdf5wrB4hDlISgXk_dOaf_rD9dTpJmCEd1TM2lIBQ4joFPZbOEXfvdPDAejtdDUMf3b9OiTH8Il9oFdXevAotDu4qZ-F9lV3A6OEcak1O7ovTqdWAYLrh4LKfqLNG4',
      calories: 420,
      protein: 28,
      carbs: 34,
      fat: 16,
      category: 'Bowls & Salads',
      available: true,
      isChefSpecial: true,
      description: 'Wild salmon, fresh edamame, cucumber ribbons, pickled ginger, brown rice & sesame drizzle.',
      dietaryTags: ['High Protein', 'Omega 3', 'Chef Special'],
    },
    {
      _id: new Types.ObjectId('6640c1a2f1839a5840d8a203'),
      name: 'Mediterranean Quinoa Bowl',
      imageUrl:
        'https://lh3.googleusercontent.com/aida-public/AB6AXuDaIq-Lkfwt1PIM8untR6ncyJ8KUC1u1CjCw0GeyA3oFVbx1VYXC7wq45Qd8yOhJvfo_N51APh86zzRY_jS6cxBbWX8XIUgecZBqbahxf2tuwZ0CSqi8d9VknReJA4FvjTSCI_Ae_2_TRBvsHvTg8pw9O_UUI5-AcxnzC-rCdPCMNuhI9JH8NpYLWauEHoZweeRF5lhpkODWiUXOsuLMz2YlYN2YEjX_-L83eHHk15mvAt-bJru__S5',
      calories: 365,
      protein: 15,
      carbs: 42,
      fat: 13,
      category: 'Bowls & Salads',
      available: true,
      isChefSpecial: false,
      description: 'Grilled kalamata olives, marinated feta, diced cucumber, bell peppers & fresh mint.',
      dietaryTags: ['Vegetarian', 'Mediterranean', 'Gluten-Free'],
    },
    {
      _id: new Types.ObjectId('6640c1a2f1839a5840d8a204'),
      name: 'Avocado Green Goddess Bowl',
      imageUrl:
        'https://images.unsplash.com/photo-1540420773420-3366772f4999?auto=format&fit=crop&w=800&q=80',
      calories: 395,
      protein: 16,
      carbs: 38,
      fat: 19,
      category: 'Bowls & Salads',
      available: true,
      isChefSpecial: false,
      description: 'Creamy avocado, baby spinach, roasted broccoli, pumpkin seeds & herb dressing.',
      dietaryTags: ['Keto-Friendly', 'Vegan', 'Superfood'],
    },
    {
      _id: new Types.ObjectId('6640c1a2f1839a5840d8a205'),
      name: 'Grilled Herb Chicken & Sweet Potato',
      imageUrl:
        'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?auto=format&fit=crop&w=800&q=80',
      calories: 450,
      protein: 38,
      carbs: 40,
      fat: 12,
      category: 'Proteins & Warm Plates',
      available: true,
      isChefSpecial: true,
      description: 'Rosemary grilled chicken breast with roasted sweet potatoes and garlic asparagus.',
      dietaryTags: ['High Protein', 'Gluten-Free', 'Lean Muscle'],
    },
    {
      _id: new Types.ObjectId('6640c1a2f1839a5840d8a206'),
      name: 'Matcha Overnight Chia Oats',
      imageUrl:
        'https://images.unsplash.com/photo-1517673400267-0251440c45dc?auto=format&fit=crop&w=800&q=80',
      calories: 290,
      protein: 12,
      carbs: 44,
      fat: 8,
      category: 'Breakfast Bowls',
      available: true,
      isChefSpecial: false,
      description: 'Organic ceremonial matcha, rolled oats, almond milk, chia seeds & wild blueberries.',
      dietaryTags: ['Breakfast', 'Antioxidants', 'Vegan'],
    },
    {
      _id: new Types.ObjectId('6640c1a2f1839a5840d8a207'),
      name: 'Tuscan Kale & White Bean Stew',
      imageUrl:
        'https://images.unsplash.com/photo-1547592180-85f173990554?auto=format&fit=crop&w=800&q=80',
      calories: 340,
      protein: 18,
      carbs: 48,
      fat: 7,
      category: 'Warm Plates',
      available: true,
      isChefSpecial: false,
      description: 'Simmered cannellini beans, tender Tuscan kale, sun-ripened tomatoes & garlic focaccia crunch.',
      dietaryTags: ['Hearty', 'Fiber Rich', 'Vegetarian'],
    },
    {
      _id: new Types.ObjectId('6640c1a2f1839a5840d8a208'),
      name: 'Keto Lemon Basil Pesto Zoodles',
      imageUrl:
        'https://images.unsplash.com/photo-1551248429-40975aa4de74?auto=format&fit=crop&w=800&q=80',
      calories: 310,
      protein: 14,
      carbs: 12,
      fat: 24,
      category: 'Low Carb',
      available: true,
      isChefSpecial: false,
      description: 'Zucchini noodles tossed in house-made pine nut basil pesto with shaved parmesan.',
      dietaryTags: ['Keto', 'Low Carb', 'Gluten-Free'],
    },
    {
      _id: new Types.ObjectId('6640c1a2f1839a5840d8a209'),
      name: 'Sesame Crusted Tofu Buddha Bowl',
      imageUrl:
        'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?auto=format&fit=crop&w=800&q=80',
      calories: 370,
      protein: 22,
      carbs: 36,
      fat: 15,
      category: 'Bowls & Salads',
      available: true,
      isChefSpecial: false,
      description: 'Crispy sesame organic tofu, purple cabbage, avocado, edamame and miso ginger dressing.',
      dietaryTags: ['Plant Protein', 'Vegan', 'Dairy-Free'],
    },
  ];

  const meals = await MealCatalogModel.insertMany(mealsData);
  console.log(`Seeded ${meals.length} meals.`);

  // 4. Seed 14 Days of Scheduled Orders relative to local today
  console.log('Seeding scheduled orders...');
  const nowInUserTz = DateTime.now().setZone(USER_TIMEZONE);

  const ordersToInsert: any[] = [];

  // Generate for days: -1 (yesterday), 0 (today), 1..10 (future days)
  for (let offset = -1; offset <= 10; offset++) {
    const day = nowInUserTz.plus({ days: offset });
    const dateStr = day.toISODate()!; // YYYY-MM-DD

    // Breakfast on even days
    if (offset % 2 === 0) {
      ordersToInsert.push({
        userId: user._id,
        subscriptionId: subscription._id,
        deliveryDate: dateStr,
        mealId: meals[5]._id, // Chia Oats
        slot: MealSlot.BREAKFAST,
        status: OrderStatus.SCHEDULED,
        version: 1,
      });
    }

    // Lunch on every day
    const lunchMeal = meals[Math.abs(offset) % 4]; // Rotate between Moroccan, Teriyaki, Quinoa, Avocado
    ordersToInsert.push({
      userId: user._id,
      subscriptionId: subscription._id,
      deliveryDate: dateStr,
      mealId: lunchMeal._id,
      slot: MealSlot.LUNCH,
      status: offset === 2 ? OrderStatus.SKIPPED : OrderStatus.SCHEDULED,
      version: 1,
    });

    // Dinner on selected days
    if (offset % 3 === 0) {
      ordersToInsert.push({
        userId: user._id,
        subscriptionId: subscription._id,
        deliveryDate: dateStr,
        mealId: meals[4]._id, // Herb chicken
        slot: MealSlot.DINNER,
        status: OrderStatus.SCHEDULED,
        version: 1,
      });
    }
  }

  const createdOrders = await ScheduledOrderModel.insertMany(ordersToInsert);
  console.log(`Seeded ${createdOrders.length} scheduled orders successfully across multiple dates.`);

  console.log('----------------------------------------------------');
  console.log('✨ Seed complete! You can test with:');
  console.log(`DEMO_USER_ID: ${DEMO_USER_ID}`);
  console.log(`User Timezone: ${USER_TIMEZONE}`);
  console.log('----------------------------------------------------');

  await mongoose.disconnect();
}

// Run directly if called from CLI
if (require.main === module) {
  seedDatabase()
    .then(() => process.exit(0))
    .catch((err) => {
      console.error('Seed script failed:', err);
      process.exit(1);
    });
}
