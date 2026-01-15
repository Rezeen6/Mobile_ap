import 'package:flutter/material.dart';

class WaterTracker extends StatelessWidget {
  final double current;
  final double target;
  final Function(double) onAdd;

  const WaterTracker({
    super.key,
    required this.current,
    required this.target,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final progress = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.water_drop, color: Colors.blue[700]),
                  const SizedBox(width: 8),
                  const Text(
                    'Water Intake',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Text(
                '${current.toStringAsFixed(0)} / ${target.toStringAsFixed(0)} ml',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 20,
              backgroundColor: Colors.blue[100],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[400]!),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildWaterButton(context, 250, '250ml'),
              _buildWaterButton(context, 500, '500ml'),
              _buildWaterButton(context, 1000, '1L'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWaterButton(BuildContext context, double amount, String label) {
    return ElevatedButton.icon(
      onPressed: () => onAdd(amount),
      icon: const Icon(Icons.add),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}

