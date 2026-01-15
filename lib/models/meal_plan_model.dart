import 'meal_model.dart';

class MealPlan {
  final String? id;
  final String userId;
  final DateTime startDate;
  final DateTime endDate;
  final List<Meal> meals;
  final NutritionInfo? dailyNutrition;
  final String? goal; // weight_loss, muscle_gain, maintenance, diabetes_management
  final DateTime? createdAt;

  MealPlan({
    this.id,
    required this.userId,
    required this.startDate,
    required this.endDate,
    required this.meals,
    this.dailyNutrition,
    this.goal,
    this.createdAt,
  });

  factory MealPlan.fromJson(Map<String, dynamic> json) {
    return MealPlan(
      id: json['id'] as String?,
      userId: json['user_id'] as String,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      meals: (json['meals'] as List<dynamic>?)
              ?.map((m) => Meal.fromJson(m as Map<String, dynamic>))
              .toList() ??
          [],
      dailyNutrition: json['daily_nutrition'] != null
          ? NutritionInfo.fromJson(
              json['daily_nutrition'] as Map<String, dynamic>)
          : null,
      goal: json['goal'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'meals': meals.map((m) => m.toJson()).toList(),
      if (dailyNutrition != null) 'daily_nutrition': dailyNutrition!.toJson(),
      if (goal != null) 'goal': goal,
    };
  }
}

