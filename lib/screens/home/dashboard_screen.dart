import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io' show Platform;
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/tracking_service.dart';
import '../../services/api_service.dart';
import '../profile/profile_screen.dart';
import '../meal_plan/meal_plan_screen.dart';
import '../nutrition/nutrition_tracking_screen.dart';
import '../meal_plan/add_meal_screen.dart';
import '../meal_plan/generate_meal_plan_screen.dart';
import '../meal_plan/image_recognition_screen.dart';
import '../../widgets/nutrition_chart.dart';
import '../../widgets/water_tracker.dart';
import '../../widgets/meal_card.dart';
import '../../widgets/advanced_stats_card.dart';
import '../../widgets/macro_distribution_chart.dart';
import '../../widgets/advanced_macro_trends_chart.dart';
import '../../models/meal_model.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  late TrackingService _trackingService;

  @override
  void initState() {
    super.initState();
    final apiService = Provider.of<ApiService>(context, listen: false);
    _trackingService = TrackingService(apiService);
  }

  @override
  Widget build(BuildContext context) {
    // Platform-specific optimizations
    final isIOS = Platform.isIOS;
    final isAndroid = Platform.isAndroid;
    
    return ChangeNotifierProvider.value(
      value: _trackingService,
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: [
            DashboardHome(trackingService: _trackingService),
            const MealPlanScreen(),
            const NutritionTrackingScreen(),
            const ProfileScreen(),
          ],
        ),
        bottomNavigationBar: _buildBottomNavigationBar(isIOS, isAndroid),
        floatingActionButton: _buildFloatingActionButton(),
      ),
    );
  }

  Widget? _buildFloatingActionButton() {
    if (_currentIndex == 0) {
      // Home tab - Log Meal button
      return FloatingActionButton.extended(
        heroTag: "fab_home",
        onPressed: () async {
          HapticFeedback.mediumImpact();
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AddMealScreen(),
            ),
          );
          // Refresh data if meal was saved
          if (result == true) {
            final authService = Provider.of<AuthService>(context, listen: false);
            if (authService.isAuthenticated) {
              await _trackingService.loadTodayMeals();
              await _trackingService.loadWeeklyNutrition();
            }
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Log Meal'),
        elevation: 4,
      );
    } else if (_currentIndex == 1) {
      // Meal Plans tab - Generate Plan button
      return FloatingActionButton.extended(
        heroTag: "fab_meal_plan",
        onPressed: () {
          HapticFeedback.mediumImpact();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const GenerateMealPlanScreen(),
            ),
          );
        },
        icon: const Icon(Icons.auto_awesome),
        label: const Text('Generate Plan'),
      );
    }
    return null;
  }

  Widget _buildBottomNavigationBar(bool isIOS, bool isAndroid) {
    if (isIOS) {
      // iOS-style navigation with CupertinoTabBar
      return NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          HapticFeedback.selectionClick();
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.restaurant_menu_outlined),
            selectedIcon: Icon(Icons.restaurant_menu),
            label: 'Meals',
          ),
          NavigationDestination(
            icon: Icon(Icons.track_changes_outlined),
            selectedIcon: Icon(Icons.track_changes),
            label: 'Nutrition',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      );
    } else {
      // Android-style navigation
      return NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          HapticFeedback.mediumImpact();
          setState(() {
            _currentIndex = index;
          });
        },
        height: 70,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.restaurant_menu_outlined),
            selectedIcon: Icon(Icons.restaurant_menu),
            label: 'Meals',
          ),
          NavigationDestination(
            icon: Icon(Icons.track_changes_outlined),
            selectedIcon: Icon(Icons.track_changes),
            label: 'Nutrition',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      );
    }
  }
}

class DashboardHome extends StatefulWidget {
  final TrackingService trackingService;

  const DashboardHome({super.key, required this.trackingService});

  @override
  State<DashboardHome> createState() => _DashboardHomeState();
}

