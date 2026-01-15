import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import '../models/user_model.dart';

class AuthService extends ChangeNotifier {
  final ApiService _apiService;
  ApiService? _sharedApiService; // Reference to the Provider's ApiService
  User? _user;
  bool _isAuthenticated = false;
  bool _isLoading = false;

  AuthService({ApiService? sharedApiService}) 
      : _apiService = ApiService(),
        _sharedApiService = sharedApiService {
    _loadAuthState();
  }

  // Method to set the shared ApiService instance (called from main.dart)
  void setSharedApiService(ApiService apiService) {
    _sharedApiService = apiService;
    // Defer token sync to happen asynchronously, to avoid notifying listeners
    // during the widget build phase.
    _syncTokenFromStorage();
  }

  // Helper method to sync token from storage to shared ApiService
  Future<void> _syncTokenFromStorage() async {
    if (_sharedApiService == null) return;
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token != null && _sharedApiService?.token != token) {
      _sharedApiService?.setToken(token);
    }
  }

  User? get user => _user;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;

  Future<void> _loadAuthState() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      if (token != null) {
        _apiService.setToken(token);
        _sharedApiService?.setToken(token); // Also set token on Provider's instance
        _user = await _apiService.getProfile();
        _isAuthenticated = true;
      }
    } catch (e) {
      await _clearAuthState();
    } finally {
      _isLoading = false;
      // Ensure token is synced to shared ApiService (in case it was set up after _loadAuthState started)
      await _syncTokenFromStorage();
      notifyListeners();
    }
  }

  String? _lastError;
  String? get lastError => _lastError;

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _lastError = null;
    notifyListeners();

    try {
      // Step 1: Login and get token
      final response = await _apiService.login(email, password);
      final token = response['access_token'] as String;
      
      if (token.isEmpty) {
        _lastError = 'Invalid token received from server';
        _isLoading = false;
        notifyListeners();
        return false;
      }
      
      // Step 2: Save token
      await _saveAuthToken(token);
      
      // Step 3: Set token on both API service instances
      _apiService.setToken(token);
      _sharedApiService?.setToken(token);
      
      // Step 4: Try to get user profile (but don't fail login if this fails)
      try {
        _user = await _apiService.getProfile();
      } catch (profileError) {
        // If profile fetch fails, still allow login but log the error
        print('Warning: Could not fetch user profile: $profileError');
        // User will be null but authenticated = true, profile can be loaded later
      }
      
      _isAuthenticated = true;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('Login error: $e');
      String errorMsg = e.toString().replaceFirst('Exception: ', '');
      
      // Provide more specific error messages
      if (errorMsg.contains('Incorrect email or password')) {
        _lastError = 'Incorrect email or password. Please try again.';
      } else if (errorMsg.contains('Network error') || errorMsg.contains('Unable to connect')) {
        _lastError = 'Cannot connect to server. Please check:\n• Backend is running\n• Device and computer are on same WiFi\n• IP: 192.168.1.70:8000';
      } else if (errorMsg.contains('timeout')) {
        _lastError = 'Connection timeout. Check your network connection.';
      } else {
        _lastError = errorMsg;
      }
      
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(Map<String, dynamic> userData) async {
    _isLoading = true;
    _lastError = null;
    notifyListeners();

    try {
      final response = await _apiService.register(userData);
      final token = response['access_token'] as String;
      
      await _saveAuthToken(token);
      _apiService.setToken(token);
      _sharedApiService?.setToken(token); // Also set token on Provider's instance
      _user = await _apiService.getProfile();
      _isAuthenticated = true;
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _lastError = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _clearAuthState();
    _user = null;
    _isAuthenticated = false;
    _apiService.setToken(null);
    _sharedApiService?.setToken(null); // Also clear token on Provider's instance
    notifyListeners();
  }

  Future<void> _saveAuthToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  Future<void> _clearAuthState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  Future<void> updateProfile(Map<String, dynamic> userData) async {
    try {
      _user = await _apiService.updateProfile(userData);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }
}

