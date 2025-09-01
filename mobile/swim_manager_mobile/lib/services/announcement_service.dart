import '../models/announcement.dart';
import 'api_service.dart';

class AnnouncementService {
  static final AnnouncementService _instance = AnnouncementService._internal();
  factory AnnouncementService() => _instance;
  AnnouncementService._internal();

  final ApiService _apiService = ApiService();

  // お知らせ一覧を取得
  Future<List<Announcement>> getAnnouncements({int? page, int? perPage}) async {
    try {
      final response = await _apiService.get('/announcements', queryParameters: {
        if (page != null) 'page': page,
        if (perPage != null) 'per_page': perPage,
      });

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['announcements'];
        return data.map((json) => Announcement.fromJson(json)).toList();
      }
    } catch (e) {
      // エラーハンドリング
    }
    return [];
  }

  // お知らせ詳細を取得
  Future<Announcement?> getAnnouncement(int id) async {
    try {
      final response = await _apiService.get('/announcements/$id');

      if (response.statusCode == 200) {
        return Announcement.fromJson(response.data['announcement']);
      }
    } catch (e) {
      // エラーハンドリング
    }
    return null;
  }

  // 重要なお知らせを取得
  Future<List<Announcement>> getImportantAnnouncements() async {
    try {
      final response = await _apiService.get('/announcements/important');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['announcements'];
        return data.map((json) => Announcement.fromJson(json)).toList();
      }
    } catch (e) {
      // エラーハンドリング
    }
    return [];
  }

  // 最新のお知らせを取得
  Future<List<Announcement>> getRecentAnnouncements({int limit = 5}) async {
    try {
      final response = await _apiService.get('/announcements/recent', queryParameters: {
        'limit': limit,
      });

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['announcements'];
        return data.map((json) => Announcement.fromJson(json)).toList();
      }
    } catch (e) {
      // エラーハンドリング
    }
    return [];
  }
}
