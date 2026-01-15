import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../services/tracking_service.dart';
import '../../models/meal_model.dart';
import 'package:intl/intl.dart';
import 'image_recognition_screen.dart';

class AddMealScreen extends StatefulWidget {
  final Meal? existingMeal;
  final String? mealType;
  final FoodItem? initialFoodItem;

  const AddMealScreen({
    super.key,
    this.existingMeal,
    this.mealType,
    this.initialFoodItem,
  });

  @override
  State<AddMealScreen> createState() => _AddMealScreenState();
}

class _AddMealScreenState extends State<AddMealScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedMealType;
  DateTime _selectedDate = DateTime.now();
  final List<FoodItem> _foodItems = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedMealType = widget.mealType ?? 'breakfast';
    if (widget.existingMeal != null) {
      _nameController.text = widget.existingMeal!.name;
      _descriptionController.text = widget.existingMeal!.description ?? '';
      _selectedMealType = widget.existingMeal!.mealType;
      _selectedDate = widget.existingMeal!.date;
      _foodItems.addAll(widget.existingMeal!.foods);
    } else if (widget.initialFoodItem != null) {
      // Pre-fill with food item from image recognition
      _foodItems.add(widget.initialFoodItem!);
      _nameController.text = widget.initialFoodItem!.name;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveMeal() async {
    if (!_formKey.currentState!.validate()) return;
    if (_foodItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one food item'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      
      // Analyze nutrition
      final nutrition = await apiService.analyzeNutrition(_foodItems);

      // Create meal data - use FoodItem.toJson() but remove id and nutrition (backend calculates it)
      final mealData = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        'meal_type': _selectedMealType,
        'date': _selectedDate.toIso8601String(),
        'foods': _foodItems.map((f) => {
          'name': f.name,
          'quantity': f.quantity,
          'unit': f.unit ?? 'g',
        }).toList(),
        'nutrition': nutrition.toJson(),
      };

      // Save meal to backend
      await apiService.createMeal(mealData);

      // Refresh tracking service to update today's progress
      final trackingService = Provider.of<TrackingService>(context, listen: false);
      await trackingService.loadTodayMeals();
      await trackingService.loadWeeklyNutrition();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Meal saved successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _addFoodItem() {
    showDialog(
      context: context,
      builder: (context) => _AddFoodItemDialog(
        onAdd: (foodItem) {
          setState(() {
            _foodItems.add(foodItem);
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(
          widget.existingMeal == null ? 'Add Meal' : 'Edit Meal',
          style: const TextStyle(fontWeight: FontWeight.w600),
              ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Form(
        key: _formKey,
        child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header chip row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Chip(
                          avatar: const Icon(Icons.restaurant, size: 18),
                          label: Text(
                            _selectedMealType != null
                                ? _selectedMealType![0].toUpperCase() +
                                    _selectedMealType!.substring(1)
                                : 'Meal',
                          ),
                        ),
                        Chip(
                          avatar: const Icon(Icons.fastfood, size: 18),
                          label: Text('${_foodItems.length} items'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Card: basic info
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                                labelText: 'Meal name',
                                hintText: 'e.g. Oatmeal with fruits',
                                prefixIcon: Icon(Icons.restaurant_menu),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a meal name';
                  }
                  return null;
                },
              ),
                            const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                                labelText: 'Description (optional)',
                                hintText: 'Add notes or details',
                                prefixIcon: Icon(Icons.description_outlined),
                ),
                maxLines: 2,
              ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Card: meal meta (type + date)
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Meal details',
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Meal type',
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(color: theme.hintColor),
                ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              children: [
                                _MealTypeChip(
                                  label: 'Breakfast',
                                  value: 'breakfast',
                                  groupValue: _selectedMealType,
                                  onChanged: (value) => setState(
                                    () => _selectedMealType = value,
                                  ),
                                ),
                                _MealTypeChip(
                                  label: 'Lunch',
                                  value: 'lunch',
                                  groupValue: _selectedMealType,
                                  onChanged: (value) => setState(
                                    () => _selectedMealType = value,
                                  ),
                                ),
                                _MealTypeChip(
                                  label: 'Dinner',
                                  value: 'dinner',
                                  groupValue: _selectedMealType,
                                  onChanged: (value) => setState(
                                    () => _selectedMealType = value,
                                  ),
                                ),
                                _MealTypeChip(
                                  label: 'Snack',
                                  value: 'snack',
                                  groupValue: _selectedMealType,
                                  onChanged: (value) => setState(
                                    () => _selectedMealType = value,
                                  ),
                                ),
                              ],
              ),
              const SizedBox(height: 16),
                            Text(
                              'Date',
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(color: theme.hintColor),
                            ),
                            const SizedBox(height: 8),
              InkWell(
                              borderRadius: BorderRadius.circular(12),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                                  firstDate: DateTime.now()
                                      .subtract(const Duration(days: 30)),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setState(() => _selectedDate = date);
                  }
                },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: theme.dividerColor,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.calendar_today_outlined),
                                    const SizedBox(width: 12),
                                    Text(
                                      DateFormat('MMM d, yyyy')
                                          .format(_selectedDate),
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                  ],
                ),
              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Food items section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                        Text(
                          'Food items',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextButton.icon(
                              onPressed: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const ImageRecognitionScreen(),
                                  ),
                                );
                                // If food item was added from image recognition, refresh
                                if (result != null) {
                                  setState(() {});
                                }
                              },
                              icon: const Icon(Icons.camera_alt, size: 18),
                              label: const Text('Scan'),
                            ),
                            TextButton.icon(
                              onPressed: _addFoodItem,
                              icon: const Icon(Icons.add),
                              label: const Text('Add'),
                            ),
                          ],
                        ),
                ],
              ),
                    const SizedBox(height: 8),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: _foodItems.isEmpty
                          ? Container(
                              key: const ValueKey('empty'),
                              padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceVariant
                                    .withOpacity(0.4),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: theme.dividerColor.withOpacity(0.4),
                                ),
                  ),
                  child: Column(
                                mainAxisSize: MainAxisSize.min,
                    children: [
                                  Icon(
                                    Icons.fastfood_outlined,
                                    size: 40,
                                    color:
                                        theme.hintColor.withOpacity(0.8),
                                  ),
                      const SizedBox(height: 8),
                      Text(
                                    'No food items yet',
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Tap "Add" to start building your meal.',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.hintColor,
                                    ),
                                    textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
                          : Column(
                              key: const ValueKey('list'),
                              children: _foodItems
                                  .asMap()
                                  .entries
                                  .map(
                                    (entry) {
                  final index = entry.key;
                  final item = entry.value;
                  return Card(
                                        margin:
                                            const EdgeInsets.only(bottom: 8),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                    child: ListTile(
                                          leading: CircleAvatar(
                                            backgroundColor: theme
                                                .colorScheme.primary
                                                .withOpacity(0.1),
                                            child: Icon(
                                              Icons.restaurant,
                                              color: theme
                                                  .colorScheme.primary,
                                            ),
                                          ),
                      title: Text(item.name),
                                          subtitle: Text(
                                            '${item.quantity}${item.unit ?? 'g'}',
                                          ),
                      trailing: IconButton(
                                            icon: const Icon(
                                              Icons.delete_outline,
                                              color: Colors.redAccent,
                                            ),
                        onPressed: () {
                          setState(() {
                            _foodItems.removeAt(index);
                          });
                        },
                      ),
                    ),
                  );
                                    },
                                  )
                                  .toList(),
                            ),
                    ),
            ],
          ),
              ),
            ),

            // Bottom sticky action bar
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _addFoodItem,
                          icon: const Icon(Icons.add),
                          label: const Text('Add food'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _saveMeal,
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor:
                                        AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Text('Save meal'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddFoodItemDialog extends StatefulWidget {
  final Function(FoodItem) onAdd;

  const _AddFoodItemDialog({required this.onAdd});

  @override
  State<_AddFoodItemDialog> createState() => _AddFoodItemDialogState();
}

class _AddFoodItemDialogState extends State<_AddFoodItemDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController(text: '100');
  String _unit = 'g';

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  void _add() {
    if (!_formKey.currentState!.validate()) return;

    final item = FoodItem(
      name: _nameController.text.trim(),
      quantity: double.tryParse(_quantityController.text) ?? 100,
      unit: _unit,
    );

    widget.onAdd(item);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Add food item'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Food name',
                hintText: 'e.g. Apple, Rice, Chicken breast',
                prefixIcon: Icon(Icons.fastfood_outlined),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter food name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _quantityController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Quantity',
                      prefixIcon: Icon(Icons.scale_outlined),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Invalid number';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _unit,
                    decoration: const InputDecoration(
                      labelText: 'Unit',
                    ),
                    items: const [
                      DropdownMenuItem(value: 'g', child: Text('g')),
                      DropdownMenuItem(value: 'ml', child: Text('ml')),
                      DropdownMenuItem(value: 'oz', child: Text('oz')),
                    ],
                    onChanged: (value) => setState(() => _unit = value!),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actionsPadding:
          const EdgeInsets.only(left: 16, right: 16, bottom: 12, top: 0),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(
            foregroundColor: theme.colorScheme.secondary,
          ),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          onPressed: _add,
          icon: const Icon(Icons.check),
          label: const Text('Add'),
        ),
      ],
    );
  }
}

class _MealTypeChip extends StatelessWidget {
  final String label;
  final String value;
  final String? groupValue;
  final ValueChanged<String>? onChanged;

  const _MealTypeChip({
    required this.label,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selected = value == groupValue;

    return ChoiceChip(
      selected: selected,
      label: Text(label),
      labelStyle: TextStyle(
        color: selected ? theme.colorScheme.onPrimary : null,
      ),
      selectedColor: theme.colorScheme.primary,
      onSelected: (_) => onChanged?.call(value),
    );
  }
}

