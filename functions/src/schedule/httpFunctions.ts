import {onRequest} from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import { fetchNewsFromRSS } from "../services/rssService";
import { saveNewsToFirestore, getRecentNews, getNewsDetailById, increaseNewsViewCount, getNewsCount, getPopularNews, getPopularNewsPaginated } from "../services/firestoreService";
import * as admin from "firebase-admin";

/**
 * 수동으로 뉴스를 가져오는 HTTP 함수 (테스트용)
 */
export const fetchNewsManually = onRequest({
  timeoutSeconds: 540 // 9분 (AI 요청을 위한 충분한 시간)
}, async (request, response) => {
  try {
    logger.info("수동 뉴스 가져오기가 요청되었습니다.");
    
    const newsItems = await fetchNewsFromRSS();
    
    if (newsItems.length > 0) {
      const result = await saveNewsToFirestore(newsItems);
      response.json({
        success: true,
        message: `${newsItems.length}개의 뉴스 아이템을 성공적으로 처리했습니다.`,
        data: {
          totalCount: result.totalCount,
          savedCount: result.savedCount,
          updatedCount: result.updatedCount
        }
      });
    } else {
      response.json({
        success: false,
        message: "가져온 뉴스 아이템이 없습니다."
      });
    }
  } catch (error) {
    logger.error("수동 뉴스 가져오기 중 오류 발생:", error);
    response.status(500).json({
      success: false,
      message: "뉴스 가져오기 중 오류가 발생했습니다.",
      error: error instanceof Error ? error.message : "Unknown error"
    });
  }
});

/**
 * 최근 뉴스를 가져오는 HTTP 함수
 */
export const getRecentNewsAPI = onRequest({
  timeoutSeconds: 540 // 9분 (단순 조회이므로 짧게)
}, async (request, response) => {
  try {
    logger.info("최근 뉴스 조회가 요청되었습니다.");
    
    // 쿼리 파라미터에서 limit 가져오기 (기본값: 10)
    const limit = parseInt(request.query.limit as string) || 10;
    
    // 최대 100개로 제한
    const safeLimit = Math.min(limit, 100);
    
    const newsItems = await getRecentNews(safeLimit);
    
    response.json({
      success: true,
      message: `${newsItems.length}개의 최근 뉴스를 가져왔습니다.`,
      data: {
        count: newsItems.length,
        limit: safeLimit,
        news: newsItems
      }
    });
  } catch (error) {
    logger.error("최근 뉴스 조회 중 오류 발생:", error);
    response.status(500).json({
      success: false,
      message: "최근 뉴스 조회 중 오류가 발생했습니다.",
      error: error instanceof Error ? error.message : "Unknown error"
    });
  }
});

/**
 * 뉴스 상태 확인 HTTP 함수
 */
export const getNewsStatus = onRequest({
  timeoutSeconds: 540 // 9분 (단순 조회이므로 짧게)
}, async (request, response) => {
  try {
    logger.info("뉴스 상태 확인이 요청되었습니다.");
    
    // 최근 5개 뉴스만 가져와서 상태 확인
    const recentNews = await getRecentNews(5);
    
    response.json({
      success: true,
      message: "뉴스 상태 확인이 완료되었습니다.",
      data: {
        totalRecentNews: recentNews.length,
        latestNews: recentNews.length > 0 ? recentNews[0] : null,
        status: "active"
      }
    });
  } catch (error) {
    logger.error("뉴스 상태 확인 중 오류 발생:", error);
    response.status(500).json({
      success: false,
      message: "뉴스 상태 확인 중 오류가 발생했습니다.",
      error: error instanceof Error ? error.message : "Unknown error"
    });
  }
}); 

/**
 * 뉴스 목록을 페이지네이션으로 반환하는 HTTP 함수
 * 쿼리: page(1부터), pageSize(기본 10, 최대 100), cursor(선택적), sortBy(선택적: 'date' 또는 'views')
 */
export const getNewsListAPI = onRequest({
  timeoutSeconds: 60
}, async (request, response) => {
  try {
    logger.info("뉴스 목록 페이지네이션 조회 요청");
    const page = Math.max(1, parseInt(request.query.page as string) || 1);
    const pageSize = Math.min(Math.max(1, parseInt(request.query.pageSize as string) || 10), 100);
    const cursor = request.query.cursor as string; // 커서 기반 페이지네이션용
    const sortBy = request.query.sortBy as string || 'date'; // 정렬 기준: 'date' 또는 'views'
    
    let query: admin.firestore.Query = admin.firestore().collection('news');
    
    // 정렬 기준에 따라 쿼리 설정
    if (sortBy === 'views') {
      // 조회수 기준 내림차순 정렬
      query = query.orderBy('viewCount', 'desc');
    } else {
      // 기본값: 날짜 기준 내림차순 정렬
      query = query.orderBy('pubDate', 'desc');
    }
    
    // 커서 기반 페이지네이션 적용
    if (cursor && page > 1) {
      try {
        if (sortBy === 'views') {
          // 조회수 기준 커서
          const cursorValue = parseInt(cursor);
          query = query.startAfter(cursorValue);
        } else {
          // 날짜 기준 커서
          const cursorTimestamp = admin.firestore.Timestamp.fromMillis(parseInt(cursor));
          query = query.startAfter(cursorTimestamp);
        }
      } catch (error) {
        logger.warn("커서 파싱 실패, 첫 페이지부터 조회:", error);
      }
    }
    
    // 전체 개수 조회
    const totalSize = await getNewsCount();
    
    const snapshot = await query
      .limit(pageSize)
      .get();
    
    const news = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
    
    // 다음 페이지용 커서 생성
    let nextCursor = null;
    if (news.length > 0 && news.length === pageSize) {
      const lastNews = news[news.length - 1] as any;
      if (sortBy === 'views') {
        // 조회수 기준 커서
        nextCursor = (lastNews.viewCount || 0).toString();
      } else {
        // 날짜 기준 커서
        if (lastNews.pubDate && lastNews.pubDate._seconds) {
          nextCursor = (lastNews.pubDate._seconds * 1000).toString();
        }
      }
    }
    
    response.json({
      success: true,
      message: `${news.length}건의 뉴스 목록을 반환합니다.`,
      data: { 
        page, 
        pageSize, 
        count: news.length, 
        totalSize,
        news, 
        sortBy,
        nextCursor,
        hasMore: news.length === pageSize
      }
    });
  } catch (error) {
    logger.error("뉴스 목록 페이지네이션 조회 오류:", error);
    response.status(500).json({ success: false, message: "뉴스 목록 조회 오류", error: error instanceof Error ? error.message : error });
  }
});

