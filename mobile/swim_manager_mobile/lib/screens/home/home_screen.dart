import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/announcement_provider.dart';
import '../../providers/practice_provider.dart';
import '../../models/race.dart';
import '../../models/attendance.dart';
import '../../models/objective.dart';
import '../../constants/strings.dart';
import '../../widgets/custom_button.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = 0;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 権限変更時にインデックスを調整
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    final isAdmin = user?.isAdmin == true;
    final maxIndex = isAdmin ? 6 : 5; // 管理者: 7タブ、一般: 6タブ
    
    if (_currentIndex > maxIndex) {
      _currentIndex = maxIndex;
    }
  }



  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AnnouncementProvider()),
        ChangeNotifierProvider(create: (_) => PracticeProvider()),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          final user = authProvider.user;
          final isAdmin = user?.isAdmin == true;
          
          // 管理者権限に基づいてスクリーンとナビゲーションアイテムを生成
          final List<Widget> screens = [
            const _DashboardTab(),
            const _MembersTab(),
            const _PracticeTab(),
            const _RacesTab(),
            const _AttendanceTab(),
            const _ObjectivesTab(),
            if (isAdmin) const _AdminTab(),
          ];
          
          final List<BottomNavigationBarItem> navigationItems = [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: AppStrings.home,
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.people),
              label: AppStrings.members,
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.fitness_center),
              label: AppStrings.practice,
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.emoji_events),
              label: AppStrings.races,
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.check_circle),
              label: AppStrings.attendance,
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.flag),
              label: AppStrings.objectives,
            ),
            if (isAdmin)
              const BottomNavigationBarItem(
                icon: Icon(Icons.admin_panel_settings),
                label: AppStrings.admin,
              ),
          ];
          
          // 現在のインデックスが範囲内かチェックし、必要に応じて調整
          if (_currentIndex >= screens.length) {
            _currentIndex = screens.length - 1;
          }
          
          return Scaffold(
            appBar: AppBar(
              title: Text(AppStrings.appName),
              actions: [
                IconButton(
                  icon: const Icon(Icons.person),
                  onPressed: () {
                    // マイページに遷移
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () => _showLogoutDialog(context),
                ),
              ],
            ),
            body: IndexedStack(
              index: _currentIndex,
              children: screens,
            ),
            bottomNavigationBar: BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              currentIndex: _currentIndex,
              onTap: (index) {
                setState(() {
                  _currentIndex = index.clamp(0, screens.length - 1);
                });
              },
              items: navigationItems,
            ),
          );
        },
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ログアウト'),
        content: const Text('ログアウトしますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          CustomButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              await authProvider.logout();
            },
            child: const Text('ログアウト'),
          ),
        ],
      ),
    );
  }
}

// ダッシュボードタブ
class _DashboardTab extends StatefulWidget {
  const _DashboardTab();

  @override
  State<_DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<_DashboardTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final announcementProvider = Provider.of<AnnouncementProvider>(context, listen: false);
      final practiceProvider = Provider.of<PracticeProvider>(context, listen: false);
      
