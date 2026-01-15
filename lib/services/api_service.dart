import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../config/api_config.dart';
import '../models/user_model.dart';
import '../models/meal_model.dart';
import '../models/meal_plan_model.dart';

class ApiService extends ChangeNotifier {
  String? _token;
  User? _currentUser;

  String? get token => _token;
  User? get currentUser => _currentUser;

  void setToken(String? token) {
    _token = token;
    notifyListeners();
  }

  void setUser(User? user) {
    _currentUser = user;
    notifyListeners();
  }

  Future<dynamic> _request(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');
    final headers = ApiConfig.getHeaders(_token);
    
    if (kDebugMode) {
      print('📤 Making $method request to: $url');
    }

    http.Response response;

    try {
      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(url, headers: headers).timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception('Connection timeout. Please check your internet connection and ensure the backend is running.');
            },
          );
          break;
        case 'POST':
          response = await http.post(
            url,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          ).timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception('Connection timeout. Please check your internet connection and ensure the backend is running.');
            },
          );
          break;
        case 'PUT':
          response = await http.put(
            url,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          ).timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception('Connection timeout. Please check your internet connection and ensure the backend is running.');
            },
          );
          break;
        case 'DELETE':
          response = await http.delete(url, headers: headers).timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception('Connection timeout. Please check your internet connection and ensure the backend is running.');
            },
          );
          break;
        default:
          throw Exception('Unsupported HTTP method');
      }
    } on http.ClientException catch (e) {
      throw Exception('Network error: Unable to connect to server. Please check:\n1. Backend is running\n2. Device and computer are on same network\n3. IP address is correct (${ApiConfig.baseUrl})');
    } on FormatException catch (e) {
      throw Exception('Invalid server response. Please check backend configuration.');
    } catch (e) {
      if (e.toString().contains('timeout') || e.toString().contains('Connection')) {
        rethrow;
      }
      throw Exception('Network error: ${e.toString()}');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return {};
      }
      final decoded = jsonDecode(response.body);
      // Handle both list and map responses from FastAPI
      return decoded;
    } else {
      String errorMessage = 'Request failed';
      try {
        final error = jsonDecode(response.body) as Map<String, dynamic>;
        errorMessage = error['detail'] ?? error['message'] ?? errorMessage;
      } catch (e) {
        errorMessage = response.body.isNotEmpty ? response.body : 'Request failed with status ${response.statusCode}';
      }
      throw Exception(errorMessage);
    }
  }

  // Auth endpoints
  Future<Map<String, dynamic>> login(String email, String password) async {
    print('🔐 Attempting login for: $email');
    final apiUrl = ApiConfig.baseUrl;
    print('🌐 API URL: $apiUrl${ApiConfig.login}');
    try {
      final response = await _request('POST', ApiConfig.login, body: {
        'email': email,
        'password': password,
      });
      print('✅ Login successful, token received');
      return response;
    } catch (e) {
      print('❌ Login error: $e');
      print('🔍 Backend URL: $apiUrl');
      print('💡 Tip: Ensure backend is running on port 8000');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    final response = await _request('POST', ApiConfig.register, body: userData);
    return response;
  }

  // User endpoints
  Future<User> getProfile() async {
    final response = await _request('GET', ApiConfig.profile);
    return User.fromJson(response as Map<String, dynamic>);
  }

  Future<User> updateProfile(Map<String, dynamic> userData) async {
    final response = await _request('PUT', ApiConfig.updateProfile, body: userData);
    return User.fromJson(response as Map<String, dynamic>);
  }

  // Meal Plan endpoints
  Future<List<MealPlan>> getMealPlans({DateTime? startDate, DateTime? endDate}) async {
    String endpoint = ApiConfig.mealPlans;
    if (startDate != null && endDate != null) {
      endpoint += '?start_date=${startDate.toIso8601String()}&end_date=${endDate.toIso8601String()}';
    }
    final response = await _request('GET', endpoint);
    // Response is a list directly from FastAPI
    if (response is List) {
      return (response as List<dynamic>).map((m) => MealPlan.fromJson(m as Map<String, dynamic>)).toList();
    }
    // Fallback if wrapped (shouldn't happen with FastAPI but just in case)
    final List<dynamic> data = (response as Map<String, dynamic>)['data'] as List<dynamic>? ?? [];
    return data.map((m) => MealPlan.fromJson(m as Map<String, dynamic>)).toList();
  }

  Future<MealPlan> createMealPlan(Map<String, dynamic> mealPlanData) async {
    final response = await _request('POST', ApiConfig.mealPlans, body: mealPlanData);
    if (response is Map<String, dynamic>) {
      return MealPlan.fromJson(response);
    }
    return MealPlan.fromJson((response as Map<String, dynamic>)['data'] as Map<String, dynamic>);
  }

  // Generate meal plan automatically
  Future<MealPlan> generateMealPlan({
    required DateTime startDate,
    required DateTime endDate,
    String? goal,
  }) async {
    String endpoint = '${ApiConfig.mealPlans}/generate?start_date=${startDate.toIso8601String()}&end_date=${endDate.toIso8601String()}';
    if (goal != null) {
      endpoint += '&goal=$goal';
    }
    final response = await _request('POST', endpoint);
    if (response is Map<String, dynamic>) {
      return MealPlan.fromJson(response);
    }
    return MealPlan.fromJson((response as Map<String, dynamic>)['data'] as Map<String, dynamic>);
  }

  // Nutrition analysis
  Future<NutritionInfo> analyzeNutrition(List<FoodItem> foods) async {
    final response = await _request('POST', ApiConfig.nutrition, body: {
      'foods': foods.map((f) => f.toJson()).toList(),
    });
    if (response is Map<String, dynamic>) {
      return NutritionInfo.fromJson(response);
    }
    return NutritionInfo.fromJson((response as Map<String, dynamic>)['data'] as Map<String, dynamic>);
  }

  // Create a single meal
  Future<Meal> createMeal(Map<String, dynamic> mealData) async {
    final response = await _request('POST', '${ApiConfig.mealPlans}/meals', body: mealData);
    if (response is Map<String, dynamic>) {
      return Meal.fromJson(response);
    }
    return Meal.fromJson((response as Map<String, dynamic>)['data'] as Map<String, dynamic>);
  }

  // Recommendations
  Future<List<Meal>> getRecommendations({
    required String mealType,
    DateTime? date,
  }) async {
    String endpoint = '${ApiConfig.recommendations}?meal_type=$mealType';
    if (date != null) {
      endpoint += '&date=${date.toIso8601String()}';
    }
    final response = await _request('GET', endpoint);
    // Response is a list directly from FastAPI
    if (response is List) {
      return (response as List<dynamic>).map((m) => Meal.fromJson(m as Map<String, dynamic>)).toList();
    }
    // Fallback if wrapped (shouldn't happen with FastAPI but just in case)
    final List<dynamic> data = (response as Map<String, dynamic>)['data'] as List<dynamic>? ?? [];
    return data.map((m) => Meal.fromJson(m as Map<String, dynamic>)).toList();
  }

  // Image Recognition
  Future<Map<String, dynamic>> recognizeFoodImage(
    File imageFile, {
    double? quantity,
    bool estimatePortion = true,
  }) async {
    print('📸 Starting image upload...');
    print('📁 File path: ${imageFile.path}');
    
    // Check if file exists
    if (!await imageFile.exists()) {
      throw Exception('Image file not found');
    }
    
    // Check file size (limit to 10MB)
    final fileSize = await imageFile.length();
    print('📊 File size: ${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB');
    if (fileSize > 10 * 1024 * 1024) {
      throw Exception('Image file too large. Maximum size is 10MB.');
    }
    if (fileSize == 0) {
      throw Exception('Image file is empty');
    }
    
    String queryParams = 'estimate_portion=$estimatePortion';
    if (quantity != null && quantity > 0) {
      queryParams += '&quantity=$quantity';
    }
    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.imageRecognition}?$queryParams');
    print('🌐 Upload URL: $url');
    
    final headers = {
      'Accept': 'application/json',
      if (_token != null) 'Authorization': 'Bearer $_token',
    };

    try {
      var request = http.MultipartRequest('POST', url);
      request.headers.addAll(headers);
      
      // Determine content type from file extension
      String? contentType;
      final extension = imageFile.path.split('.').last.toLowerCase();
      if (extension == 'jpg' || extension == 'jpeg') {
        contentType = 'image/jpeg';
      } else if (extension == 'png') {
        contentType = 'image/png';
      } else if (extension == 'gif') {
        contentType = 'image/gif';
      } else if (extension == 'webp') {
        contentType = 'image/webp';
      }
      
      // Add image file with proper content type
      var multipartFile = await http.MultipartFile.fromPath(
        'file',
        imageFile.path,
        filename: imageFile.path.split('/').last,
        contentType: contentType != null ? http.MediaType.parse(contentType) : null,
      );
      request.files.add(multipartFile);
      
      print('📤 Sending multipart request...');
      var streamedResponse = await request.send().timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          throw Exception('Upload timeout. Please check your network connection and try again.');
        },
      );
      
      print('📥 Received response, status: ${streamedResponse.statusCode}');
      var response = await http.Response.fromStream(streamedResponse).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Response timeout. Please try again.');
        },
      );

      print('📄 Response body length: ${response.body.length}');
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        try {
          final result = jsonDecode(response.body) as Map<String, dynamic>;
          print('✅ Image recognition successful');
          return result;
        } catch (e) {
          print('❌ Error parsing response: $e');
          throw Exception('Invalid server response format');
        }
      } else {
        String errorMessage = 'Request failed';
        try {
          final error = jsonDecode(response.body) as Map<String, dynamic>;
          errorMessage = error['detail'] ?? error['message'] ?? errorMessage;
          print('❌ Server error: $errorMessage');
        } catch (e) {
          errorMessage = response.body.isNotEmpty ? response.body : 'Request failed with status ${response.statusCode}';
          print('❌ Error parsing error response: $e');
        }
        throw Exception(errorMessage);
      }
    } on SocketException catch (e) {
      print('❌ Network error: $e');
      throw Exception('Network error: Unable to connect to server. Please check:\n1. Backend is running\n2. Device and computer are on same network\n3. IP address is correct (${ApiConfig.baseUrl})');
    } on TimeoutException catch (e) {
      print('❌ Timeout error: $e');
      throw Exception('Upload timeout. The image may be too large or network is slow. Please try again.');
    } catch (e) {
      print('❌ Upload error: $e');
      String errorMsg = e.toString().replaceFirst('Exception: ', '');
      if (errorMsg.contains('timeout') || errorMsg.contains('Timeout')) {
        throw Exception('Upload timeout. Please check your network connection and try again.');
      } else if (errorMsg.contains('SocketException') || errorMsg.contains('Connection')) {
        throw Exception('Network error: Unable to connect to server. Please check your network connection.');
      } else {
        throw Exception('Error uploading image: $errorMsg');
      }
    }
  }

  // Get available foods for recognition
  Future<List<String>> getAvailableFoods() async {
    final response = await _request('GET', ApiConfig.availableFoods);
    if (response is Map<String, dynamic> && response['foods'] != null) {
      return (response['foods'] as List<dynamic>).map((f) => f.toString()).toList();
    }
    return [];
  }
}

