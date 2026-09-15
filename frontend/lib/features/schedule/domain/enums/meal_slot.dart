enum MealSlot {
  breakfast,
  lunch,
  dinner;

  static MealSlot fromString(String value) {
    switch (value.toLowerCase()) {
      case 'breakfast':
        return MealSlot.breakfast;
      case 'dinner':
        return MealSlot.dinner;
      case 'lunch':
      default:
        return MealSlot.lunch;
    }
  }

  String get displayName {
    switch (this) {
      case MealSlot.breakfast:
        return 'Breakfast Slot';
      case MealSlot.lunch:
        return 'Lunch Slot';
      case MealSlot.dinner:
        return 'Dinner Slot';
    }
  }

  String get timeWindow {
    switch (this) {
      case MealSlot.breakfast:
        return '7:30 AM - 8:45 AM';
      case MealSlot.lunch:
        return '12:30 PM - 1:30 PM';
      case MealSlot.dinner:
        return '6:30 PM - 7:45 PM';
    }
  }

  String toJson() => name;
}
