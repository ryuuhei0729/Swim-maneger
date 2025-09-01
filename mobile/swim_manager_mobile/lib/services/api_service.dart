import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_config.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  late Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  void initialize() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: Duration(milliseconds: AppConfig.connectionTimeout),
      receiveTimeout: Duration(milliseconds: AppConfig.receiveTimeout),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // インターセプターを追加
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // トークンを自動的に追加
        final token = await _storage.read(key: AppConfig.tokenKey);
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          // トークンが無効な場合、リフレッシュトークンで再認証を試行
          final refreshed = await _refreshToken();
          if (refreshed) {
            // 再認証成功時は元のリクエストを再実行
            final token = await _storage.read(key: AppConfig.tokenKey);
            error.requestOptions.headers['Authorization'] = 'Bearer $token';
            final response = await _dio.fetch(error.requestOptions);
            handler.resolve(response);
            return;
          }
        }
        handler.next(error);
      },
    ));
  }

  Future<bool> _refreshToken() async {
    try {
      final refreshToken = await _storage.read(key: AppConfig.refreshTokenKey);
      if (refreshToken == null) return false;

      final response = await _dio.post('/auth/refresh', data: {
        'refresh_token': refreshToken,
      });

      if (response.statusCode == 200) {
        final newToken = response.data['token'];
        final newRefreshToken = response.data['refresh_token'];
        
        await _storage.write(key: AppConfig.tokenKey, value: newToken);
        await _storage.write(key: AppConfig.refreshTokenKey, value: newRefreshToken);
        return true;
      }
    } catch (e) {
      // リフレッシュトークンも無効な場合
      await _clearTokens();
    }
    return false;
  }

  Future<void> _clearTokens() async {
    await _storage.delete(key: AppConfig.tokenKey);
    await _storage.delete(key: AppConfig.refreshTokenKey);
    await _storage.delete(key: AppConfig.userKey);
  }

  // GET リクエスト
  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    return await _dio.get(path, queryParameters: queryParameters);
  }

  // POST リクエスト
  Future<Response> post(String path, {dynamic data}) async {
    return await _dio.post(path, data: data);
  }

  // PUT リクエスト
  Future<Response> put(String path, {dynamic data}) async {
    return await _dio.put(path, data: data);
  }

  // DELETE リクエスト
  Future<Response> delete(String path) async {
    return await _dio.delete(path);
  }

  // PATCH リクエスト
  Future<Response> patch(String path, {dynamic data}) async {
    return await _dio.patch(path, data: data);
  }

  // ファイルアップロード
  Future<Response> uploadFile(String path, FormData formData) async {
    return await _dio.post(path, data: formData);
  }
}
