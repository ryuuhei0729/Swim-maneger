import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  
  User? _user;
  bool _isLoading = false;
  bool _isAuthenticated = false;
  String? _error;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  String? get error => _error;

  // 初期化
  Future<void> initialize() async {
    _setLoading(true);
    try {
      await _authService.initialize();
      _user = _authService.currentUser;
      _isAuthenticated = _authService.isAuthenticated;
    } catch (e) {
      _setError('初期化に失敗しました');
    } finally {
      _setLoading(false);
    }
  }

  // ログイン
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _clearError();
    
    try {
      final success = await _authService.login(email, password);
      if (success) {
        _user = _authService.currentUser;
        _isAuthenticated = true;
        notifyListeners();
        return true;
      } else {
        _setError('ログインに失敗しました');
        return false;
      }
    } catch (e) {
      _setError('ネットワークエラーが発生しました');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ログアウト
  Future<void> logout() async {
    _setLoading(true);
    
    try {
      await _authService.logout();
    } catch (e) {
      // エラーが発生してもローカルデータはクリアする
    } finally {
      _user = null;
      _isAuthenticated = false;
      _setLoading(false);
      notifyListeners();
    }
  }

  // パスワードリセット
  Future<bool> forgotPassword(String email) async {
    _setLoading(true);
    _clearError();
    
    try {
      final success = await _authService.forgotPassword(email);
      if (!success) {
        _setError('パスワードリセットに失敗しました');
      }
      return success;
    } catch (e) {
      _setError('ネットワークエラーが発生しました');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // パスワード変更
  Future<bool> changePassword(String currentPassword, String newPassword) async {
    _setLoading(true);
    _clearError();
    
    try {
      final success = await _authService.changePassword(currentPassword, newPassword);
      if (!success) {
        _setError('パスワード変更に失敗しました');
      }
      return success;
    } catch (e) {
      _setError('ネットワークエラーが発生しました');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // プロフィール更新
  Future<bool> updateProfile(Map<String, dynamic> profileData) async {
    _setLoading(true);
    _clearError();
    
    try {
      final success = await _authService.updateProfile(profileData);
      if (success) {
        _user = _authService.currentUser;
        notifyListeners();
        return true;
      } else {
        _setError('プロフィール更新に失敗しました');
        return false;
      }
    } catch (e) {
      _setError('ネットワークエラーが発生しました');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // トークン検証
  Future<bool> validateToken() async {
    try {
      final isValid = await _authService.validateToken();
      if (!isValid) {
        // トークンが無効な場合、永続的なトークンを削除し、ローカルユーザー状態をクリア
        await _authService.logout();
        await _clearUserData();
      }
      return isValid;
    } catch (e) {
      return false;
    }
  }

  // ユーザーデータをクリア（永続的なトークンとローカル状態を削除）
  Future<void> _clearUserData() async {
    _user = null;
    _isAuthenticated = false;
    // セキュアストレージからトークンを削除
    await _authService.logout();
    notifyListeners();
  }

  // エラーをクリア
  void _clearError() {
    _error = null;
    notifyListeners();
  }

  // エラーを設定
  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  // ローディング状態を設定
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // ユーザー情報を更新（外部から呼び出し可能）
  void updateUser(User user) {
    _user = user;
    notifyListeners();
  }
}
