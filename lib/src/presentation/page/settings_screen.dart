import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../controller/font_size_provider.dart';
import '../controller/theme_mode_provider.dart';
import '../../data/constants/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  PackageInfo? packageInfo;

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      packageInfo = info;
    });
  }

  void _showAppDataDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('앱 데이터 삭제'),
        content: const Text(
          '모든 앱 데이터가 삭제됩니다.\n이 작업은 되돌릴 수 없습니다.\n\n정말로 삭제하시겠습니까?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteAppData();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAppData() async {
    // 여기에 실제 앱 데이터 삭제 로직을 구현
    // 예: SharedPreferences 클리어, 캐시 삭제 등
    try {
      // TODO: 실제 데이터 삭제 로직 구현
      // await SharedPreferences.getInstance().then((prefs) => prefs.clear());
      // await DefaultCacheManager().emptyCache();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('앱 데이터가 삭제되었습니다.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('데이터 삭제 중 오류가 발생했습니다: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showLicensePage() {
    showLicensePage(
      context: context,
      applicationName: 'Easy News',
      applicationVersion: packageInfo?.version ?? '1.0.0',
      applicationIcon: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Icon(Icons.article, size: 48, color: AppColors.primary),
      ),
      applicationLegalese: '© 2024 Easy News. All rights reserved.',
    );
  }

  static const String _rssUrl =
      'https://news.sbs.co.kr/news/TopicRssFeed.do?plink=RSSREADER';
  static const String _developerEmail = 'idlepoe@gmail.com';
  static const String _developerAppsUrl =
      'https://play.google.com/store/search?q=pub%3Amongbat&c=apps';

  void _showRssDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('데이터 소스'),
        content: SelectableText(_rssUrl),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final uri = Uri.parse(_rssUrl);
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            },
            child: const Text('바로가기'),
          ),
        ],
      ),
    );
  }

  void _launchMail() async {
    final mailUri = Uri.parse('mailto:$_developerEmail');
    await launchUrl(mailUri);
  }

  void _openDeveloperApps() async {
    final uri = Uri.parse(_developerAppsUrl);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final fontSize = ref.watch(fontSizeProvider);
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final newsBodyDisplay = ref.watch(newsBodyDisplayProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '설정',
          style: TextStyle(
            color: Theme.of(context).textTheme.titleLarge?.color,
          ),
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(
          color: Theme.of(context).textTheme.titleLarge?.color,
        ),
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 뉴스 본문 표시 방식 섹션
          _buildSectionHeader('뉴스 본문 표시 방식'),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  RadioListTile<NewsBodyDisplayType>(
                    value: NewsBodyDisplayType.description,
                    groupValue: newsBodyDisplay,
                    onChanged: (v) {
                      if (v != null)
                        ref.read(newsBodyDisplayProvider.notifier).setType(v);
                    },
                    title: const Text('원본'),
                  ),
                  RadioListTile<NewsBodyDisplayType>(
                    value: NewsBodyDisplayType.summary,
                    groupValue: newsBodyDisplay,
                    onChanged: (v) {
                      if (v != null)
                        ref.read(newsBodyDisplayProvider.notifier).setType(v);
                    },
                    title: const Text('일반요약'),
                  ),
                  RadioListTile<NewsBodyDisplayType>(
                    value: NewsBodyDisplayType.summary3lines,
                    groupValue: newsBodyDisplay,
                    onChanged: (v) {
                      if (v != null)
                        ref.read(newsBodyDisplayProvider.notifier).setType(v);
                    },
                    title: const Text('3줄요약'),
                  ),
                  RadioListTile<NewsBodyDisplayType>(
                    value: NewsBodyDisplayType.easySummary,
                    groupValue: newsBodyDisplay,
                    onChanged: (v) {
                      if (v != null)
                        ref.read(newsBodyDisplayProvider.notifier).setType(v);
                    },
                    title: const Text('쉬운요약'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 테마 설정 섹션
          _buildSectionHeader('테마 설정'),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  RadioListTile<ThemeMode>(
                    value: ThemeMode.system,
                    groupValue: themeMode,
                    onChanged: (mode) {
                      if (mode != null)
                        ref.read(themeModeProvider.notifier).setThemeMode(mode);
                    },
                    title: const Text('시스템 설정에 따름'),
                  ),
                  RadioListTile<ThemeMode>(
                    value: ThemeMode.light,
                    groupValue: themeMode,
                    onChanged: (mode) {
                      if (mode != null)
                        ref.read(themeModeProvider.notifier).setThemeMode(mode);
                    },
                    title: const Text('라이트 모드'),
                  ),
                  RadioListTile<ThemeMode>(
                    value: ThemeMode.dark,
                    groupValue: themeMode,
                    onChanged: (mode) {
                      if (mode != null)
                        ref.read(themeModeProvider.notifier).setThemeMode(mode);
                    },
                    title: const Text('다크 모드'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 폰트 크기 설정 섹션
          _buildSectionHeader('폰트 크기'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '현재 크기: ${fontSize.toInt()}pt',
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    children: fontSizeOptions
                        .map(
                          (size) => ElevatedButton(
                            onPressed: () => ref
                                .read(fontSizeProvider.notifier)
                                .setFontSize(size),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: fontSize == size
                                  ? AppColors.primary
                                  : Theme.of(context).cardColor,
                              foregroundColor: fontSize == size
                                  ? Colors.white
                                  : Theme.of(
                                      context,
                                    ).textTheme.bodyLarge?.color,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              elevation: fontSize == size ? 2 : 0,
                            ),
                            child: Text(
                              '${size.toInt()}',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 앱 정보 섹션
          _buildSectionHeader('앱 정보'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.article, color: AppColors.primary),
                  title: Text(
                    'Easy News',
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    '버전 ${packageInfo?.version ?? '1.0.0'}',
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                ),
                Divider(color: Theme.of(context).dividerColor, height: 1),
                ListTile(
                  leading: Icon(Icons.source, color: AppColors.primary),
                  title: Text(
                    '데이터 소스',
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  subtitle: GestureDetector(
                    onTap: _showRssDialog,
                    child: Text(
                      'SBS 뉴스 RSS',
                      style: TextStyle(
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                Divider(color: Theme.of(context).dividerColor, height: 1),
                ListTile(
                  leading: Icon(Icons.info_outline, color: AppColors.primary),
                  title: Text(
                    '앱 정보',
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  subtitle: Text(
                    'AI 기반 뉴스 요약 및 엔티티 분석',
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 기타 설정 섹션
          _buildSectionHeader('기타'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.gavel, color: AppColors.primary),
                  title: Text(
                    '라이선스',
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  subtitle: Text(
                    '오픈소스 라이선스 정보',
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                  trailing: Icon(
                    Icons.chevron_right,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                  onTap: _showLicensePage,
                ),
                Divider(color: Theme.of(context).dividerColor, height: 1),
                ListTile(
                  leading: Icon(Icons.email_outlined, color: AppColors.primary),
                  title: Text(
                    '문의하기',
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  subtitle: Text(
                    _developerEmail,
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                  onTap: _launchMail,
                ),
                Divider(color: Theme.of(context).dividerColor, height: 1),
                ListTile(
                  leading: Icon(Icons.apps, color: AppColors.primary),
                  title: Text(
                    '개발자의 다른 앱 보기',
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  subtitle: Text(
                    'Google Play에서 mongbat 개발자 앱 보기',
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                  onTap: _openDeveloperApps,
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),

          // 앱 데이터 삭제 버튼 (최하단)
          _buildSectionHeader('데이터 관리'),
          Card(
            child: ListTile(
              leading: Icon(Icons.delete_forever, color: AppColors.error),
              title: Text(
                '앱 데이터 삭제',
                style: TextStyle(
                  color: AppColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                '모든 앱 데이터를 삭제합니다',
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
              onTap: _showAppDataDeleteDialog,
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
      ),
    );
  }
}
