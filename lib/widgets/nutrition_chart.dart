import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/meal_model.dart';

class NutritionChart extends StatelessWidget {
  final NutritionInfo? current;
  final NutritionInfo? target;
  final String nutrient;
  final Color color;

  const NutritionChart({
    super.key,
    required this.current,
    required this.target,
    required this.nutrient,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (target == null) {
      return const SizedBox.shrink();
    }

    final currentValue = _getCurrentValue();
    final targetValue = _getTargetValue();
    final progress = targetValue > 0 ? (currentValue / targetValue).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _getNutrientLabel(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${currentValue.toStringAsFixed(0)} / ${targetValue.toStringAsFixed(0)} ${_getUnit()}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 12,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${(progress * 100).toStringAsFixed(0)}% of daily goal',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  double _getCurrentValue() {
    if (current == null) return 0.0;
    switch (nutrient) {
      case 'calories':
        return current!.calories;
      case 'protein':
        return current!.protein;
      case 'carbs':
        return current!.carbohydrates;
      case 'fat':
        return current!.fat;
      default:
        return 0.0;
    }
  }

  double _getTargetValue() {
    if (target == null) return 0.0;
    switch (nutrient) {
      case 'calories':
        return target!.calories;
      case 'protein':
        return target!.protein;
      case 'carbs':
        return target!.carbohydrates;
      case 'fat':
        return target!.fat;
      default:
        return 0.0;
    }
  }

  String _getNutrientLabel() {
    switch (nutrient) {
      case 'calories':
        return 'Calories';
      case 'protein':
        return 'Protein';
      case 'carbs':
        return 'Carbohydrates';
      case 'fat':
        return 'Fat';
      default:
        return nutrient;
    }
  }

  String _getUnit() {
    switch (nutrient) {
      case 'calories':
        return 'kcal';
      default:
        return 'g';
    }
  }
}

class WeeklyCaloriesChart extends StatelessWidget {
  final Map<DateTime, NutritionInfo> weeklyData;

  const WeeklyCaloriesChart({super.key, required this.weeklyData});

  @override
  Widget build(BuildContext context) {
    if (weeklyData.isEmpty) {
      return Container(
        height: 200,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Text('No data available'),
        ),
      );
    }

    final spots = weeklyData.entries.map((entry) {
      final index = entry.key.weekday - 1;
      return FlSpot(index.toDouble(), entry.value.calories);
    }).toList();

    final maxCalories = weeklyData.values
        .map((n) => n.calories)
        .reduce((a, b) => a > b ? a : b);

    // Calculate horizontal interval, ensuring it's never zero
    final horizontalInterval = maxCalories > 0 ? maxCalories / 5 : 1.0;

    return Container(
      height: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Weekly Calories',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: horizontalInterval,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey[200]!,
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                        if (value.toInt() >= 0 && value.toInt() < 7) {
                          return Text(
                            days[value.toInt()],
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border(
                    bottom: BorderSide(color: Colors.grey[300]!),
                    left: BorderSide(color: Colors.grey[300]!),
                  ),
                ),
                minX: 0,
                maxX: 6,
                minY: 0,
                maxY: maxCalories * 1.2,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: Colors.orange,
                    barWidth: 3,
                    dotData: FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.orange.withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

