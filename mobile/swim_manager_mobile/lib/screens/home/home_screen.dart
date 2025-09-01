import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../constants/strings.dart';
import '../../widgets/custom_button.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const _DashboardTab(),
    const _MembersTab(),
    const _PracticeTab(),
    const _RacesTab(),
    const _AttendanceTab(),
    const _ObjectivesTab(),
    const _AdminTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.user;
        
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
          body: _screens[_currentIndex],
          bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            items: [
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
              if (user?.isAdmin == true)
                const BottomNavigationBarItem(
                  icon: Icon(Icons.admin_panel_settings),
                  label: AppStrings.admin,
                ),
            ],
          ),
        );
      },
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
class _DashboardTab extends StatelessWidget {
  const _DashboardTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.user;
        
        return SingleChildScrollView(
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
                          user?.name.substring(0, 1) ?? 'U',
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
              Text(
                'お知らせ',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.announcement, color: Colors.orange),
                  title: const Text('システムメンテナンスのお知らせ'),
                  subtitle: const Text('2024年1月15日 22:00-24:00'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // お知らせ詳細画面に遷移
                  },
                ),
              ),
              const SizedBox(height: 24),

              // 今日の予定
              Text(
                '今日の予定',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.fitness_center, color: Colors.green),
                  title: const Text('練習'),
                  subtitle: const Text('18:00-20:00 プール'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // 練習詳細画面に遷移
                  },
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

class _PracticeTab extends StatelessWidget {
  const _PracticeTab();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('練習記録画面（実装予定）'),
    );
  }
}

class _RacesTab extends StatelessWidget {
  const _RacesTab();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('レース管理画面（実装予定）'),
    );
  }
}

class _AttendanceTab extends StatelessWidget {
  const _AttendanceTab();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('出席管理画面（実装予定）'),
    );
  }
}

class _ObjectivesTab extends StatelessWidget {
  const _ObjectivesTab();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('目標管理画面（実装予定）'),
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
