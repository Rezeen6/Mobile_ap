import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/user_model.dart';
import '../models/meal_model.dart';

class AdvancedStatsCard extends StatelessWidget {
  final User? user;
  final NutritionInfo? todayNutrition;
  final NutritionInfo? targetNutrition;
  final double? weightChange;
  final int? steps;

  const AdvancedStatsCard({
    super.key,
    this.user,
    this.todayNutrition,
    this.targetNutrition,
    this.weightChange,
    this.steps,
  });

  @override
  Widget build(BuildContext context) {
    final bmi = user?.bmi;
    final calories = todayNutrition?.calories ?? 0.0;
    final targetCalories = targetNutrition?.calories ?? 2000.0;
    final progress = targetCalories > 0 ? (calories / targetCalories).clamp(0.0, 1.0) : 0.0;

    // Use green color scheme to match the design
    final cardColor = Colors.green[600] ?? const Color(0xFF4CAF50);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            cardColor,
            cardColor.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: cardColor.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Today\'s Progress',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    NumberFormat('#,###').format(calories),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      height: 1.0,
                    ),
                  ),
                  Text(
                    'of ${NumberFormat('#,###').format(targetCalories)} kcal',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.local_fire_department,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 12,
              backgroundColor: Colors.white.withOpacity(0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(progress * 100).toStringAsFixed(0)}% Complete',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (steps != null)
                Row(
                  children: [
                    const Icon(Icons.directions_walk, color: Colors.white, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${NumberFormat('#,###').format(steps)} steps',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          // Always show BMI if available, or show a placeholder for testing
          if (bmi != null) ...[
            const SizedBox(height: 20),
            const Divider(color: Colors.white30),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildStatItem(
                  'BMI',
                  bmi.toStringAsFixed(1),
                  _getBMICategory(bmi),
                  Icons.monitor_weight_outlined,
                ),
                if (weightChange != null) ...[
                  const SizedBox(width: 40),
                  _buildStatItem(
                    'Weight',
                    weightChange! > 0 ? '+${weightChange!.toStringAsFixed(1)}' : weightChange!.toStringAsFixed(1),
                    'kg this week',
                    Icons.trending_up,
                    color: weightChange! > 0 ? Colors.red[300] : Colors.green[300],
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, String subtitle, IconData icon, {Color? color}) {
    return Column(
      children: [
        Icon(icon, color: color ?? Colors.white, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: color ?? Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 12,
          ),
        ),
        if (subtitle.isNotEmpty)
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 10,
            ),
          ),
      ],
    );
  }

  String _getBMICategory(double bmi) {
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Normal';
    if (bmi < 30) return 'Overweight';
    return 'Obese';
  }
}

