import {onRequest} from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import { fetchNewsFromRSS } from "../services/rssService";
import { saveNewsToFirestore, getRecentNews } from "../services/firestoreService";

/**
 * 수동으로 뉴스를 가져오는 HTTP 함수 (테스트용)
 */
export const fetchNewsManually = onRequest(async (request, response) => {
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
export const getRecentNewsAPI = onRequest(async (request, response) => {
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
export const getNewsStatus = onRequest(async (request, response) => {
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