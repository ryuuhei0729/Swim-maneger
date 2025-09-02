import 'package:flutter/foundation.dart';
import '../models/practice_log.dart';
import '../services/practice_service.dart';

class PracticeProvider with ChangeNotifier {
  final PracticeService _practiceService = PracticeService();
  
  List<PracticeLog> _practiceLogs = [];
  PracticeLog? _todayPracticeLog;
  List<PracticeTime> _bestTimes = [];
  Map<String, dynamic>? _stats;
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  bool _hasMore = true;

  List<PracticeLog> get practiceLogs => _practiceLogs;
  PracticeLog? get todayPracticeLog => _todayPracticeLog;
  List<PracticeTime> get bestTimes => _bestTimes;
  Map<String, dynamic>? get stats => _stats;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMore => _hasMore;

  // 練習記録一覧を取得
  Future<void> loadPracticeLogs({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _practiceLogs = [];
      _hasMore = true;
    }

    if (!_hasMore || _isLoading) return;

    _setLoading(true);
    _clearError();
    
    try {
      final practiceLogs = await _practiceService.getPracticeLogs(
        page: _currentPage,
        perPage: 20,
      );

      // サービスが空の配列を返した場合、エラーとして扱う
      if (practiceLogs.isEmpty && _currentPage == 1) {
        throw Exception('練習記録が見つかりません');
      }

      if (refresh) {
        _practiceLogs = practiceLogs;
      } else {
        _practiceLogs.addAll(practiceLogs);
      }

      _hasMore = practiceLogs.length == 20;
      _currentPage++;
      notifyListeners();
    } catch (e) {
      _setError('練習記録の取得に失敗しました: ${e.toString()}');
      rethrow; // エラーを再スローして、呼び出し元でも処理できるようにする
    } finally {
      _setLoading(false);
    }
  }

  // 今日の練習記録を取得
  Future<void> loadTodayPracticeLog() async {
    _setLoading(true);
    _clearError();
    
    try {
      final todayLog = await _practiceService.getTodayPracticeLog();
      
      // サービスがnullを返した場合、エラーとして扱う
      if (todayLog == null) {
        throw Exception('今日の練習記録の取得に失敗しました: サービスがnullを返しました');
      }
      
      _todayPracticeLog = todayLog;
      notifyListeners();
    } catch (e) {
      _setError('今日の練習記録の取得に失敗しました: ${e.toString()}');
      rethrow; // エラーを再スローして、呼び出し元でも処理できるようにする
    } finally {
      _setLoading(false);
    }
  }

  // ベストタイムを取得
  Future<void> loadBestTimes() async {
    _setLoading(true);
    _clearError();
    
    try {
      final bestTimes = await _practiceService.getBestTimes();
      
      // サービスが空の配列を返した場合、エラーとして扱う
      if (bestTimes.isEmpty) {
        throw Exception('ベストタイムが見つかりません');
      }
      
      _bestTimes = bestTimes;
      notifyListeners();
    } catch (e) {
      _setError('ベストタイムの取得に失敗しました: ${e.toString()}');
      rethrow; // エラーを再スローして、呼び出し元でも処理できるようにする
    } finally {
      _setLoading(false);
    }
  }

  // 練習統計を取得
  Future<void> loadStats({DateTime? startDate, DateTime? endDate}) async {
    _setLoading(true);
    _clearError();
    
    try {
      final stats = await _practiceService.getPracticeStats(
        startDate: startDate,
        endDate: endDate,
      );
      
      // サービスがnullを返した場合、エラーとして扱う
      if (stats == null) {
        throw Exception('練習統計の取得に失敗しました: サービスがnullを返しました');
      }
      
      _stats = stats;
      notifyListeners();
    } catch (e) {
      _setError('練習統計の取得に失敗しました: ${e.toString()}');
      rethrow; // エラーを再スローして、呼び出し元でも処理できるようにする
    } finally {
      _setLoading(false);
    }
  }

  // 練習記録を作成
  Future<bool> createPracticeLog(Map<String, dynamic> data) async {
    _setLoading(true);
    _clearError();
    
    try {
      final practiceLog = await _practiceService.createPracticeLog(data);
      
      // サービスがnullを返した場合、エラーとして扱う
      if (practiceLog == null) {
        throw Exception('練習記録の作成に失敗しました: サービスがnullを返しました');
      }
      
      _practiceLogs.insert(0, practiceLog);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('練習記録の作成に失敗しました: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // 練習記録を更新
  Future<bool> updatePracticeLog(int id, Map<String, dynamic> data) async {
    _setLoading(true);
    _clearError();
    
    try {
      final practiceLog = await _practiceService.updatePracticeLog(id, data);
      
      // サービスがnullを返した場合、エラーとして扱う
      if (practiceLog == null) {
        throw Exception('練習記録の更新に失敗しました: サービスがnullを返しました');
      }
      
      final index = _practiceLogs.indexWhere((log) => log.id == id);
      if (index != -1) {
        _practiceLogs[index] = practiceLog;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _setError('練習記録の更新に失敗しました: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // 練習記録を削除
  Future<bool> deletePracticeLog(int id) async {
    _setLoading(true);
    _clearError();
    
    try {
      final success = await _practiceService.deletePracticeLog(id);
      
      // サービスがfalseを返した場合、エラーとして扱う
      if (success == false) {
        throw Exception('練習記録の削除に失敗しました: サービスがfalseを返しました');
      }
      
      if (success) {
        _practiceLogs.removeWhere((log) => log.id == id);
        notifyListeners();
      }
      return success;
    } catch (e) {
      _setError('練習記録の削除に失敗しました: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // 練習記録詳細を取得
  Future<PracticeLog?> getPracticeLog(int id) async {
    try {
      final practiceLog = await _practiceService.getPracticeLog(id);
      
      // サービスがnullを返した場合、エラーとして扱う
      if (practiceLog == null) {
        throw Exception('練習記録詳細の取得に失敗しました: サービスがnullを返しました');
      }
      
      return practiceLog;
    } catch (e) {
      _setError('練習記録詳細の取得に失敗しました: ${e.toString()}');
      return null;
    }
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

  // データをリフレッシュ
  Future<void> refresh() async {
    await loadPracticeLogs(refresh: true);
    await loadTodayPracticeLog();
    await loadBestTimes();
    await loadStats();
  }
}
