class Meal {
  final String? id;
  final String name;
  final String? description;
  final String mealType; // breakfast, lunch, dinner, snack
  final DateTime date;
  final List<FoodItem> foods;
  final NutritionInfo? nutrition;

  Meal({
    this.id,
    required this.name,
    this.description,
    required this.mealType,
    required this.date,
    required this.foods,
    this.nutrition,
  });

  factory Meal.fromJson(Map<String, dynamic> json) {
    return Meal(
      id: json['id'] as String?,
      name: json['name'] as String,
      description: json['description'] as String?,
      mealType: json['meal_type'] as String,
      date: DateTime.parse(json['date'] as String),
      foods: (json['foods'] as List<dynamic>?)
              ?.map((f) => FoodItem.fromJson(f as Map<String, dynamic>))
              .toList() ??
          [],
      nutrition: json['nutrition'] != null
          ? NutritionInfo.fromJson(json['nutrition'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      if (description != null) 'description': description,
      'meal_type': mealType,
      'date': date.toIso8601String(),
      'foods': foods.map((f) => f.toJson()).toList(),
      if (nutrition != null) 'nutrition': nutrition!.toJson(),
    };
  }
}

class FoodItem {
  final String? id;
  final String name;
  final double quantity; // in grams
  final String? unit;
  final NutritionInfo? nutrition;

  FoodItem({
    this.id,
    required this.name,
    required this.quantity,
    this.unit,
    this.nutrition,
  });

  factory FoodItem.fromJson(Map<String, dynamic> json) {
    return FoodItem(
      id: json['id'] as String?,
      name: json['name'] as String,
      quantity: (json['quantity'] as num).toDouble(),
      unit: json['unit'] as String?,
      nutrition: json['nutrition'] != null
          ? NutritionInfo.fromJson(json['nutrition'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'quantity': quantity,
      if (unit != null) 'unit': unit,
      if (nutrition != null) 'nutrition': nutrition!.toJson(),
    };
  }
}

class NutritionInfo {
  final double calories;
  final double protein; // in grams
  final double carbohydrates; // in grams
  final double fat; // in grams
  final double fiber; // in grams
  final double? sugar;
  final double? sodium; // in mg

  NutritionInfo({
    required this.calories,
    required this.protein,
    required this.carbohydrates,
    required this.fat,
    required this.fiber,
    this.sugar,
    this.sodium,
  });

  factory NutritionInfo.fromJson(Map<String, dynamic> json) {
    return NutritionInfo(
      calories: (json['calories'] as num).toDouble(),
      protein: (json['protein'] as num).toDouble(),
      carbohydrates: (json['carbohydrates'] as num).toDouble(),
      fat: (json['fat'] as num).toDouble(),
      fiber: (json['fiber'] as num).toDouble(),
      sugar: json['sugar'] != null ? (json['sugar'] as num).toDouble() : null,
      sodium: json['sodium'] != null ? (json['sodium'] as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'calories': calories,
      'protein': protein,
      'carbohydrates': carbohydrates,
      'fat': fat,
      'fiber': fiber,
      if (sugar != null) 'sugar': sugar,
      if (sodium != null) 'sodium': sodium,
    };
  }
}

