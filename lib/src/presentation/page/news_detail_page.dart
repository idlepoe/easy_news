import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:go_router/go_router.dart';
import '../controller/news_controller.dart';
import '../../domain/entity/news.dart';
import '../../domain/entity/news_entity.dart';
import '../../data/constants/app_colors.dart';
import 'package:intl/intl.dart';
import '../widgets/font_size_menu.dart';
import '../widgets/rounded_circular_progress.dart';
import '../controller/font_size_provider.dart';
import '../widgets/refresh_status_card.dart';

class NewsDetailPage extends ConsumerStatefulWidget {
  final String newsId;
  final News? initialNews;

  const NewsDetailPage({super.key, required this.newsId, this.initialNews});

  @override
  ConsumerState<NewsDetailPage> createState() => _NewsDetailPageState();
}

class _NewsDetailPageState extends ConsumerState<NewsDetailPage> {
  NewsEntity? selectedEntity;
  bool _hasUpdatedViewCount = false;
  bool _isRefreshingDetail = false;
  bool _isLoadingDetail = false;

  // TTS 관련 변수
  FlutterTts? _flutterTts;
  bool _isSpeaking = false;

  // 스크롤 관련 변수
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _summaryKey = GlobalKey();

  News? _displayNews; // 즉시 표시용 뉴스

