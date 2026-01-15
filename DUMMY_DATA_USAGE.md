# Using Admin User Dummy Data in Flutter App

## Overview

All graphs, charts, and UI elements in the Flutter app now use **real dummy data from the backend** for the admin user (`admin@gmail.com`).

## Admin User Credentials

- **Email**: `admin@gmail.com`
- **Password**: `admin!@#`

## Data Source

The Flutter app fetches all data from the backend API:
- ✅ **Today's Meals** - Loaded via `TrackingService.loadTodayMeals()`
- ✅ **Weekly Nutrition** - Loaded via `TrackingService.loadWeeklyNutrition()`
- ✅ **Meal Plans** - Fetched from `/api/v1/meal-plans`
- ✅ **Nutrition Data** - Calculated from meals in the database

## Graphs & Charts Using Backend Data

### 1. **Advanced Stats Card**
- Shows today's nutrition (calories, protein, carbs, fat)
- Data source: `trackingService.todayNutrition` (from backend meals)
- Target: Calculated from user profile (TDEE, BMR)

### 2. **Macro Distribution Chart**
- Shows macro breakdown (protein, carbs, fat)
- Data source: `trackingService.todayNutrition` (from backend meals)
- Target: Calculated from user profile

### 3. **Nutrition Progress Charts**
- Shows progress bars for protein, carbs, fat
- Data source: `trackingService.todayNutrition` (from backend meals)
- Target: Calculated from user profile

### 4. **Advanced Macro Trends Chart**
- Shows weekly/monthly trends for macros
- Data source: `trackingService.weeklyNutrition` (from backend meal plans)
- Time ranges: Today, Week (last 7 days), Month (last 30 days)
- Displays: Protein, Carbohydrates, Fat trends over time

### 5. **Today's Meals List**
- Shows all meals logged today
- Data source: `trackingService.todayMeals` (from backend)
- Includes: Meal name, type, time, nutrition info

### 6. **Water Tracker**
- Local tracking (not from backend)
- Persists in app state

## How Data is Loaded

### On App Start / Login

```dart
// Dashboard automatically loads data
WidgetsBinding.instance.addPostFrameCallback((_) {
  final authService = Provider.of<AuthService>(context, listen: false);
  if (authService.isAuthenticated) {
    widget.trackingService.loadTodayMeals();      // Load today's meals
    widget.trackingService.loadWeeklyNutrition(); // Load past 7 days
  }
});
```

### Data Flow

```
Backend Database (Admin User's Meals)
    ↓
API: GET /api/v1/meal-plans (with date filters)
    ↓
ApiService.getMealPlans()
    ↓
TrackingService.loadTodayMeals() / loadWeeklyNutrition()
    ↓
Calculate Nutrition from Meals
    ↓
Update UI (Charts, Graphs, Lists)
```

## Weekly Nutrition Data

The `loadWeeklyNutrition()` method:
- ✅ Fetches meals for **past 7 days** (including today)
- ✅ Calculates daily nutrition from meals
- ✅ Creates a map: `Map<DateTime, NutritionInfo>`
- ✅ Used by Advanced Macro Trends Chart for weekly/monthly views

## Today's Nutrition Data

The `loadTodayMeals()` method:
- ✅ Fetches all meals for **today** (current date)
- ✅ Calculates total nutrition from today's meals
- ✅ Updates `todayNutrition` for charts and progress bars

## Dummy Data Structure

The backend seed script creates:

### User Profile
- Name: Admin User
- Age: 30, Height: 175cm, Weight: 75kg
- Goal: Maintenance
- Activity Level: Moderately Active

### Meals (Past 7 Days)
- **Breakfast**: 3 different meal options
- **Lunch**: 3 different meal options
- **Dinner**: 3 different meal options
- **Snack**: 4 different meal options

Each meal includes:
- ✅ Food items with quantities
- ✅ Complete nutrition data (calories, protein, carbs, fat, fiber, sugar, sodium)
- ✅ Realistic values based on USDA nutrition data

## Running the Seed Script

To create/update dummy data:

```bash
cd backend
source venv/bin/activate
python seed_dummy_data.py
```

This will:
- ✅ Create/update admin user profile
- ✅ Create meals for the past 7 days
- ✅ Add food items with nutrition data
- ✅ Create meal plans for each day

## Debug Logging

The app includes debug logging to track data loading:

```
✅ Today's meals loaded from backend: X meals
   Today's nutrition: XXX kcal, P: XX.Xg, C: XX.Xg, F: XX.Xg

📊 Loaded nutrition for YYYY-MM-DD: XXX kcal, X meals

✅ Weekly nutrition loaded: 7 days with data from backend
   Days with meals: X / 7
```

## Refresh Data

Users can refresh data by:
1. **Pull to refresh** on dashboard
2. **Add new meal** - automatically refreshes today's data
3. **App restart** - loads fresh data from backend

## Notes

- ✅ **No Hardcoded Data** - All data comes from backend API
- ✅ **Real-time Updates** - Data refreshes when meals are added/updated
- ✅ **Error Handling** - Graceful fallback if API fails
- ✅ **Loading States** - Shows loading indicators while fetching
- ✅ **Empty States** - Shows appropriate messages when no data

## Troubleshooting

**Issue**: Graphs showing empty/zero data
- **Solution**: Ensure backend is running and admin user has meals in database
- **Check**: Run seed script to create dummy data

**Issue**: Weekly chart not showing data
- **Solution**: Verify meals exist for the past 7 days in database
- **Check**: Seed script creates meals for past 7 days

**Issue**: Today's nutrition is zero
- **Solution**: Check if meals exist for today's date
- **Check**: Add a meal for today or verify seed script ran correctly

---

**Last Updated**: Current version
**Status**: ✅ All graphs use backend dummy data for admin user

