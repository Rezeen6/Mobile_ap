import 'package:flutter/foundation.dart';
import '../models/meal_model.dart';
import '../models/user_model.dart';
import 'api_service.dart';

class TrackingService extends ChangeNotifier {
  final ApiService _apiService;
  
  List<Meal> _todayMeals = [];
  NutritionInfo? _todayNutrition;
  double _waterIntake = 0.0; // in ml
  Map<DateTime, NutritionInfo> _weeklyNutrition = {};
  bool _isLoading = false;

  TrackingService(this._apiService);

  List<Meal> get todayMeals => _todayMeals;
  NutritionInfo? get todayNutrition => _todayNutrition;
  double get waterIntake => _waterIntake;
  Map<DateTime, NutritionInfo> get weeklyNutrition => _weeklyNutrition;
  bool get isLoading => _isLoading;

  // Calculate daily nutrition from meals
  NutritionInfo _calculateDailyNutrition(List<Meal> meals) {
    double calories = 0;
    double protein = 0;
    double carbs = 0;
    double fat = 0;
    double fiber = 0;

    for (var meal in meals) {
      if (meal.nutrition != null) {
        calories += meal.nutrition!.calories;
        protein += meal.nutrition!.protein;
        carbs += meal.nutrition!.carbohydrates;
        fat += meal.nutrition!.fat;
        fiber += meal.nutrition!.fiber;
      }
    }

    return NutritionInfo(
      calories: calories,
      protein: protein,
      carbohydrates: carbs,
      fat: fat,
      fiber: fiber,
    );
  }

  // Get target nutrition based on user profile
  NutritionInfo? getTargetNutrition(User? user) {
    if (user == null) return null;
    
    final tdee = _calculateTDEE(user);
    if (tdee == null) return null;

    // Calculate macros based on goal
    double proteinRatio = 0.25; // 25% protein
    double carbRatio = 0.45; // 45% carbs
    double fatRatio = 0.30; // 30% fat

    if (user.healthGoal == 'weight_loss') {
      // Slightly higher protein for weight loss
      proteinRatio = 0.30;
      carbRatio = 0.40;
      fatRatio = 0.30;
    } else if (user.healthGoal == 'muscle_gain') {
      // Higher protein and carbs for muscle gain
      proteinRatio = 0.30;
      carbRatio = 0.50;
      fatRatio = 0.20;
    }

    return NutritionInfo(
      calories: tdee,
      protein: (tdee * proteinRatio) / 4, // 4 calories per gram
      carbohydrates: (tdee * carbRatio) / 4, // 4 calories per gram
      fat: (tdee * fatRatio) / 9, // 9 calories per gram
      fiber: 25.0, // Recommended daily fiber
    );
  }

  double? _calculateTDEE(User user) {
    if (user.age == null || user.height == null || user.weight == null || user.gender == null) {
      return null;
    }

    // BMR calculation (Mifflin-St Jeor)
    double bmr;
    if (user.gender!.toLowerCase() == 'male') {
      bmr = 10 * user.weight! + 6.25 * user.height! - 5 * user.age! + 5;
    } else {
      bmr = 10 * user.weight! + 6.25 * user.height! - 5 * user.age! - 161;
    }

    // Activity multipliers
    final multipliers = {
      'sedentary': 1.2,
      'lightly_active': 1.375,
      'moderately_active': 1.55,
      'very_active': 1.725,
      'extremely_active': 1.9,
    };

    final multiplier = multipliers[user.activityLevel] ?? 1.2;
    return bmr * multiplier;
  }