  @override
  void initState() {
    super.initState();
    _initTts();
    // 진입 시 목록에서 받은 데이터를 우선 표시
    _displayNews = widget.initialNews;
    // 상세정보 fetch
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshNewsDetail();
    });
  }

  @override
  void dispose() {
    // TTS 정리
    _flutterTts?.stop();
    _scrollController.dispose();

    // 화면을 나갈 때 조회수 업데이트
    if (!_hasUpdatedViewCount) {
      _hasUpdatedViewCount = true;
      // 조회수 업데이트 (백그라운드에서 실행)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(updateViewCountProvider(widget.newsId));
        }
      });
    }
    super.dispose();
  }

  // TTS 초기화
  Future<void> _initTts() async {
    _flutterTts = FlutterTts();

    await _flutterTts!.setLanguage("ko-KR");
    await _flutterTts!.setSpeechRate(0.5);
    await _flutterTts!.setVolume(1.0);
    await _flutterTts!.setPitch(1.0);

    _flutterTts!.setCompletionHandler(() {
      setState(() {
        _isSpeaking = false;
      });
    });

    _flutterTts!.setErrorHandler((msg) {
      setState(() {
        _isSpeaking = false;
      });
      print('TTS 에러: $msg');
    });
  }

  // 상세정보를 다시 호출하는 메서드
  Future<void> _refreshNewsDetail() async {
    setState(() {
      _isRefreshingDetail = true;
      _isLoadingDetail = true;
    });
    try {
      await ref.refresh(newsDetailProvider(widget.newsId));
    } catch (e) {}
    setState(() {
      _isRefreshingDetail = false;
      _isLoadingDetail = false;
    });
  }

  String _formatKoreanDateTime(DateTime dateTime) {
    return DateFormat('yyyy년 M월 d일 H시 mm분', 'ko_KR').format(dateTime);
  }

  /// 뒤로가기 버튼 생성
  Widget _buildBackButton() {
    return IconButton(
      icon: Icon(
        Icons.arrow_back,
        color: Theme.of(context).textTheme.titleLarge?.color,
      ),
      onPressed: () => _handleBackNavigation(),
    );
  }

  /// 뒤로가기 네비게이션 처리
  void _handleBackNavigation() {
    // 현재 라우터 상태 확인
    final router = GoRouter.of(context);

    // 디버그 로그
    print('현재 라우터: $router');

    // 이전 화면이 있는지 확인
    if (router.canPop()) {
      // 이전 화면이 있으면 뒤로가기
      print('이전 화면으로 뒤로가기');
      router.pop();
    } else {
      // 이전 화면이 없으면 홈으로 이동
      print('이전 화면이 없어서 홈으로 이동');
      router.go('/');
    }
  }

  Color _getEntityColor(String type) {
    switch (type) {
      case 'PERSON':
        return AppColors.entityPerson;
      case 'ORGANIZATION':
        return AppColors.entityOrganization;
      case 'LOCATION':
        return AppColors.entityLocation;
      case 'COMPANY':
        return AppColors.entityCompany;
      case 'COUNTRY':
        return AppColors.entityCountry;
      default:
        return AppColors.textSecondary;
    }
  }

  String _getEntityTypeName(String type) {
    switch (type) {
      case 'PERSON':
        return '인물';
      case 'ORGANIZATION':
        return '기관';
      case 'LOCATION':
        return '장소';
      case 'COMPANY':
        return '회사';
      case 'COUNTRY':
        return '국가';
      default:
        return type;
    }
  }

  // 요약 내용 공유 메서드
  void _shareSummary(String title, String content, String type) {
    final newsAsync = ref.watch(newsDetailProvider(widget.newsId));
    final news = newsAsync.value;
    if (news == null) return;

    final shareText =
        '''
📰 $title

$type:
$content

원본 기사: ${news.link}
    ''';

    Share.share(shareText, subject: title);
  }

  // 원본 기사 공유 메서드
  void _shareOriginalArticle() {
    final newsAsync = ref.watch(newsDetailProvider(widget.newsId));
    final news = newsAsync.value;
    if (news == null) return;

    final shareText =
        '''
📰 ${news.title}

${news.description}

원본 기사: ${news.link}
    ''';

    Share.share(shareText, subject: news.title);
  }

  // TTS 재생/정지 메서드
  Future<void> _toggleTts() async {
    if (_flutterTts == null) return;

    if (_isSpeaking) {
      await _flutterTts!.stop();
      setState(() {
        _isSpeaking = false;
      });
    } else {
      final newsAsync = ref.watch(newsDetailProvider(widget.newsId));
      final news = newsAsync.value;
      if (news == null) return;

      // HTML 태그 제거하고 읽기
      final cleanText = news.description
          .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), ' ')
          .replaceAll(RegExp(r'<[^>]*>'), '')
          .replaceAll(RegExp(r'&[^;]+;'), '');

      setState(() {
        _isSpeaking = true;
      });

      await _flutterTts!.speak('${news.title}. $cleanText');
    }
  }

  // 요약 섹션으로 스크롤
  void _scrollToSummary() {
    final context = _summaryKey.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final newsAsync = ref.watch(newsDetailProvider(widget.newsId));
    final fontSize = ref.watch(fontSizeProvider);
    final news = newsAsync.value ?? _displayNews;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          '뉴스 상세',
          style: TextStyle(
            color: Theme.of(context).textTheme.titleLarge?.color,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(
          color: Theme.of(context).textTheme.titleLarge?.color,
        ),
        leading: _buildBackButton(),
        actions: [],
      ),
      body: news == null
          ? const Center(child: RoundedCircularProgress())
          : Stack(
              children: [
                ListView(
                  controller: _scrollController,
                  children: [
                    if (_isRefreshingDetail || newsAsync.isLoading)
                      RefreshStatusCard(message: '상세 데이터를 갱신하는 중...'),
                    // 기존 상세 UI (news 객체 사용)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (news.mediaUrl.isNotEmpty)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: CachedNetworkImage(
                                imageUrl: news.mediaUrl,
                                width: double.infinity,
                                height: 200,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  width: double.infinity,
                                  height: 200,
                                  color: AppColors.surface,
                                  child: const Center(
                                    child: RoundedCircularProgress(),
                                  ),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  width: double.infinity,
                                  height: 200,
                                  color: AppColors.surface,
                                  child: Icon(
                                    Icons.error_outline,
                                    size: 64,
                                    color: AppColors.textTertiary,
                                  ),
                                ),
                              ),
                            ),
                          const SizedBox(height: 16),
                          Text(
                            news.title,
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: fontSize + 4,
                                ),
                          ),
                          const SizedBox(height: 8),
                          // 게시일 표시
                          Text(
                            _formatKoreanDateTime(news.pubDate),
                            style: TextStyle(
                              fontSize: fontSize - 2,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // 뉴스듣기, AI 요약보기 버튼
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _toggleTts,
                                  icon: Icon(
                                    _isSpeaking ? Icons.stop : Icons.volume_up,
                                  ),
                                  label: Text(_isSpeaking ? '정지' : '뉴스 듣기'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _isSpeaking
                                        ? AppColors.error
                                        : AppColors.primary,
                                    foregroundColor: AppColors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _scrollToSummary,
                                  icon: const Icon(Icons.summarize),
                                  label: const Text('AI 요약보기'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.primary,
                                    side: BorderSide(color: AppColors.primary),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // 본문 - entities 하이라이트 적용
                          _buildHighlightedText(
                            news.description,
                            news.entities ?? [],
                            fontSize: fontSize,
                          ),
                          const SizedBox(height: 24),

                          // 3가지 요약 표시 (키 추가)
                          Container(
                            key: _summaryKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (news.summary != null &&
                                    news.summary!.isNotEmpty) ...[
                                  _buildSummarySection(
                                    '📝 일반 요약',
                                    news.summary!,
                                    fontSize,
                                  ),
                                  const SizedBox(height: 16),
                                ],

                                if (news.easySummary != null &&
                                    news.easySummary!.isNotEmpty) ...[
                                  _buildSummarySection(
                                    '🎯 쉬운 요약',
                                    news.easySummary!,
                                    fontSize,
                                  ),
                                  const SizedBox(height: 16),
                                ],

                                if (news.summary3lines != null &&
                                    news.summary3lines!.isNotEmpty) ...[
                                  _buildSummary3LinesSection(
                                    '📋 3줄 요약',
                                    news.summary3lines!,
                                    fontSize,
                                  ),
                                  const SizedBox(height: 16),
                                ],
                              ],
                            ),
                          ),

                          if (news.link.isNotEmpty)
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () async {
                                      final url = Uri.parse(news.link);
                                      try {
                                        await launchUrl(
                                          url,
                                          mode: LaunchMode.externalApplication,
                                        );
                                      } catch (e) {
                                        if (mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                '링크 열기 중 오류가 발생했습니다: $e',
                                              ),
                                            ),
                                          );
                                        }
                                      }
                                    },
                                    icon: const Icon(Icons.open_in_new),
                                    label: const Text('원본 기사 보기'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                ElevatedButton.icon(
                                  onPressed: _shareOriginalArticle,
                                  icon: const Icon(Icons.share),
                                  label: const Text('공유'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.surface,
                                    foregroundColor: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ],
                ),
                // Entity 상세 모달
                if (selectedEntity != null)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: _buildEntityModal(selectedEntity!),
                  ),
              ],
            ),
      bottomNavigationBar: SafeArea(
        child: Container(
          color: Theme.of(context).appBarTheme.backgroundColor,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(Icons.arrow_back),
              label: const Text('목록으로 돌아가기'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHighlightedText(
    String text,
    List<NewsEntity> entities, {
    double fontSize = 16,
  }) {
    // <br> 태그를 \n으로 변환
    final processedText = text.replaceAll(
      RegExp(r'<br\s*/?>', caseSensitive: false),
      '\n',
    );
    if (entities.isEmpty) {
      return Text(
        processedText,
        style: Theme.of(
          context,
        ).textTheme.bodyLarge?.copyWith(fontSize: fontSize),
      );
    }

    // entities를 텍스트 위치 순으로 정렬
    final sortedEntities = List<NewsEntity>.from(entities);
    sortedEntities.sort((a, b) {
      final aIndex = processedText.toLowerCase().indexOf(a.text.toLowerCase());
      final bIndex = processedText.toLowerCase().indexOf(b.text.toLowerCase());
      return aIndex.compareTo(bIndex);
    });

    final List<TextSpan> spans = [];
    int currentIndex = 0;

    for (final entity in sortedEntities) {
      final entityText = entity.text;
      final entityIndex = processedText.toLowerCase().indexOf(
        entityText.toLowerCase(),
        currentIndex,
      );

      if (entityIndex == -1) continue; // 텍스트에서 찾을 수 없는 경우

      // entity 이전 텍스트 추가
      if (entityIndex > currentIndex) {
        spans.add(
          TextSpan(
            text: processedText.substring(currentIndex, entityIndex),
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(fontSize: fontSize),
          ),
        );
      }

      // entity 텍스트 추가 (색상 적용 및 클릭 가능)
      spans.add(
        TextSpan(
          text: processedText.substring(
            entityIndex,
            entityIndex + entityText.length,
          ),
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: _getEntityColor(entity.type),
            fontWeight: FontWeight.w600,
            decoration: TextDecoration.underline,
            fontSize: fontSize,
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () {
              setState(() {
                if (selectedEntity?.text == entity.text &&
                    selectedEntity?.type == entity.type) {
                  selectedEntity = null;
                } else {
                  selectedEntity = entity;
                }
              });
            },
        ),
      );

      currentIndex = entityIndex + entityText.length;
    }

    // 남은 텍스트 추가
    if (currentIndex < processedText.length) {
      spans.add(
        TextSpan(
          text: processedText.substring(currentIndex),
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(fontSize: fontSize),
        ),
      );
    }

    return RichText(text: TextSpan(children: spans));
  }

  Widget _buildEntityModal(NewsEntity entity) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.overlay.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 헤더 (타이틀 배경색을 엔티티 타입 색상으로)
          GestureDetector(
            onTap: () {
              setState(() {
                selectedEntity = null;
              });
            },
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _getEntityColor(entity.type),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      _getEntityTypeName(entity.type),
                      style: TextStyle(
                        color: _getEntityColor(entity.type),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      entity.text,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Icon(Icons.close, color: Colors.white, size: 20),
                ],
              ),
            ),
          ),
          // 내용
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              entity.description,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection(String title, String content, double fontSize) {
    final newsAsync = ref.watch(newsDetailProvider(widget.newsId));
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.titleMedium?.color,
                  ),
                ),
              ),
              IconButton(
                onPressed: () =>
                    _shareSummary(newsAsync.value?.title ?? '', content, title),
                icon: Icon(
                  Icons.share_outlined,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontSize: fontSize - 2,
              color: Theme.of(context).textTheme.bodyMedium?.color,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary3LinesSection(
    String title,
    String content,
    double fontSize,
  ) {
    final lines = content.split('\n');
    final newsAsync = ref.watch(newsDetailProvider(widget.newsId));
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.titleMedium?.color,
                  ),
                ),
              ),
              IconButton(
                onPressed: () =>
                    _shareSummary(newsAsync.value?.title ?? '', content, title),
                icon: Icon(
                  Icons.share_outlined,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...lines.map(
            (line) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                line,
                style: TextStyle(
                  fontSize: fontSize - 2,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