class _DashboardHomeState extends State<DashboardHome> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _animationController.forward();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authService = Provider.of<AuthService>(context, listen: false);
      if (authService.isAuthenticated) {
        widget.trackingService.loadTodayMeals();
        widget.trackingService.loadWeeklyNutrition();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.user;
    final trackingService = widget.trackingService;
    final targetNutrition = trackingService.getTargetNutrition(user);
    final isIOS = Platform.isIOS;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        systemOverlayStyle: isIOS 
          ? SystemUiOverlayStyle.dark 
          : SystemUiOverlayStyle.light,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hello, ${user?.firstName ?? 'User'}! 👋',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              DateFormat('EEEE, MMMM d').format(DateTime.now()),
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              HapticFeedback.mediumImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Notifications coming soon!'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          HapticFeedback.mediumImpact();
          final authService = Provider.of<AuthService>(context, listen: false);
          if (authService.isAuthenticated) {
            await trackingService.loadTodayMeals();
            await trackingService.loadWeeklyNutrition();
          }
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 100),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Advanced Stats Card
                  _buildAnimatedCard(
                    index: 0,
                    child: ChangeNotifierProvider.value(
                      value: trackingService,
                      child: Consumer<TrackingService>(
                        builder: (context, service, _) {
                          return AdvancedStatsCard(
                            user: user,
                            todayNutrition: service.todayNutrition,
                            targetNutrition: targetNutrition,
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Water Tracker
                  _buildAnimatedCard(
                    index: 1,
                    child: ChangeNotifierProvider.value(
                      value: trackingService,
                      child: Consumer<TrackingService>(
                        builder: (context, service, _) {
                          return WaterTracker(
                            current: service.waterIntake,
                            target: service.getWaterTarget(),
                            onAdd: (amount) {
                              HapticFeedback.lightImpact();
                              service.addWater(amount);
                            },
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Macro Distribution Chart
                  _buildAnimatedCard(
                    index: 2,
                    child: ChangeNotifierProvider.value(
                      value: trackingService,
                      child: Consumer<TrackingService>(
                        builder: (context, service, _) {
                          return MacroDistributionChart(
                            current: service.todayNutrition,
                            target: targetNutrition,
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Nutrition Progress
                  _buildAnimatedCard(
                    index: 3,
                    child: _buildNutritionProgress(trackingService, targetNutrition),
                  ),
                  const SizedBox(height: 16),

                  // Advanced Macronutrient Trends Chart
                  if (trackingService.weeklyNutrition.isNotEmpty || trackingService.todayNutrition != null) ...[
                    _buildAnimatedCard(
                      index: 4,
                      child: ChangeNotifierProvider.value(
                        value: trackingService,
                        child: Consumer<TrackingService>(
                          builder: (context, service, _) {
                            return AdvancedMacroTrendsChart(
                              weeklyData: service.weeklyNutrition,
                              todayNutrition: service.todayNutrition,
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Today's Meals
                  _buildAnimatedCard(
                    index: 5,
                    child: _buildTodaysMeals(trackingService),
                  ),
                  const SizedBox(height: 16),

                  // Quick Actions
                  _buildAnimatedCard(
                    index: 6,
                    child: _buildQuickActions(context),
                  ),
                  const SizedBox(height: 20), // Space for FAB
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedCard({required int index, required Widget child}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (index * 100)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  Widget _buildNutritionProgress(TrackingService service, NutritionInfo? target) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Nutrition Progress',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        NutritionChart(
          current: service.todayNutrition,
          target: target,
          nutrient: 'protein',
          color: Colors.blue,
        ),
        const SizedBox(height: 12),
        NutritionChart(
          current: service.todayNutrition,
          target: target,
          nutrient: 'carbs',
          color: Colors.green,
        ),
        const SizedBox(height: 12),
        NutritionChart(
          current: service.todayNutrition,
          target: target,
          nutrient: 'fat',
          color: Colors.purple,
        ),
      ],
    );
  }

  Widget _buildTodaysMeals(TrackingService service) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Today's Meals",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton.icon(
              onPressed: () {
                HapticFeedback.mediumImpact();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AddMealScreen(),
                  ),
                ).then((result) {
                  if (result == true) {
                    service.loadTodayMeals();
                  }
                });
              },
              icon: const Icon(Icons.add_circle_outline, size: 18),
              label: const Text('Add Meal'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ChangeNotifierProvider.value(
          value: service,
          child: Consumer<TrackingService>(
            builder: (context, service, _) {
              if (service.isLoading) {
                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    );
                  },
                );
              }

              final meals = service.todayMeals;
              if (meals.isEmpty) {
                return _buildEmptyMealsState();
              }

              return Column(
                children: meals.asMap().entries.map((entry) {
                  final index = entry.key;
                  final meal = entry.value;
                  return TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: Duration(milliseconds: 300 + (index * 100)),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(20 * (1 - value), 0),
                          child: child,
                        ),
                      );
                    },
                    child: Padding(
                      padding: EdgeInsets.only(bottom: index < meals.length - 1 ? 12 : 0),
                      child: MealCard(
                        meal: meal,
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AddMealScreen(existingMeal: meal),
                            ),
                          ).then((result) {
                            if (result == true) {
                              service.loadTodayMeals();
                            }
                          });
                        },
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyMealsState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Icon(
            Icons.restaurant_menu,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No meals logged today',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the button below to log your first meal',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.user;

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
              child: _buildActionCard(
                context,
                icon: Icons.camera_alt,
                title: 'Scan Food',
                color: Colors.blue,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ImageRecognitionScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                context,
                icon: Icons.auto_awesome,
                title: 'Get Recommendations',
                color: Colors.purple,
                onTap: () {
                  // TODO: Navigate to recommendations
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Recommendations coming soon!'),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                context,
                icon: Icons.calendar_today,
                title: 'Meal Plan',
                color: Colors.green,
                onTap: () {
                  // Navigate to meal plan screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MealPlanScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                context,
                icon: Icons.add_circle,
                title: 'Add Meal',
                color: Colors.orange,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AddMealScreen(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.mediumImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
