import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/tracking_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/nutrition_chart.dart';
import '../../models/meal_model.dart';
import '../meal_plan/add_meal_screen.dart';

class NutritionTrackingScreen extends StatelessWidget {
  const NutritionTrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.user;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nutrition Tracking'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AddMealScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<TrackingService>(
        builder: (context, trackingService, _) {
          final targetNutrition = trackingService.getTargetNutrition(user);
          final currentNutrition = trackingService.todayNutrition;

          if (trackingService.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: () async {
              await trackingService.loadTodayMeals();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Summary Card
                  _buildSummaryCard(context, currentNutrition, targetNutrition),
                  const SizedBox(height: 20),

                  // Detailed Nutrition Charts
                  const Text(
                    'Macronutrients',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  NutritionChart(
                    current: currentNutrition,
                    target: targetNutrition,
                    nutrient: 'calories',
                    color: Colors.orange,
                  ),
                  const SizedBox(height: 12),
                  NutritionChart(
                    current: currentNutrition,
                    target: targetNutrition,
                    nutrient: 'protein',
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 12),
                  NutritionChart(
                    current: currentNutrition,
                    target: targetNutrition,
                    nutrient: 'carbs',
                    color: Colors.green,
                  ),
                  const SizedBox(height: 12),
                  NutritionChart(
                    current: currentNutrition,
                    target: targetNutrition,
                    nutrient: 'fat',
                    color: Colors.purple,
                  ),
                  const SizedBox(height: 20),

                  // Weekly Chart
                  if (trackingService.weeklyNutrition.isNotEmpty) ...[
                    WeeklyCaloriesChart(
                      weeklyData: trackingService.weeklyNutrition,
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Quick Actions
                  _buildQuickActions(context),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    NutritionInfo? current,
    NutritionInfo? target,
  ) {
    final calories = current?.calories ?? 0.0;
    final targetCalories = target?.calories ?? 2000.0;
    final progress = targetCalories > 0 ? (calories / targetCalories).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.orange[400]!,
            Colors.orange[600]!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Today\'s Summary',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                'Calories',
                calories.toStringAsFixed(0),
                targetCalories.toStringAsFixed(0),
                Colors.white,
              ),
              _buildStatItem(
                'Protein',
                (current?.protein ?? 0).toStringAsFixed(0),
                (target?.protein ?? 0).toStringAsFixed(0),
                Colors.white,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                'Carbs',
                (current?.carbohydrates ?? 0).toStringAsFixed(0),
                (target?.carbohydrates ?? 0).toStringAsFixed(0),
                Colors.white,
              ),
              _buildStatItem(
                'Fat',
                (current?.fat ?? 0).toStringAsFixed(0),
                (target?.fat ?? 0).toStringAsFixed(0),
                Colors.white,
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: Colors.white.withOpacity(0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${(progress * 100).toStringAsFixed(0)}% of daily calories',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String current, String target, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: color.withOpacity(0.9),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$current / $target',
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AddMealScreen(mealType: 'breakfast'),
                    ),
                  );
                },
                icon: const Icon(Icons.breakfast_dining),
                label: const Text('Log Breakfast'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AddMealScreen(mealType: 'lunch'),
                    ),
                  );
                },
                icon: const Icon(Icons.lunch_dining),
                label: const Text('Log Lunch'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AddMealScreen(mealType: 'dinner'),
                    ),
                  );
                },
                icon: const Icon(Icons.dinner_dining),
                label: const Text('Log Dinner'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AddMealScreen(mealType: 'snack'),
                    ),
                  );
                },
                icon: const Icon(Icons.cookie),
                label: const Text('Log Snack'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