/**
 * 조회수 기준으로 인기 뉴스를 가져오는 HTTP 함수
 * 쿼리: limit(기본 10, 최대 100), period(선택적: '24h', '7d', '30d', 'all')
 */
export const getPopularNewsAPI = onRequest({
  timeoutSeconds: 60
}, async (request, response) => {
  try {
    logger.info("조회수 기준 인기 뉴스 조회 요청");
    const limit = Math.min(Math.max(1, parseInt(request.query.limit as string) || 10), 100);
    const period = request.query.period as string || 'all'; // 기간 필터
    
    // 기간 파라미터 검증
    const validPeriods = ['24h', '7d', '30d', 'all'];
    if (!validPeriods.includes(period)) {
      response.status(400).json({ 
        success: false, 
        message: "잘못된 기간 파라미터입니다. '24h', '7d', '30d', 'all' 중 하나를 사용하세요." 
      });
      return;
    }
    
    const newsItems = await getPopularNews(limit, period);
    
    response.json({
      success: true,
      message: `${newsItems.length}건의 인기 뉴스를 반환합니다.`,
      data: {
        count: newsItems.length,
        limit,
        period,
        news: newsItems
      }
    });
  } catch (error) {
    logger.error("조회수 기준 인기 뉴스 조회 오류:", error);
    response.status(500).json({ 
      success: false, 
      message: "인기 뉴스 조회 오류", 
      error: error instanceof Error ? error.message : error 
    });
  }
});

/**
 * 조회수 기준으로 뉴스 목록을 페이지네이션으로 반환하는 HTTP 함수
 * 쿼리: pageSize(기본 10, 최대 100), cursor(선택적), period(선택적: '24h', '7d', '30d', 'all')
 */
export const getPopularNewsPaginatedAPI = onRequest({
  timeoutSeconds: 60
}, async (request, response) => {
  try {
    logger.info("조회수 기준 뉴스 페이지네이션 조회 요청");
    const pageSize = Math.min(Math.max(1, parseInt(request.query.pageSize as string) || 10), 100);
    const cursor = request.query.cursor as string; // 조회수 값
    const period = request.query.period as string || 'all'; // 기간 필터
    
    // 기간 파라미터 검증
    const validPeriods = ['24h', '7d', '30d', 'all'];
    if (!validPeriods.includes(period)) {
      response.status(400).json({ 
        success: false, 
        message: "잘못된 기간 파라미터입니다. '24h', '7d', '30d', 'all' 중 하나를 사용하세요." 
      });
      return;
    }
    
    let cursorValue: number | undefined;
    if (cursor) {
      cursorValue = parseInt(cursor);
    }
    
    const result = await getPopularNewsPaginated(pageSize, cursorValue, period);
    
    response.json({
      success: true,
      message: `${result.news.length}건의 인기 뉴스를 반환합니다.`,
      data: {
        pageSize,
        count: result.news.length,
        period,
        news: result.news,
        nextCursor: result.nextCursor,
        hasMore: result.hasMore
      }
    });
  } catch (error) {
    logger.error("조회수 기준 뉴스 페이지네이션 조회 오류:", error);
    response.status(500).json({ 
      success: false, 
      message: "인기 뉴스 페이지네이션 조회 오류", 
      error: error instanceof Error ? error.message : error 
    });
  }
});

/**
 * 뉴스 상세를 반환하고 조회수 증가까지 처리하는 HTTP 함수
 * 쿼리: docId(필수)
 */
export const getNewsDetailAPI = onRequest({
  timeoutSeconds: 30
}, async (request, response) => {
  try {
    const docId = request.query.docId as string;
    if (!docId) {
      response.status(400).json({ success: false, message: "docId 파라미터가 필요합니다." });
      return;
    }
    // 상세 조회
    const news = await getNewsDetailById(docId);
    if (!news) {
      response.status(404).json({ success: false, message: "해당 뉴스가 존재하지 않습니다." });
      return;
    }
    // 조회수 증가
    await increaseNewsViewCount(docId);
    response.json({ success: true, message: "뉴스 상세 반환 및 조회수 증가 완료", data: news });
  } catch (error) {
    logger.error("뉴스 상세 조회/조회수 증가 오류:", error);
    response.status(500).json({ success: false, message: "뉴스 상세 조회 오류", error: error instanceof Error ? error.message : error });
  }
});

 