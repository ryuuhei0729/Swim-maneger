import '../models/practice_log.dart';
import 'api_service.dart';

class PracticeService {
  static final PracticeService _instance = PracticeService._internal();
  factory PracticeService() => _instance;
  PracticeService._internal();

  final ApiService _apiService = ApiService();

  // 練習記録一覧を取得
  Future<List<PracticeLog>> getPracticeLogs({int? page, int? perPage}) async {
    try {
      final response = await _apiService.get('/practice_logs', queryParameters: {
        if (page != null) 'page': page,
        if (perPage != null) 'per_page': perPage,
      });

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['practice_logs'];
        return data.map((json) => PracticeLog.fromJson(json)).toList();
      }
    } catch (e) {
      // エラーハンドリング
    }
    return [];
  }

  // 練習記録詳細を取得
  Future<PracticeLog?> getPracticeLog(int id) async {
    try {
      final response = await _apiService.get('/practice_logs/$id');

      if (response.statusCode == 200) {
        return PracticeLog.fromJson(response.data['practice_log']);
      }
    } catch (e) {
      // エラーハンドリング
    }
    return null;
  }

  // 練習記録を作成
  Future<PracticeLog?> createPracticeLog(Map<String, dynamic> data) async {
    try {
      final response = await _apiService.post('/practice_logs', data: data);

      if (response.statusCode == 201) {
        return PracticeLog.fromJson(response.data['practice_log']);
      }
    } catch (e) {
      // エラーハンドリング
    }
    return null;
  }

  // 練習記録を更新
  Future<PracticeLog?> updatePracticeLog(int id, Map<String, dynamic> data) async {
    try {
      final response = await _apiService.put('/practice_logs/$id', data: data);

      if (response.statusCode == 200) {
        return PracticeLog.fromJson(response.data['practice_log']);
      }
    } catch (e) {
      // エラーハンドリング
    }
    return null;
  }

  // 練習記録を削除
  Future<bool> deletePracticeLog(int id) async {
    try {
      final response = await _apiService.delete('/practice_logs/$id');
      return response.statusCode == 204;
    } catch (e) {
      // エラーハンドリング
    }
    return false;
  }

  // 今日の練習記録を取得
  Future<PracticeLog?> getTodayPracticeLog() async {
    try {
      final response = await _apiService.get('/practice_logs/today');

      if (response.statusCode == 200) {
        final data = response.data['practice_log'];
        return data != null ? PracticeLog.fromJson(data) : null;
      }
    } catch (e) {
      // エラーハンドリング
    }
    return null;
  }

  // 練習統計を取得
  Future<Map<String, dynamic>?> getPracticeStats({DateTime? startDate, DateTime? endDate}) async {
    try {
      final response = await _apiService.get('/practice_logs/stats', queryParameters: {
        if (startDate != null) 'start_date': startDate.toIso8601String(),
        if (endDate != null) 'end_date': endDate.toIso8601String(),
      });

      if (response.statusCode == 200) {
        return response.data['stats'];
      }
    } catch (e) {
      // エラーハンドリング
    }
    return null;
  }

  // ベストタイムを取得
  Future<List<PracticeTime>> getBestTimes() async {
    try {
      final response = await _apiService.get('/practice_logs/best_times');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['best_times'];
        return data.map((json) => PracticeTime.fromJson(json)).toList();
      }
    } catch (e) {
      // エラーハンドリング
    }
    return [];
  }
}