  Future<void> loadTodayMeals() async {
    _isLoading = true;
    notifyListeners();

    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final mealPlans = await _apiService.getMealPlans(
        startDate: startOfDay,
        endDate: endOfDay,
      );

      _todayMeals = [];
      for (var plan in mealPlans) {
        _todayMeals.addAll(plan.meals.where((m) {
          try {
            final mealDate = m.date is DateTime 
                ? m.date as DateTime 
                : DateTime.parse(m.date.toString());
            return mealDate.isAfter(startOfDay.subtract(const Duration(seconds: 1))) && 
                   mealDate.isBefore(endOfDay);
          } catch (e) {
            debugPrint('Error parsing meal date: $e');
            return false;
          }
        }));
      }
      
      // Sort meals by date/time
      _todayMeals.sort((a, b) {
        try {
          final dateA = a.date is DateTime ? a.date as DateTime : DateTime.parse(a.date.toString());
          final dateB = b.date is DateTime ? b.date as DateTime : DateTime.parse(b.date.toString());
          return dateA.compareTo(dateB);
        } catch (e) {
          return 0;
        }
      });

      _todayNutrition = _calculateDailyNutrition(_todayMeals);
      
      if (kDebugMode) {
        debugPrint('✅ Today\'s meals loaded from backend: ${_todayMeals.length} meals');
        if (_todayNutrition != null) {
          debugPrint('   Today\'s nutrition: ${_todayNutrition!.calories.toStringAsFixed(0)} kcal, '
              'P: ${_todayNutrition!.protein.toStringAsFixed(1)}g, '
              'C: ${_todayNutrition!.carbohydrates.toStringAsFixed(1)}g, '
              'F: ${_todayNutrition!.fat.toStringAsFixed(1)}g');
        }
      }
    } catch (e) {
      debugPrint('❌ Error loading today meals: $e');
      _todayMeals = [];
      _todayNutrition = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadWeeklyNutrition() async {
    _isLoading = true;
    notifyListeners();

    try {
      final now = DateTime.now();
      // Get past 7 days (including today) - last 7 days from now
      final startOfWeek = now.subtract(const Duration(days: 6));
      
      _weeklyNutrition = {};
      
      for (int i = 0; i < 7; i++) {
        final date = startOfWeek.add(Duration(days: i));
        final startOfDay = DateTime(date.year, date.month, date.day);
        final endOfDay = startOfDay.add(const Duration(days: 1));

        try {
          final mealPlans = await _apiService.getMealPlans(
            startDate: startOfDay,
            endDate: endOfDay,
          );

          List<Meal> dayMeals = [];
          for (var plan in mealPlans) {
            dayMeals.addAll(plan.meals.where((m) {
              try {
                final mealDate = m.date is DateTime 
                    ? m.date as DateTime 
                    : DateTime.parse(m.date.toString());
                return mealDate.isAfter(startOfDay.subtract(const Duration(seconds: 1))) && 
                       mealDate.isBefore(endOfDay);
              } catch (e) {
                debugPrint('Error parsing meal date: $e');
                return false;
              }
            }));
          }

          _weeklyNutrition[date] = _calculateDailyNutrition(dayMeals);
          
          if (kDebugMode && dayMeals.isNotEmpty) {
            final nutrition = _weeklyNutrition[date]!;
            debugPrint('📊 Loaded nutrition for ${date.toString().split(' ')[0]}: ${nutrition.calories.toStringAsFixed(0)} kcal, ${dayMeals.length} meals');
          }
        } catch (e) {
          debugPrint('Error loading nutrition for date $date: $e');
          // Set empty nutrition for this day if there's an error
          _weeklyNutrition[date] = NutritionInfo(
            calories: 0,
            protein: 0,
            carbohydrates: 0,
            fat: 0,
            fiber: 0,
          );
        }
      }
      
      if (kDebugMode) {
        debugPrint('✅ Weekly nutrition loaded: ${_weeklyNutrition.length} days with data from backend');
        final totalMeals = _weeklyNutrition.values.fold<int>(
          0,
          (sum, nutrition) => sum + (nutrition.calories > 0 ? 1 : 0),
        );
        debugPrint('   Days with meals: $totalMeals / ${_weeklyNutrition.length}');
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading weekly nutrition: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void addWater(double amount) {
    _waterIntake += amount;
    notifyListeners();
  }

  void resetWater() {
    _waterIntake = 0.0;
    notifyListeners();
  }

  double getWaterTarget() {
    return 2000.0; // 2 liters default
  }

  double getWaterProgress() {
    return _waterIntake / getWaterTarget();
  }

  List<Meal> getMealsByType(String mealType) {
    return _todayMeals.where((m) => m.mealType == mealType).toList();
  }

  double getProgressPercentage(NutritionInfo? target, NutritionInfo? current, String nutrient) {
    if (target == null || current == null) return 0.0;
    
    double targetValue = 0;
    double currentValue = 0;
    
    switch (nutrient) {
      case 'calories':
        targetValue = target.calories;
        currentValue = current.calories;
        break;
      case 'protein':
        targetValue = target.protein;
        currentValue = current.protein;
        break;
      case 'carbs':
        targetValue = target.carbohydrates;
        currentValue = current.carbohydrates;
        break;
      case 'fat':
        targetValue = target.fat;
        currentValue = current.fat;
        break;
    }
    
    if (targetValue == 0) return 0.0;
    return (currentValue / targetValue).clamp(0.0, 1.5); // Allow up to 150% for visualization
  }

  // Generate dummy test data for macronutrient trends chart
  void loadDummyData() {
    final now = DateTime.now();
    
    // Generate today's nutrition data (matching the image: 0 calories initially, but can be set to test)
    // For testing, you can set this to any value to see progress
    _todayNutrition = NutritionInfo(
      calories: 0.0, // Start at 0 like in the image, or change to test progress
      protein: 0.0,
      carbohydrates: 0.0,
      fat: 0.0,
      fiber: 0.0,
    );
    
    // You can also set it to show progress:
    // _todayNutrition = NutritionInfo(
    //   calories: 1200.0, // Example: 60% of 2000 kcal
    //   protein: 80.0,
    //   carbohydrates: 150.0,
    //   fat: 40.0,
    //   fiber: 20.0,
    // );

    // Generate data for last 30 days (covers week and month views)
    _weeklyNutrition = {};
    
    // Realistic macronutrient values with trends (matching the chart image)
    // Week 1-5 data pattern
    final carbsPattern = [
      // Week 1
      50.0, 25.0, 115.0, 145.0, 45.0,
      // Week 2  
      90.0, 70.0, 110.0, 130.0, 60.0,
      // Week 3
      85.0, 95.0, 120.0, 140.0, 55.0,
      // Week 4
      75.0, 100.0, 125.0, 135.0, 65.0,
      // Week 5
      80.0, 105.0, 115.0, 150.0, 50.0,
    ];
    
    final proteinPattern = [
      // Week 1
      15.0, 5.0, 95.0, 25.0, 15.0,
      // Week 2
      60.0, 45.0, 70.0, 85.0, 20.0,
      // Week 3
      55.0, 65.0, 80.0, 90.0, 18.0,
      // Week 4
      50.0, 75.0, 88.0, 92.0, 22.0,
      // Week 5
      58.0, 68.0, 85.0, 95.0, 16.0,
    ];
    
    final fatPattern = [
      // Week 1
      30.0, 5.0, 40.0, 30.0, 40.0,
      // Week 2
      35.0, 28.0, 38.0, 42.0, 25.0,
      // Week 3
      32.0, 30.0, 40.0, 45.0, 22.0,
      // Week 4
      28.0, 35.0, 43.0, 38.0, 26.0,
      // Week 5
      34.0, 36.0, 40.0, 42.0, 24.0,
    ];

    // Generate 30 days of data
    for (int i = 0; i < 30; i++) {
      final date = now.subtract(Duration(days: 29 - i));
      final dayDate = DateTime(date.year, date.month, date.day);
      
      final carbs = carbsPattern[i % carbsPattern.length];
      final protein = proteinPattern[i % proteinPattern.length];
      final fat = fatPattern[i % fatPattern.length];
      
      _weeklyNutrition[dayDate] = NutritionInfo(
        calories: (carbs * 4) + (protein * 4) + (fat * 9),
        protein: protein,
        carbohydrates: carbs,
        fat: fat,
        fiber: 18.0 + (i * 0.25),
      );
    }

    // Set some water intake
    _waterIntake = 1500.0;

    notifyListeners();
    debugPrint('✅ Dummy test data loaded successfully!');
    debugPrint('   - Today nutrition: ${_todayNutrition?.calories} kcal');
    debugPrint('   - Weekly data: ${_weeklyNutrition.length} days');
  }

  // Clear dummy data and reset to empty
  void clearDummyData() {
    _todayNutrition = null;
    _weeklyNutrition = {};
    _waterIntake = 0.0;
    _todayMeals = [];
    notifyListeners();
    debugPrint('🗑️ Dummy test data cleared!');
  }

  // Set today's nutrition for testing (useful for testing progress display)
  void setTodayNutrition({
    double? calories,
    double? protein,
    double? carbs,
    double? fat,
    double? fiber,
  }) {
    _todayNutrition = NutritionInfo(
      calories: calories ?? _todayNutrition?.calories ?? 0.0,
      protein: protein ?? _todayNutrition?.protein ?? 0.0,
      carbohydrates: carbs ?? _todayNutrition?.carbohydrates ?? 0.0,
      fat: fat ?? _todayNutrition?.fat ?? 0.0,
      fiber: fiber ?? _todayNutrition?.fiber ?? 0.0,
    );
    notifyListeners();
    debugPrint('📊 Today\'s nutrition updated: ${_todayNutrition?.calories} kcal');
  }
}

