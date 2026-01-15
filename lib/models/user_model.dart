class User {
  final String? id;
  final String email;
  final String? firstName;
  final String? lastName;
  final int? age;
  final String? gender;
  final double? height; // in cm
  final double? weight; // in kg
  final String? activityLevel;
  final List<String>? medicalConditions;
  final List<String>? foodPreferences;
  final List<String>? allergies;
  final String? healthGoal;
  final double? targetWeight;
  final DateTime? createdAt;

  User({
    this.id,
    required this.email,
    this.firstName,
    this.lastName,
    this.age,
    this.gender,
    this.height,
    this.weight,
    this.activityLevel,
    this.medicalConditions,
    this.foodPreferences,
    this.allergies,
    this.healthGoal,
    this.targetWeight,
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String?,
      email: json['email'] as String,
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      age: json['age'] as int?,
      gender: json['gender'] as String?,
      height: json['height'] != null ? (json['height'] as num).toDouble() : null,
      weight: json['weight'] != null ? (json['weight'] as num).toDouble() : null,
      activityLevel: json['activity_level'] as String?,
      medicalConditions: json['medical_conditions'] != null
          ? List<String>.from(json['medical_conditions'])
          : null,
      foodPreferences: json['food_preferences'] != null
          ? List<String>.from(json['food_preferences'])
          : null,
      allergies: json['allergies'] != null
          ? List<String>.from(json['allergies'])
          : null,
      healthGoal: json['health_goal'] as String?,
      targetWeight: json['target_weight'] != null
          ? (json['target_weight'] as num).toDouble()
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'email': email,
      if (firstName != null) 'first_name': firstName,
      if (lastName != null) 'last_name': lastName,
      if (age != null) 'age': age,
      if (gender != null) 'gender': gender,
      if (height != null) 'height': height,
      if (weight != null) 'weight': weight,
      if (activityLevel != null) 'activity_level': activityLevel,
      if (medicalConditions != null) 'medical_conditions': medicalConditions,
      if (foodPreferences != null) 'food_preferences': foodPreferences,
      if (allergies != null) 'allergies': allergies,
      if (healthGoal != null) 'health_goal': healthGoal,
      if (targetWeight != null) 'target_weight': targetWeight,
    };
  }

  double? get bmi {
    if (height != null && weight != null && height! > 0) {
      return weight! / ((height! / 100) * (height! / 100));
    }
    return null;
  }
}

