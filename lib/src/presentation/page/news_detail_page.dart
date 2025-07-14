import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import '../controller/news_controller.dart';
import '../../domain/entity/news.dart';
import '../../domain/entity/news_entity.dart';
import '../../data/constants/app_colors.dart';
import 'package:intl/intl.dart';
import '../widgets/font_size_menu.dart';
import '../widgets/rounded_circular_progress.dart';
import '../controller/font_size_provider.dart';

class NewsDetailPage extends ConsumerStatefulWidget {
  final String newsId;

  const NewsDetailPage({super.key, required this.newsId});

  @override
  ConsumerState<NewsDetailPage> createState() => _NewsDetailPageState();
}

class _NewsDetailPageState extends ConsumerState<NewsDetailPage> {
  NewsEntity? selectedEntity;
  bool _hasUpdatedViewCount = false;
  bool _isRefreshingDetail = false;

  @override
  void initState() {
    super.initState();
    // 상세화면 진입 시 상세정보를 다시 호출
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshNewsDetail();
    });
  }

  @override
  void dispose() {
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

  // 상세정보를 다시 호출하는 메서드
  Future<void> _refreshNewsDetail() async {
    print('🔄 상세정보 갱신 시작: ${widget.newsId}');
    setState(() {
      _isRefreshingDetail = true;
    });

    try {
      // 상세정보를 다시 호출
      print('📡 API 호출 시작');
      await ref.refresh(newsDetailProvider(widget.newsId));
      print('✅ API 호출 완료');

      // 목록의 조회수를 낙관적 업데이트
      ref
          .read(allNewsListProvider.notifier)
          .updateViewCountOptimistically(widget.newsId);
      print('📊 조회수 낙관적 업데이트 완료');
    } catch (e) {
      // 에러는 무시 (사용자 경험에 영향 없음)
      print('❌ 상세정보 갱신 실패: $e');
    } finally {
      setState(() {
        _isRefreshingDetail = false;
      });
      print('🏁 상세정보 갱신 완료');
    }
  }

  String _formatKoreanDateTime(DateTime dateTime) {
    return DateFormat('yyyy년 M월 d일 H시 mm분', 'ko_KR').format(dateTime);
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

  @override
  Widget build(BuildContext context) {
    final newsAsync = ref.watch(newsDetailProvider(widget.newsId));
    final fontSize = ref.watch(fontSizeProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          '뉴스 상세',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppColors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
        actions: [
          FontSizeMenu(
            currentSize: fontSize,
            fontSizes: fontSizeOptions,
            onSelected: (size) =>
                ref.read(fontSizeProvider.notifier).setFontSize(size),
          ),
        ],
      ),
      body: Stack(
        children: [
          newsAsync.when(
            data: (news) {
              return Stack(
                children: [
                  SingleChildScrollView(
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
                                child: Icon(
                                  Icons.image_outlined,
                                  size: 64,
                                  color: AppColors.textTertiary,
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

                        // 본문 - entities 하이라이트 적용
                        _buildHighlightedText(
                          news.description,
                          news.entities ?? [],
                          fontSize: fontSize,
                        ),
                        const SizedBox(height: 24),

                        // 3가지 요약 표시
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

                        if (news.link.isNotEmpty)
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    final url = Uri.parse(news.link);
                                    try {
                                      if (await canLaunchUrl(url)) {
                                        await launchUrl(
                                          url,
                                          mode: LaunchMode.externalApplication,
                                        );
                                      } else {
                                        if (mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                '링크를 열 수 없습니다: ${news.link}',
                                              ),
                                            ),
                                          );
                                        }
                                      }
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

                  // Entity 상세 모달
                  if (selectedEntity != null)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: _buildEntityModal(selectedEntity!),
                    ),
                ],
              );
            },
            loading: () => const Center(child: RoundedCircularProgress()),
            error: (e, _) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: AppColors.error),
                  const SizedBox(height: 16),
                  Text('에러가 발생했습니다: $e'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () =>
                        ref.refresh(newsDetailProvider(widget.newsId)),
                    child: const Text('다시 시도'),
                  ),
                ],
              ),
            ),
          ),

          // 상세정보 갱신 중 로딩 카드
          if (_isRefreshingDetail)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.overlay.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '상세 정보를 갱신하고 있습니다...',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          color: AppColors.white,
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
        color: AppColors.white,
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
          // 헤더 (전체 탭 시 닫힘)
          GestureDetector(
            onTap: () {
              setState(() {
                selectedEntity = null;
              });
            },
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
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
                      color: _getEntityColor(entity.type).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _getEntityColor(entity.type).withOpacity(0.3),
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
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Icon(Icons.close, color: AppColors.textSecondary, size: 20),
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
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider, width: 1),
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
                    color: AppColors.textPrimary,
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
              color: AppColors.textSecondary,
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
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider, width: 1),
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
                    color: AppColors.textPrimary,
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
