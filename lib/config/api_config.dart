import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiConfig {
  // Backend configuration
  // USB Connection (No Internet Needed):
  //   1. Connect device via USB
  //   2. Run: adb reverse tcp:8000 tcp:8000
  //   3. App uses localhost:8000 (no internet required!)
  //
  // For Emulator: Can use localhost (with ADB reverse) or 10.0.2.2 (without ADB reverse)
  static const String _defaultHost = 'localhost';  // Works with ADB reverse - USB connection, no internet needed!
  static const String _defaultPort = '8000';
  static const String _apiPath = '/api/v1';
  
  static const String _backendHostKey = 'backend_host';
  static const String _backendPortKey = 'backend_port';
  
  // Cached values (loaded from SharedPreferences on initialization)
  static String? _cachedHost;
  static String? _cachedPort;
  static bool _initialized = false;
  
  // Initialize backend configuration from SharedPreferences
  // Call this on app startup (e.g., in main.dart)
  static Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      _cachedHost = prefs.getString(_backendHostKey) ?? _defaultHost;
      _cachedPort = prefs.getString(_backendPortKey) ?? _defaultPort;
      _initialized = true;
      
      if (kDebugMode) {
        print('🔧 Backend initialized: http://$_cachedHost:$_cachedPort$_apiPath');
        print('💡 For USB connection: Run "adb reverse tcp:8000 tcp:8000" on your computer');
        print('💡 For emulator: localhost works with ADB reverse, or use 10.0.2.2');
      }
    } catch (e) {
      // Fallback to defaults if SharedPreferences fails
      _cachedHost = _defaultHost;
      _cachedPort = _defaultPort;
      _initialized = true;
      if (kDebugMode) {
        print('⚠️ Failed to load backend config, using defaults: http://$_cachedHost:$_cachedPort$_apiPath');
      }
    }
  }
  
  // Synchronous getter for base URL (uses cached or default values)
  static String get baseUrl {
    final host = _cachedHost ?? _defaultHost;
    final port = _cachedPort ?? _defaultPort;
    return 'http://$host:$port$_apiPath';
  }
  
  // Set custom backend host (for physical devices)
  static Future<void> setBackendHost(String host, {String port = '8000'}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_backendHostKey, host);
    await prefs.setString(_backendPortKey, port);
    
    // Update cache
    _cachedHost = host;
    _cachedPort = port;
    
    if (kDebugMode) {
      print('🔧 Backend host updated to: http://$host:$port$_apiPath');
    }
  }
  
  // Reset to default (emulator settings)
  static Future<void> resetToDefault() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_backendHostKey);
    await prefs.remove(_backendPortKey);
    
    // Update cache
    _cachedHost = _defaultHost;
    _cachedPort = _defaultPort;
    
    if (kDebugMode) {
      print('🔧 Backend host reset to default: http://$_defaultHost:$_defaultPort$_apiPath');
    }
  }
  
  // Get current backend configuration
  static Map<String, String> getBackendConfig() {
    return {
      'host': _cachedHost ?? _defaultHost,
      'port': _cachedPort ?? _defaultPort,
      'url': baseUrl,
    };
  }
  
  // API Endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String profile = '/users/profile';
  static const String updateProfile = '/users/profile';
  static const String mealPlans = '/meal-plans';
  static const String meals = '/meals';
  static const String nutrition = '/nutrition/analyze';
  static const String recommendations = '/recommendations';
  static const String imageRecognition = '/image-recognition/recognize';
  static const String availableFoods = '/image-recognition/available-foods';
  static const String goals = '/goals';
  static const String progress = '/progress';
  
  // Headers
  static Map<String, String> getHeaders(String? token) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }
}

