import '../models/attendance.dart';
import 'api_service.dart';

class AttendanceService {
  static final AttendanceService _instance = AttendanceService._internal();
  factory AttendanceService() => _instance;
  AttendanceService._internal();

  final ApiService _apiService = ApiService();

  // 出席イベント一覧を取得
  Future<List<AttendanceEvent>> getAttendanceEvents({int? page, int? perPage}) async {
    try {
      final response = await _apiService.get('/attendance_events', queryParameters: {
        if (page != null) 'page': page,
        if (perPage != null) 'per_page': perPage,
      });

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['attendance_events'];
        return data.map((json) => AttendanceEvent.fromJson(json)).toList();
      }
    } catch (e) {
      // エラーハンドリング
    }
    return [];
  }

  // 出席イベント詳細を取得
  Future<AttendanceEvent?> getAttendanceEvent(int id) async {
    try {
      final response = await _apiService.get('/attendance_events/$id');

      if (response.statusCode == 200) {
        return AttendanceEvent.fromJson(response.data['attendance_event']);
      }
    } catch (e) {
      // エラーハンドリング
    }
    return null;
  }

  // 今日の出席イベントを取得
  Future<AttendanceEvent?> getTodayAttendanceEvent() async {
    try {
      final response = await _apiService.get('/attendance_events/today');

      if (response.statusCode == 200) {
        final data = response.data['attendance_event'];
        return data != null ? AttendanceEvent.fromJson(data) : null;
      }
    } catch (e) {
      // エラーハンドリング
    }
    return null;
  }

  // 出席状況を更新
  Future<bool> updateAttendance(int eventId, String status, {String? reason}) async {
    try {
      final response = await _apiService.put('/attendance_events/$eventId/attendance', data: {
        'status': status,
        if (reason != null) 'reason': reason,
      });

      return response.statusCode == 200;
    } catch (e) {
      // エラーハンドリング
    }
    return false;
  }

  // ユーザーの出席履歴を取得
  Future<List<Attendance>> getUserAttendanceHistory({DateTime? startDate, DateTime? endDate}) async {
    try {
      final response = await _apiService.get('/attendance/history', queryParameters: {
        if (startDate != null) 'start_date': startDate.toIso8601String(),
        if (endDate != null) 'end_date': endDate.toIso8601String(),
      });

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['attendances'];
        return data.map((json) => Attendance.fromJson(json)).toList();
      }
    } catch (e) {
      // エラーハンドリング
    }
    return [];
  }

  // 出席統計を取得
  Future<Map<String, dynamic>?> getAttendanceStats({DateTime? startDate, DateTime? endDate}) async {
    try {
      final response = await _apiService.get('/attendance/stats', queryParameters: {
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

  // 今月の出席率を取得
  Future<double> getMonthlyAttendanceRate() async {
    try {
      final response = await _apiService.get('/attendance/monthly_rate');

      if (response.statusCode == 200) {
        return (response.data['attendance_rate'] ?? 0.0).toDouble();
      }
    } catch (e) {
      // エラーハンドリング
    }
    return 0.0;
  }
}
