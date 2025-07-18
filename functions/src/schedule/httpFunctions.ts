import {onRequest} from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import { fetchNewsFromRSS } from "../services/rssService";
import { saveNewsToFirestore, getRecentNews, getNewsDetailById, increaseNewsViewCount, getNewsCount } from "../services/firestoreService";
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
 * 쿼리: page(1부터), pageSize(기본 10, 최대 100), category(선택적), cursor(선택적)
 */
export const getNewsListAPI = onRequest({
  timeoutSeconds: 60
}, async (request, response) => {
  try {
    logger.info("뉴스 목록 페이지네이션 조회 요청");
    const page = Math.max(1, parseInt(request.query.page as string) || 1);
    const pageSize = Math.min(Math.max(1, parseInt(request.query.pageSize as string) || 10), 100);
    const category = request.query.category as string;
    const cursor = request.query.cursor as string; // 커서 기반 페이지네이션용
    
    let query = admin.firestore().collection('news').orderBy('pubDate', 'desc'); // pubDate 기준 내림차순
    
    // 카테고리 필터링
    if (category) {
      if (category === 'politics') {
        // 정치 카테고리만
        query = query.where('category', '==', '정치');
      } else if (category === 'all') {
        // 정치 제외한 모든 카테고리
        query = query.where('category', '!=', '정치');
      }
    }
    
    // 커서 기반 페이지네이션 적용
    if (cursor && page > 1) {
      try {
        // 커서를 Timestamp로 변환
        const cursorTimestamp = admin.firestore.Timestamp.fromMillis(parseInt(cursor));
        query = query.startAfter(cursorTimestamp);
      } catch (error) {
        logger.warn("커서 파싱 실패, 첫 페이지부터 조회:", error);
      }
    }
    
    // 전체 개수 조회
    const totalSize = await getNewsCount(category);
    
    const snapshot = await query
      .limit(pageSize)
      .get();
    
    const news = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
    
    // 다음 페이지용 커서 생성 (마지막 문서의 pubDate 사용)
    let nextCursor = null;
    if (news.length > 0 && news.length === pageSize) {
      const lastNews = news[news.length - 1] as any;
      if (lastNews.pubDate && lastNews.pubDate._seconds) {
        nextCursor = (lastNews.pubDate._seconds * 1000).toString();
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
        category,
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

/**
 * 조회수만 업데이트하는 HTTP 함수
 * 쿼리: docId(필수)
 */
export const updateNewsViewCountAPI = onRequest({
  timeoutSeconds: 30
}, async (request, response) => {
  try {
    const docId = request.query.docId as string;
    if (!docId) {
      response.status(400).json({ success: false, message: "docId 파라미터가 필요합니다." });
      return;
    }
    
    // 조회수 증가
    await increaseNewsViewCount(docId);
    response.json({ success: true, message: "조회수 업데이트 완료" });
  } catch (error) {
    logger.error("조회수 업데이트 오류:", error);
    response.status(500).json({ success: false, message: "조회수 업데이트 오류", error: error instanceof Error ? error.message : error });
  }
}); 