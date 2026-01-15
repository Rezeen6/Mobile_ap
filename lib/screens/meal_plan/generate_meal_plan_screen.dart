import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../models/meal_plan_model.dart';

class GenerateMealPlanScreen extends StatefulWidget {
  const GenerateMealPlanScreen({super.key});

  @override
  State<GenerateMealPlanScreen> createState() => _GenerateMealPlanScreenState();
}

class _GenerateMealPlanScreenState extends State<GenerateMealPlanScreen> {
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 6)); // Default: 7 days
  String? _selectedGoal;
  bool _isGenerating = false;

  final List<String> _goals = [
    'weight_loss',
    'muscle_gain',
    'maintenance',
    'diabetes_management',
  ];

  final Map<String, String> _goalLabels = {
    'weight_loss': 'Weight Loss',
    'muscle_gain': 'Muscle Gain',
    'maintenance': 'Maintenance',
    'diabetes_management': 'Diabetes Management',
  };

  Future<void> _selectStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
        if (_endDate.isBefore(_startDate)) {
          _endDate = _startDate.add(const Duration(days: 6));
        }
      });
    }
  }

  Future<void> _selectEndDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: _startDate.add(const Duration(days: 30)),
    );
    if (picked != null && picked != _endDate) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  Future<void> _generateMealPlan() async {
    if (_endDate.isBefore(_startDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('End date must be after start date'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final daysDiff = _endDate.difference(_startDate).inDays + 1;
    if (daysDiff > 30) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Meal plan cannot exceed 30 days'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
    });

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final mealPlan = await apiService.generateMealPlan(
        startDate: _startDate,
        endDate: _endDate,
        goal: _selectedGoal,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Meal plan generated successfully! ${mealPlan.meals.length} meals created.'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.of(context).pop(mealPlan);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating meal plan: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Generate Meal Plan'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            const Text(
              'Create a personalized meal plan',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'AI will generate meals based on your profile and goals',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),
            // Start Date
            Card(
              child: ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('Start Date'),
                subtitle: Text(DateFormat('MMMM d, yyyy').format(_startDate)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: _selectStartDate,
              ),
            ),
            const SizedBox(height: 16),
            // End Date
            Card(
              child: ListTile(
                leading: const Icon(Icons.event),
                title: const Text('End Date'),
                subtitle: Text(DateFormat('MMMM d, yyyy').format(_endDate)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: _selectEndDate,
              ),
            ),
            const SizedBox(height: 16),
            // Days count
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Duration:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${_endDate.difference(_startDate).inDays + 1} days',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Goal Selection
            const Text(
              'Health Goal (Optional)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ..._goals.map((goal) => RadioListTile<String>(
              title: Text(_goalLabels[goal] ?? goal),
              value: goal,
              groupValue: _selectedGoal,
              onChanged: (value) {
                setState(() {
                  _selectedGoal = value;
                });
              },
            )),
            const SizedBox(height: 32),
            // Generate Button
            ElevatedButton.icon(
              onPressed: _isGenerating ? null : _generateMealPlan,
              icon: _isGenerating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome),
              label: Text(_isGenerating ? 'Generating...' : 'Generate Meal Plan'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

