import '../models/objective.dart';
import 'api_service.dart';

class ObjectiveService {
  static final ObjectiveService _instance = ObjectiveService._internal();
  factory ObjectiveService() => _instance;
  ObjectiveService._internal();

  final ApiService _apiService = ApiService();

  // 目標一覧を取得
  Future<List<Objective>> getObjectives({int? page, int? perPage}) async {
    try {
      final response = await _apiService.get('/objectives', queryParameters: {
        if (page != null) 'page': page,
        if (perPage != null) 'per_page': perPage,
      });

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['objectives'];
        return data.map((json) => Objective.fromJson(json)).toList();
      }
    } catch (e) {
      // エラーハンドリング
    }
    return [];
  }

  // 目標詳細を取得
  Future<Objective?> getObjective(int id) async {
    try {
      final response = await _apiService.get('/objectives/$id');

      if (response.statusCode == 200) {
        return Objective.fromJson(response.data['objective']);
      }
    } catch (e) {
      // エラーハンドリング
    }
    return null;
  }

  // 目標を作成
  Future<Objective?> createObjective(Map<String, dynamic> data) async {
    try {
      final response = await _apiService.post('/objectives', data: data);

      if (response.statusCode == 201) {
        return Objective.fromJson(response.data['objective']);
      }
    } catch (e) {
      // エラーハンドリング
    }
    return null;
  }

  // 目標を更新
  Future<Objective?> updateObjective(int id, Map<String, dynamic> data) async {
    try {
      final response = await _apiService.put('/objectives/$id', data: data);

      if (response.statusCode == 200) {
        return Objective.fromJson(response.data['objective']);
      }
    } catch (e) {
      // エラーハンドリング
    }
    return null;
  }

  // 目標を削除
  Future<bool> deleteObjective(int id) async {
    try {
      final response = await _apiService.delete('/objectives/$id');
      return response.statusCode == 204;
    } catch (e) {
      // エラーハンドリング
    }
    return false;
  }

  // アクティブな目標を取得
  Future<List<Objective>> getActiveObjectives() async {
    try {
      final response = await _apiService.get('/objectives/active');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['objectives'];
        return data.map((json) => Objective.fromJson(json)).toList();
      }
    } catch (e) {
      // エラーハンドリング
    }
    return [];
  }

  // 完了した目標を取得
  Future<List<Objective>> getCompletedObjectives() async {
    try {
      final response = await _apiService.get('/objectives/completed');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['objectives'];
        return data.map((json) => Objective.fromJson(json)).toList();
      }
    } catch (e) {
      // エラーハンドリング
    }
    return [];
  }

  // マイルストーンを更新
  Future<bool> updateMilestone(int objectiveId, int milestoneId, bool isCompleted) async {
    try {
      final response = await _apiService.put('/objectives/$objectiveId/milestones/$milestoneId', data: {
        'is_completed': isCompleted,
      });

      return response.statusCode == 200;
    } catch (e) {
      // エラーハンドリング
    }
    return false;
  }

  // 目標の進捗を更新
  Future<bool> updateProgress(int objectiveId, double progress) async {
    try {
      final response = await _apiService.put('/objectives/$objectiveId/progress', data: {
        'progress': progress,
      });

      return response.statusCode == 200;
    } catch (e) {
      // エラーハンドリング
    }
    return false;
  }

  // 目標統計を取得
  Future<Map<String, dynamic>?> getObjectiveStats() async {
    try {
      final response = await _apiService.get('/objectives/stats');

      if (response.statusCode == 200) {
        return response.data['stats'];
      }
    } catch (e) {
      // エラーハンドリング
    }
    return null;
  }
}