      announcementProvider.loadRecentAnnouncements();
      practiceProvider.loadTodayPracticeLog();
      practiceProvider.loadBestTimes();
    });
  }

  /// ユーザー名から安全にイニシャルを抽出する
  String _getInitial(String? name) {
    if (name == null || name.isEmpty) {
      return 'U';
    }
    
    final runes = name.runes;
    if (runes.isEmpty) {
      return 'U';
    }
    
    return String.fromCharCode(runes.first);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, AnnouncementProvider>(
      builder: (context, authProvider, announcementProvider, child) {
        final user = authProvider.user;
        
        return RefreshIndicator(
          onRefresh: () async {
            await announcementProvider.refresh();
            if (context.mounted) {
              final practiceProvider = Provider.of<PracticeProvider>(context, listen: false);
              await practiceProvider.refresh();
            }
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ユーザー情報カード
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.blue.shade100,
                          child: Text(
                            _getInitial(user?.name),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?.name ?? 'Unknown',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              Text(
                                user?.userTypeString ?? 'Unknown',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // お知らせセクション
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'お知らせ',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    TextButton(
                      onPressed: () {
                        // お知らせ一覧画面に遷移
                      },
                      child: const Text('すべて見る'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (announcementProvider.isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (announcementProvider.recentAnnouncements.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'お知らせはありません',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  )
                else
                  ...announcementProvider.recentAnnouncements.take(3).map((announcement) => 
                    Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Icon(
                          Icons.announcement,
                          color: announcement.isImportant ? Colors.red : Colors.orange,
                        ),
                        title: Text(
                          announcement.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(announcement.formattedDate),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          // お知らせ詳細画面に遷移
                        },
                      ),
                    ),
                  ),
                const SizedBox(height: 24),

                // 今日の練習記録
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '今日の練習',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    TextButton(
                      onPressed: () {
                        // 練習記録画面に遷移
                      },
                      child: const Text('記録する'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Consumer<PracticeProvider>(
                  builder: (context, practiceProvider, child) {
                    if (practiceProvider.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    
                    final todayLog = practiceProvider.todayPracticeLog;
                    if (todayLog == null) {
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            '今日の練習記録はありません',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                      );
                    }

                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.fitness_center, color: Colors.green),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    todayLog.title ?? '練習',
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text('総距離: ${todayLog.totalDistance.toInt()}m'),
                            Text('総時間: ${todayLog.totalTime.inMinutes}分'),
                            if (todayLog.notes != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                todayLog.notes!,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),

                // ベストタイム
                Text(
                  'ベストタイム',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Consumer<PracticeProvider>(
                  builder: (context, practiceProvider, child) {
                    if (practiceProvider.bestTimes.isEmpty) {
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'ベストタイムはありません',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                      );
                    }

                    return Column(
                      children: practiceProvider.bestTimes.take(3).map((time) => 
                        Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: const Icon(Icons.timer, color: Colors.blue),
                            title: Text('${time.formattedDistance} ${time.style ?? ''}'),
                            subtitle: Text(time.formattedPace),
                            trailing: Text(
                              time.formattedDuration,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                        ),
                      ).toList(),
                    );
                  },
                ),
                const SizedBox(height: 24),

                // クイックアクション
                Text(
                  'クイックアクション',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Card(
                        child: InkWell(
                          onTap: () {
                            // 出席入力画面に遷移
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                const Icon(Icons.check_circle, size: 32, color: Colors.green),
                                const SizedBox(height: 8),
                                Text(
                                  '出席入力',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Card(
                        child: InkWell(
                          onTap: () {
                            // 練習記録画面に遷移
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                const Icon(Icons.fitness_center, size: 32, color: Colors.blue),
                                const SizedBox(height: 8),
                                Text(
                                  '練習記録',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// 他のタブのプレースホルダー
class _MembersTab extends StatelessWidget {
  const _MembersTab();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('メンバー一覧画面（実装予定）'),
    );
  }
}

class _PracticeTab extends StatefulWidget {
  const _PracticeTab();

  @override
  State<_PracticeTab> createState() => _PracticeTabState();
}

class _PracticeTabState extends State<_PracticeTab> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final practiceProvider = Provider.of<PracticeProvider>(context, listen: false);
      practiceProvider.loadPracticeLogs();
      _scrollController.addListener(() {
        final p = Provider.of<PracticeProvider>(context, listen: false);
        if (_scrollController.position.pixels >=
                _scrollController.position.maxScrollExtent - 200 &&
            p.hasMore &&
            !p.isLoading) {
          p.loadPracticeLogs();
        }
      });
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PracticeProvider>(
      builder: (context, practiceProvider, child) {
        return Scaffold(
          body: RefreshIndicator(
            onRefresh: () => practiceProvider.refresh(),
            child: ListView.builder(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: practiceProvider.practiceLogs.length + 1,
              itemBuilder: (context, index) {
                if (practiceProvider.isLoading && practiceProvider.practiceLogs.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (practiceProvider.practiceLogs.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 80),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.fitness_center, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('練習記録がありません', style: TextStyle(fontSize: 18, color: Colors.grey)),
                          SizedBox(height: 8),
                          Text('練習を記録して記録を残しましょう', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                  );
                }
                if (index == practiceProvider.practiceLogs.length) {
                  if (practiceProvider.hasMore) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                }

                final practiceLog = practiceProvider.practiceLogs[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: const Icon(Icons.fitness_center, color: Colors.blue),
                    title: Text(practiceLog.title ?? '練習'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(practiceLog.formattedDate),
                        Text('距離: ${practiceLog.totalDistance.toInt()}m'),
                        Text('時間: ${practiceLog.totalTime.inMinutes}分'),
                      ],
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // 練習記録詳細画面に遷移
                    },
                  ),
                );
              },
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              // 練習記録作成画面に遷移
            },
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}

class _RacesTab extends StatefulWidget {
  const _RacesTab();

  @override
  State<_RacesTab> createState() => _RacesTabState();
}

class _RacesTabState extends State<_RacesTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('レース管理'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '今後のレース'),
            Tab(text: '過去のレース'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _UpcomingRacesTab(),
          _PastRacesTab(),
        ],
      ),
    );
  }
}

class _UpcomingRacesTab extends StatefulWidget {
  const _UpcomingRacesTab();

  @override
  State<_UpcomingRacesTab> createState() => _UpcomingRacesTabState();
}

class _UpcomingRacesTabState extends State<_UpcomingRacesTab> {
  List<Race> _races = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadRaces();
  }

  Future<void> _loadRaces() async {
    setState(() => _isLoading = true);
    // TODO: 実際のAPI呼び出し
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _isLoading = false;
      // ダミーデータ
      _races = [
        Race(
          id: 1,
          name: '春季大会',
          raceDate: DateTime.now().add(const Duration(days: 30)),
          venue: '県立プール',
          description: '春季水泳大会',
          events: [],
          createdAt: DateTime.now(),
        ),
        Race(
          id: 2,
          name: '夏季大会',
          raceDate: DateTime.now().add(const Duration(days: 90)),
          venue: '市立プール',
          description: '夏季水泳大会',
          events: [],
          createdAt: DateTime.now(),
        ),
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadRaces,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_races.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 80),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.emoji_events, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      '今後のレースはありません',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            )
          else
            ..._races.map((race) => Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: const Icon(Icons.emoji_events, color: Colors.orange),
                title: Text(race.name),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(race.formattedDate),
                    Text(race.venue),
                    if (race.description != null) Text(race.description!),
                  ],
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // レース詳細画面に遷移
                },
              ),
            )),
        ],
      ),
    );
  }
}

class _PastRacesTab extends StatefulWidget {
  const _PastRacesTab();

  @override
  State<_PastRacesTab> createState() => _PastRacesTabState();
}

class _PastRacesTabState extends State<_PastRacesTab> {
  List<Race> _races = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadRaces();
  }

  Future<void> _loadRaces() async {
    setState(() => _isLoading = true);
    // TODO: 実際のAPI呼び出し
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _isLoading = false;
      // ダミーデータ
      _races = [
        Race(
          id: 3,
          name: '冬季大会',
          raceDate: DateTime.now().subtract(const Duration(days: 30)),
          venue: '県立プール',
          description: '冬季水泳大会',
          events: [],
          createdAt: DateTime.now(),
        ),
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadRaces,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_races.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 80),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.emoji_events, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      '過去のレースはありません',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            )
          else
            ..._races.map((race) => Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: const Icon(Icons.emoji_events, color: Colors.grey),
                title: Text(race.name),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(race.formattedDate),
                    Text(race.venue),
                    if (race.description != null) Text(race.description!),
                  ],
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // レース詳細画面に遷移
                },
              ),
            )),
        ],
      ),
    );
  }
}

