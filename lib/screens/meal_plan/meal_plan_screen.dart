import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../models/meal_plan_model.dart';
import 'generate_meal_plan_screen.dart';
import 'image_recognition_screen.dart';
import 'package:intl/intl.dart';

class MealPlanScreen extends StatefulWidget {
  const MealPlanScreen({super.key});

  @override
  State<MealPlanScreen> createState() => _MealPlanScreenState();
}

class _MealPlanScreenState extends State<MealPlanScreen> {
  List<MealPlan> _mealPlans = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMealPlans();
  }

  Future<void> _loadMealPlans() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    if (!authService.isAuthenticated) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final mealPlans = await apiService.getMealPlans();
      setState(() {
        _mealPlans = mealPlans;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading meal plans: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _generateMealPlan() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const GenerateMealPlanScreen(),
      ),
    );

    if (result != null) {
      // Refresh meal plans
      _loadMealPlans();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meal Plans'),
        actions: [
          IconButton(
            icon: const Icon(Icons.camera_alt),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ImageRecognitionScreen(),
                ),
              );
            },
            tooltip: 'Scan Food',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMealPlans,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _generateMealPlan,
            tooltip: 'Generate Meal Plan',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _mealPlans.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.restaurant_menu,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No meal plans yet',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Generate a personalized meal plan to get started',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _generateMealPlan,
                        icon: const Icon(Icons.auto_awesome),
                        label: const Text('Generate Meal Plan'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadMealPlans,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _mealPlans.length,
                    itemBuilder: (context, index) {
                      final plan = _mealPlans[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: ExpansionTile(
                          leading: const Icon(Icons.restaurant_menu),
                          title: Text(
                            '${DateFormat('MMM d').format(plan.startDate)} - ${DateFormat('MMM d, yyyy').format(plan.endDate)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '${plan.meals.length} meals • ${plan.goal ?? 'No goal'}',
                          ),
                          children: [
                            if (plan.dailyNutrition != null)
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Daily Nutrition Target:',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Calories: ${plan.dailyNutrition!.calories.toStringAsFixed(0)} kcal',
                                    ),
                                    Text(
                                      'Protein: ${plan.dailyNutrition!.protein.toStringAsFixed(1)}g',
                                    ),
                                    Text(
                                      'Carbs: ${plan.dailyNutrition!.carbohydrates.toStringAsFixed(1)}g',
                                    ),
                                    Text(
                                      'Fat: ${plan.dailyNutrition!.fat.toStringAsFixed(1)}g',
                                    ),
                                  ],
                                ),
                              ),
                            const Divider(),
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Meals:',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 8),
                                  ...plan.meals.take(5).map((meal) => ListTile(
                                        dense: true,
                                        leading: Icon(
                                          _getMealTypeIcon(meal.mealType),
                                          size: 20,
                                        ),
                                        title: Text(meal.name),
                                        subtitle: Text(
                                          '${DateFormat('MMM d, yyyy').format(meal.date)} • ${meal.mealType}',
                                        ),
                                      )),
                                  if (plan.meals.length > 5)
                                    Text(
                                      '... and ${plan.meals.length - 5} more meals',
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const ImageRecognitionScreen(),
            ),
          );
        },
        icon: const Icon(Icons.camera_alt),
        label: const Text('Scan Food'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
    );
  }

  IconData _getMealTypeIcon(String mealType) {
    switch (mealType.toLowerCase()) {
      case 'breakfast':
        return Icons.wb_sunny;
      case 'lunch':
        return Icons.lunch_dining;
      case 'dinner':
        return Icons.dinner_dining;
      case 'snack':
        return Icons.cookie;
      default:
        return Icons.restaurant;
    }
  }
}

