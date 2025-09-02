import 'package:flutter/foundation.dart';
import '../models/announcement.dart';
import '../services/announcement_service.dart';

class AnnouncementProvider with ChangeNotifier {
  final AnnouncementService _announcementService = AnnouncementService();
  
  List<Announcement> _announcements = [];
  List<Announcement> _importantAnnouncements = [];
  List<Announcement> _recentAnnouncements = [];
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  bool _hasMore = true;

  List<Announcement> get announcements => _announcements;
  List<Announcement> get importantAnnouncements => _importantAnnouncements;
  List<Announcement> get recentAnnouncements => _recentAnnouncements;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMore => _hasMore;

  // お知らせ一覧を取得
  Future<void> loadAnnouncements({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _announcements = [];
      _hasMore = true;
    }

    if (!_hasMore || _isLoading) return;

    _setLoading(true);
    _clearError();
    
    try {
      final announcements = await _announcementService.getAnnouncements(
        page: _currentPage,
        perPage: 20,
      );

      if (refresh) {
        _announcements = announcements;
      } else {
        _announcements.addAll(announcements);
      }

      _hasMore = announcements.length == 20;
      _currentPage++;
      notifyListeners();
    } catch (e) {
      _setError('お知らせの取得に失敗しました');
    } finally {
      _setLoading(false);
    }
  }

  // 重要なお知らせを取得
  Future<void> loadImportantAnnouncements() async {
    _setLoading(true);
    _clearError();
    
    try {
      _importantAnnouncements = await _announcementService.getImportantAnnouncements();
      notifyListeners();
    } catch (e) {
      _setError('重要なお知らせの取得に失敗しました');
    } finally {
      _setLoading(false);
    }
  }

  // 最新のお知らせを取得
  Future<void> loadRecentAnnouncements() async {
    _setLoading(true);
    _clearError();
    
    try {
      _recentAnnouncements = await _announcementService.getRecentAnnouncements();
      notifyListeners();
    } catch (e) {
      _setError('最新のお知らせの取得に失敗しました');
    } finally {
      _setLoading(false);
    }
  }

  // お知らせ詳細を取得
  Future<Announcement?> getAnnouncement(int id) async {
    try {
      return await _announcementService.getAnnouncement(id);
    } catch (e) {
      _setError('お知らせ詳細の取得に失敗しました');
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
    await loadAnnouncements(refresh: true);
    await loadImportantAnnouncements();
    await loadRecentAnnouncements();
  }
}
