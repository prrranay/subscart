class MealModel {
  final String id;
  final String name;
  final String imageUrl;
  final int calories;
  final int protein;
  final int carbs;
  final int fat;
  final String category;
  final bool available;
  final String description;
  final List<String> dietaryTags;
  final bool isChefSpecial;

  const MealModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.category,
    required this.available,
    this.description = '',
    this.dietaryTags = const [],
    this.isChefSpecial = false,
  });

  factory MealModel.fromJson(Map<String, dynamic> json) {
    return MealModel(
      id: json['id'] ?? json['_id'] ?? '',
      name: json['name'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      calories: json['calories'] ?? 0,
      protein: json['protein'] ?? 0,
      carbs: json['carbs'] ?? 0,
      fat: json['fat'] ?? 0,
      category: json['category'] ?? 'Bowls & Salads',
      available: json['available'] ?? true,
      description: json['description'] ?? '',
      dietaryTags: (json['dietaryTags'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      isChefSpecial: json['isChefSpecial'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'imageUrl': imageUrl,
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        'category': category,
        'available': available,
        'description': description,
        'dietaryTags': dietaryTags,
        'isChefSpecial': isChefSpecial,
      };
}
