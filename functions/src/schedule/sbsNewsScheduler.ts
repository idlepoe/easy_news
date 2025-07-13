import {onSchedule} from "firebase-functions/v2/scheduler";
import * as logger from "firebase-functions/logger";
import { fetchNewsFromRSS } from "../services/rssService";
import { saveNewsToFirestore } from "../services/firestoreService";

/**
 * SBS 뉴스 스케줄러 함수
 * 1시간마다 SBS 뉴스 RSS 피드에서 뉴스 데이터를 가져와서 Firestore에 저장
 */
export const sbsNewsScheduler = onSchedule({
  schedule: "every 1 hours",
  timeZone: "Asia/Seoul",
  retryCount: 3,
  timeoutSeconds: 1800 // 30분 (AI 요청을 위한 충분한 시간)
}, async (event) => {
  try {
    logger.info("SBS 뉴스 스케줄러가 시작되었습니다.");
    
    // RSS 피드에서 뉴스 데이터 가져오기
    const newsItems = await fetchNewsFromRSS();
    
    if (newsItems.length > 0) {
      // Firestore에 저장
      const result = await saveNewsToFirestore(newsItems);
      logger.info(`SBS 뉴스 스케줄러가 성공적으로 완료되었습니다. 새로 저장: ${result.savedCount}개, 업데이트: ${result.updatedCount}개`);
    } else {
      logger.warn("가져온 뉴스 아이템이 없습니다.");
    }
  } catch (error) {
    logger.error("SBS 뉴스 스케줄러 실행 중 오류 발생:", error);
    throw error;
  }
}); 