class AppConfig {
  // API設定
  static const String baseUrl = 'http://localhost:3000';
  static const String apiVersion = 'v1';
  static const String apiBaseUrl = '$baseUrl/api/$apiVersion';
  
  // 認証設定
  static const String tokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userKey = 'user_data';
  
  // アプリ設定
  static const String appName = 'Swim Manager';
  static const String appVersion = '1.0.0';
  
  // タイムアウト設定
  static const int connectionTimeout = 30000; // 30秒
  static const int receiveTimeout = 30000; // 30秒
  
  // ページネーション設定
  static const int defaultPageSize = 20;
  
  // 開発環境フラグ
  static const bool isDevelopment = true;
}
