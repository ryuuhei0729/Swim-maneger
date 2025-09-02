import '../models/race.dart';
import 'api_service.dart';

class RaceService {
  static final RaceService _instance = RaceService._internal();
  factory RaceService() => _instance;
  RaceService._internal();

  final ApiService _apiService = ApiService();

  // レース一覧を取得
  Future<List<Race>> getRaces({int? page, int? perPage}) async {
    try {
      final response = await _apiService.get('/races', queryParameters: {
        if (page != null) 'page': page,
        if (perPage != null) 'per_page': perPage,
      });

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['races'];
        return data.map((json) => Race.fromJson(json)).toList();
      }
    } catch (e) {
      // エラーハンドリング
    }
    return [];
  }

  // レース詳細を取得
  Future<Race?> getRace(int id) async {
    try {
      final response = await _apiService.get('/races/$id');

      if (response.statusCode == 200) {
        return Race.fromJson(response.data['race']);
      }
    } catch (e) {
      // エラーハンドリング
    }
    return null;
  }

  // 今後のレースを取得
  Future<List<Race>> getUpcomingRaces() async {
    try {
      final response = await _apiService.get('/races/upcoming');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['races'];
        return data.map((json) => Race.fromJson(json)).toList();
      }
    } catch (e) {
      // エラーハンドリング
    }
    return [];
  }

  // 過去のレースを取得
  Future<List<Race>> getPastRaces() async {
    try {
      final response = await _apiService.get('/races/past');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['races'];
        return data.map((json) => Race.fromJson(json)).toList();
      }
    } catch (e) {
      // エラーハンドリング
    }
    return [];
  }

  // エントリーを作成
  Future<bool> createEntry(int raceId, int eventId) async {
    try {
      final response = await _apiService.post('/races/$raceId/events/$eventId/entries');

      return response.statusCode == 201;
    } catch (e) {
      // エラーハンドリング
    }
    return false;
  }

  // エントリーを削除
  Future<bool> deleteEntry(int raceId, int eventId, int entryId) async {
    try {
      final response = await _apiService.delete('/races/$raceId/events/$eventId/entries/$entryId');

      return response.statusCode == 204;
    } catch (e) {
      // エラーハンドリング
    }
    return false;
  }

  // ユーザーのエントリー一覧を取得
  Future<List<Entry>> getUserEntries() async {
    try {
      final response = await _apiService.get('/races/entries');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['entries'];
        return data.map((json) => Entry.fromJson(json)).toList();
      }
    } catch (e) {
      // エラーハンドリング
    }
    return [];
  }

  // レース結果を取得
  Future<List<Entry>> getRaceResults(int raceId) async {
    try {
      final response = await _apiService.get('/races/$raceId/results');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['results'];
        return data.map((json) => Entry.fromJson(json)).toList();
      }
    } catch (e) {
      // エラーハンドリング
    }
    return [];
  }
}
