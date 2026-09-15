import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/meal_model.dart';
import '../../data/repositories/schedule_repository.dart';
import 'schedule_provider.dart';

final availableMealsProvider = FutureProvider<List<MealModel>>((ref) async {
  final repository = ref.watch(scheduleRepositoryProvider);
  return repository.getAvailableMeals();
});
