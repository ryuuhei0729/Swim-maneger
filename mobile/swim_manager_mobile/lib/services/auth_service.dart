import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_config.dart';
import '../models/user.dart';
import 'api_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final ApiService _apiService = ApiService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  User? _currentUser;
  bool _isAuthenticated = false;

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;

  // 初期化時に保存されたユーザー情報を読み込み
  Future<void> initialize() async {
    final userData = await _storage.read(key: AppConfig.userKey);
    final token = await _storage.read(key: AppConfig.tokenKey);
    
    if (userData != null && token != null) {
      try {
        _currentUser = User.fromJson(jsonDecode(userData));
        _isAuthenticated = true;
      } catch (e) {
        await _clearUserData();
      }
    }
  }

  // ログイン
  Future<bool> login(String email, String password) async {
    try {
      final response = await _apiService.post('/auth/login', data: {
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200) {
        final data = response.data;
        
        // トークンを保存
        await _storage.write(key: AppConfig.tokenKey, value: data['token']);
        if (data['refresh_token'] != null) {
          await _storage.write(key: AppConfig.refreshTokenKey, value: data['refresh_token']);
        }

        // ユーザー情報を保存
        _currentUser = User.fromJson(data['user']);
        await _storage.write(key: AppConfig.userKey, value: jsonEncode(data['user']));
        
        _isAuthenticated = true;
        return true;
      }
    } catch (e) {
      // エラーハンドリング
    }
    return false;
  }

  // ログアウト
  Future<void> logout() async {
    try {
      // サーバーにログアウトリクエストを送信
      await _apiService.post('/auth/logout');
    } catch (e) {
      // エラーが発生してもローカルデータはクリアする
    } finally {
      await _clearUserData();
    }
  }

  // パスワードリセット
  Future<bool> forgotPassword(String email) async {
    try {
      final response = await _apiService.post('/auth/forgot_password', data: {
        'email': email,
      });

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // パスワード変更
  Future<bool> changePassword(String currentPassword, String newPassword) async {
    try {
      final response = await _apiService.put('/auth/change_password', data: {
        'current_password': currentPassword,
        'new_password': newPassword,
      });

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // プロフィール更新
  Future<bool> updateProfile(Map<String, dynamic> profileData) async {
    try {
      final response = await _apiService.put('/auth/profile', data: profileData);

      if (response.statusCode == 200) {
        // ユーザー情報を更新
        _currentUser = User.fromJson(response.data['user']);
        await _storage.write(key: AppConfig.userKey, value: jsonEncode(response.data['user']));
        return true;
      }
    } catch (e) {
      // エラーハンドリング
    }
    return false;
  }

  // ユーザーデータをクリア
  Future<void> _clearUserData() async {
    await _storage.delete(key: AppConfig.tokenKey);
    await _storage.delete(key: AppConfig.refreshTokenKey);
    await _storage.delete(key: AppConfig.userKey);
    
    _currentUser = null;
    _isAuthenticated = false;
  }

  // トークンの有効性をチェック
  Future<bool> validateToken() async {
    try {
      final response = await _apiService.get('/auth/validate');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