class _AttendanceTab extends StatefulWidget {
  const _AttendanceTab();

  @override
  State<_AttendanceTab> createState() => _AttendanceTabState();
}

class _AttendanceTabState extends State<_AttendanceTab> {
  AttendanceEvent? _todayEvent;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadTodayEvent();
  }

  Future<void> _loadTodayEvent() async {
    setState(() => _isLoading = true);
    // TODO: 実際のAPI呼び出し
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _isLoading = false;
      // ダミーデータ
      _todayEvent = AttendanceEvent(
        id: 1,
        title: '今日の練習',
        date: DateTime.now(),
        description: '通常練習',
        attendances: [],
        createdAt: DateTime.now(),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadTodayEvent,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 今日の出席状況
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.check_circle, color: Colors.green),
                                const SizedBox(width: 8),
                                Text(
                                  '今日の出席状況',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            if (_todayEvent != null) ...[
                              Text('イベント: ${_todayEvent!.title}'),
                              const SizedBox(height: 8),
                              Text('日付: ${_todayEvent!.formattedDate}'),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: _AttendanceStatusCard(
                                      title: '出席',
                                      count: _todayEvent!.presentCount,
                                      color: Colors.green,
                                      icon: Icons.check_circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _AttendanceStatusCard(
                                      title: '欠席',
                                      count: _todayEvent!.absentCount,
                                      color: Colors.red,
                                      icon: Icons.cancel,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: _AttendanceStatusCard(
                                      title: 'その他',
                                      count: _todayEvent!.otherCount,
                                      color: Colors.orange,
                                      icon: Icons.info,
                                    ),
                                  ),
                                ],
                              ),
                            ] else ...[
                              const Text('今日の出席イベントはありません'),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 出席率
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.analytics, color: Colors.blue),
                                const SizedBox(width: 8),
                                Text(
                                  '今月の出席率',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    children: [
                                      Text(
                                        '85%',
                                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                          color: Colors.blue,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const Text('出席率'),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    children: [
                                      Text(
                                        '17/20',
                                        style: Theme.of(context).textTheme.titleLarge,
                                      ),
                                      const Text('出席回数'),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // クイックアクション
                    Text(
                      'クイックアクション',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Card(
                            child: InkWell(
                              onTap: () {
                                // 出席入力画面に遷移
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    const Icon(Icons.check_circle, size: 32, color: Colors.green),
                                    const SizedBox(height: 8),
                                    Text(
                                      '出席入力',
                                      style: Theme.of(context).textTheme.titleMedium,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Card(
                            child: InkWell(
                              onTap: () {
                                // 出席履歴画面に遷移
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    const Icon(Icons.history, size: 32, color: Colors.blue),
                                    const SizedBox(height: 8),
                                    Text(
                                      '出席履歴',
                                      style: Theme.of(context).textTheme.titleMedium,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _AttendanceStatusCard extends StatelessWidget {
  final String title;
  final int count;
  final Color color;
  final IconData icon;

  const _AttendanceStatusCard({
    required this.title,
    required this.count,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            count.toString(),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _ObjectivesTab extends StatefulWidget {
  const _ObjectivesTab();

  @override
  State<_ObjectivesTab> createState() => _ObjectivesTabState();
}

class _ObjectivesTabState extends State<_ObjectivesTab> {
  List<Objective> _objectives = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadObjectives();
  }

  Future<void> _loadObjectives() async {
    setState(() => _isLoading = true);
    // TODO: 実際のAPI呼び出し
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _isLoading = false;
      // ダミーデータ
      _objectives = [
        Objective(
          id: 1,
          title: '100m自由形の記録向上',
          description: '100m自由形の記録を1分以内に短縮する',
          targetDate: DateTime.now().add(const Duration(days: 90)),
          status: 'active',
          progress: 0.6,
          milestones: [
            Milestone(
              id: 1,
              title: '基礎体力の向上',
              description: '週3回の練習を継続する',
              targetDate: DateTime.now().add(const Duration(days: 30)),
              isCompleted: true,
              createdAt: DateTime.now(),
            ),
            Milestone(
              id: 2,
              title: '技術の改善',
              description: 'フォームを改善する',
              targetDate: DateTime.now().add(const Duration(days: 60)),
              isCompleted: false,
              createdAt: DateTime.now(),
            ),
          ],
          createdAt: DateTime.now(),
        ),
        Objective(
          id: 2,
          title: '大会での入賞',
          description: '春季大会で3位以内に入賞する',
          targetDate: DateTime.now().add(const Duration(days: 45)),
          status: 'active',
          progress: 0.3,
          milestones: [],
          createdAt: DateTime.now(),
        ),
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadObjectives,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _objectives.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.flag, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          '目標がありません',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '新しい目標を設定しましょう',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _objectives.length,
                    itemBuilder: (context, index) {
                      final objective = _objectives[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.flag,
                                    color: objective.statusColor,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      objective.title,
                                      style: Theme.of(context).textTheme.titleMedium,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: objective.statusColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      objective.statusText,
                                      style: TextStyle(
                                        color: objective.statusColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                objective.description,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '期限: ${objective.formattedTargetDate}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: objective.isOverdue ? Colors.red : Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: LinearProgressIndicator(
                                      value: objective.progress,
                                      backgroundColor: Colors.grey.shade200,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        objective.statusColor,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${objective.progressPercentage}%',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                              if (objective.milestones.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Text(
                                  'マイルストーン',
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                                const SizedBox(height: 8),
                                ...objective.milestones.map((milestone) => 
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Row(
                                      children: [
                                        Icon(
                                          milestone.isCompleted 
                                              ? Icons.check_circle 
                                              : Icons.radio_button_unchecked,
                                          size: 16,
                                          color: milestone.isCompleted 
                                              ? Colors.green 
                                              : Colors.grey,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            milestone.title,
                                            style: TextStyle(
                                              decoration: milestone.isCompleted 
                                                  ? TextDecoration.lineThrough 
                                                  : null,
                                              color: milestone.isCompleted 
                                                  ? Colors.grey 
                                                  : null,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // 目標作成画面に遷移
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _AdminTab extends StatelessWidget {
  const _AdminTab();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('管理者画面（実装予定）'),
    );
  }
}
