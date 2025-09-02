import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_config.dart';
import 'dart:async'; // Added for Completer

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  late Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Single-flight mechanism for token refresh
  Future<bool>? _refreshFuture;

  void initialize() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: Duration(milliseconds: AppConfig.connectionTimeout),
      receiveTimeout: Duration(milliseconds: AppConfig.receiveTimeout),
      headers: {
        'Accept': 'application/json',
      },
    ));

    // インターセプターを追加
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // skipAuthフラグが設定されている場合は認証処理をスキップ
        if (options.extra['skipAuth'] == true) {
          handler.next(options);
          return;
        }
        
        // トークンを自動的に追加
        final token = await _storage.read(key: AppConfig.tokenKey);
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        
        // データ型に応じて適切なContent-Typeを設定
        if (options.data is FormData) {
          // FormDataの場合は、Dioが自動的にmultipart/form-dataとboundaryを設定
          // 手動でContent-Typeを設定するとboundaryが正しく設定されない
        } else if (options.data != null) {
          // JSONデータの場合はapplication/jsonを設定
          options.headers['Content-Type'] = 'application/json';
        }
        
        handler.next(options);
      },
      onError: (error, handler) async {
        // skipAuthフラグが設定されている場合は認証処理をスキップ
        if (error.requestOptions.extra['skipAuth'] == true) {
          handler.next(error);
          return;
        }
        
        // 既にリトライ済みの場合は再処理しない
        if (error.requestOptions.extra['isRetry'] == true) {
          handler.next(error);
          return;
        }
        
        if (error.response?.statusCode == 401) {
          try {
            // Single-flight refresh: 既にリフレッシュ中の場合は完了を待つ
            await _refreshToken();
            
            // リフレッシュ成功時は元のリクエストを再実行（1回のみ）
            final token = await _storage.read(key: AppConfig.tokenKey);
            if (token != null) {
              // リトライフラグを設定
              error.requestOptions.extra['isRetry'] = true;
              error.requestOptions.headers['Authorization'] = 'Bearer $token';
              
              final response = await _dio.fetch(error.requestOptions);
              handler.resolve(response);
              return;
            }
          } catch (e) {
            // リフレッシュ失敗時はエラーをそのまま返す
          }
        }
        handler.next(error);
      },
    ));
  }

  /// 実際のトークンリフレッシュを実行するヘルパーメソッド
  Future<bool> _doRefreshToken() async {
    try {
      final refreshToken = await _storage.read(key: AppConfig.refreshTokenKey);
      if (refreshToken == null) {
        return false;
      }

      // リフレッシュリクエストにはskipAuthフラグを設定
      final response = await _dio.post(
        '/auth/refresh',
        data: {
          'refresh_token': refreshToken,
        },
        options: Options(
          extra: {
            'skipAuth': true, // 認証インターセプターをスキップ
          },
        ),
      );

      if (response.statusCode == 200) {
        final newToken = response.data['token'];
        final newRefreshToken = response.data['refresh_token'];
        
        await _storage.write(key: AppConfig.tokenKey, value: newToken);
        await _storage.write(key: AppConfig.refreshTokenKey, value: newRefreshToken);
        
        return true;
      } else {
        // 非200レスポンスの場合はトークンをクリア
        await _clearTokens();
        return false;
      }
    } catch (e) {
      // 例外が発生した場合はトークンをクリア
      await _clearTokens();
      return false;
    }
  }

  Future<bool> _refreshToken() async {
    // 既にリフレッシュ中の場合は、同じFutureを待つ
    if (_refreshFuture != null) {
      return await _refreshFuture!;
    }

    // 新しいリフレッシュを開始
    _refreshFuture = _doRefreshToken().whenComplete(() {
      // 完了時に参照をクリア
      _refreshFuture = null;
    });

    return await _refreshFuture!;
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
    // FormDataの場合、Dioが自動的にmultipart/form-dataとboundaryを設定
    // 手動でContent-Typeを設定するとboundaryが正しく設定されない
    return await _dio.post(path, data: formData);
  }
}
