import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import { NewsItem, NewsSaveResult } from "../models/news";

// Firestore 데이터베이스 참조
const db = admin.firestore();

/**
 * guid를 안전한 Firestore 문서 ID로 변환하는 함수
 * @param guid 원본 guid
 * @returns string 안전한 문서 ID
 */
function createSafeDocumentId(guid: string): string {
  // guid가 이미 안전한 형태인지 확인
  if (guid.match(/^[a-zA-Z0-9_-]+$/)) {
    return guid;
  }
  
  // URL에서 news_id 파라미터 추출
  try {
    const url = new URL(guid);
    const newsId = url.searchParams.get('news_id');
    if (newsId) {
      return `sbs_news_${newsId}`;
    }
  } catch (error) {
    logger.warn(`URL 파싱 실패: ${guid}`);
  }
  
  // URL이 아닌 경우 특수문자만 제거하고 해시 생성
  const crypto = require('crypto');
  const hash = crypto.createHash('md5').update(guid).digest('hex').substring(0, 16);
  return `sbs_news_${hash}`;
}

/**
 * 뉴스 데이터를 Firestore에 저장하는 함수 (상위 10건만, 중복 guid는 merge)
 * @param newsItems 저장할 뉴스 아이템 배열
 * @returns Promise<NewsSaveResult> 저장 결과
 */
export async function saveNewsToFirestore(newsItems: NewsItem[]): Promise<NewsSaveResult> {
  try {
    logger.info("Firestore에 뉴스 데이터를 저장하는 중...");
    
    // 상위 10건만 처리
    const limitedNewsItems = newsItems.slice(0, 10);
    logger.info(`총 ${newsItems.length}개 중 상위 ${limitedNewsItems.length}개 처리`);
    
    const batch = db.batch();
    let savedCount = 0;
    let updatedCount = 0;

    for (const item of limitedNewsItems) {
      // guid 로깅
      logger.info(`처리 중인 뉴스: guid=${item.guid}, title=${item.title}`);
      
      // guid를 안전한 문서 ID로 변환
      const docId = createSafeDocumentId(item.guid);
      const docRef = db.collection('news').doc(docId);
      
      logger.info(`문서 ID 변환: ${item.guid} -> ${docId}`);
      
      // 기존 문서 확인
      const doc = await docRef.get();
      
      if (doc.exists) {
        // 기존 문서가 있으면 merge(업데이트)
        batch.set(docRef, {
          ...item,
          updatedAt: admin.firestore.FieldValue.serverTimestamp()
        }, { merge: true });
        updatedCount++;
        logger.info(`기존 문서 업데이트: ${docId}`);
      } else {
        // 새 문서 생성
        batch.set(docRef, {
          ...item,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp()
        });
        savedCount++;
        logger.info(`새 문서 생성: ${docId}`);
      }
    }

    // 배치 커밋
    await batch.commit();
    
    const result: NewsSaveResult = {
      savedCount,
      updatedCount,
      totalCount: limitedNewsItems.length
    };
    
    logger.info(`뉴스 저장 완료: 새로 저장된 ${savedCount}개, 업데이트된 ${updatedCount}개`);
    return result;
  } catch (error) {
    logger.error("Firestore에 데이터를 저장하는 중 오류 발생:", error);
    throw error;
  }
}

/**
 * 특정 뉴스 아이템이 이미 존재하는지 확인하는 함수
 * @param guid 뉴스 아이템의 고유 식별자
 * @returns Promise<boolean> 존재 여부
 */
export async function isNewsExists(guid: string): Promise<boolean> {
  try {
    const docId = createSafeDocumentId(guid);
    const doc = await db.collection('news').doc(docId).get();
    return doc.exists;
  } catch (error) {
    logger.error(`뉴스 존재 여부 확인 중 오류 발생 (guid: ${guid}):`, error);
    throw error;
  }
}

/**
 * 뉴스 컬렉션에서 최근 뉴스를 가져오는 함수
 * @param limit 가져올 뉴스 개수 (기본값: 10)
 * @returns Promise<NewsItem[]> 뉴스 아이템 배열
 */
export async function getRecentNews(limit: number = 10): Promise<NewsItem[]> {
  try {
    const snapshot = await db.collection('news')
      .orderBy('createdAt', 'desc')
      .limit(limit)
      .get();

    const newsItems: NewsItem[] = [];
    snapshot.forEach(doc => {
      const data = doc.data();
      newsItems.push({
        title: data.title,
        link: data.link,
        description: data.description,
        pubDate: data.pubDate,
        guid: data.guid,
        category: data.category,
        mediaUrl: data.mediaUrl,
        summary: data.summary,
        summary3lines: data.summary3lines,
        easySummary: data.easySummary,
        entities: data.entities,
        viewCount: data.viewCount || 0
      });
    });

    return newsItems;
  } catch (error) {
    logger.error("최근 뉴스를 가져오는 중 오류 발생:", error);
    throw error;
  }
} 

/**
 * 뉴스 컬렉션의 전체 개수를 가져오는 함수
 * @param category 카테고리 필터 (선택적)
 * @returns Promise<number> 전체 뉴스 개수
 */
export async function getNewsCount(category?: string): Promise<number> {
  try {
    let query: admin.firestore.Query = db.collection('news');
    
    // 카테고리 필터링
    if (category) {
      if (category === 'politics') {
        query = query.where('category', '==', '정치');
      } else if (category === 'all') {
        query = query.where('category', '!=', '정치');
      }
    }
    
    const snapshot = await query.get();
    return snapshot.size;
  } catch (error) {
    logger.error("뉴스 개수 조회 중 오류 발생:", error);
    throw error;
  }
}

/**
 * 문서 ID로 뉴스 상세를 반환하는 함수
 * @param docId Firestore 문서 ID
 * @returns Promise<NewsItem | null>
 */
export async function getNewsDetailById(docId: string): Promise<NewsItem | null> {
  try {
    const doc = await db.collection('news').doc(docId).get();
    if (!doc.exists) return null;
    return doc.data() as NewsItem;
  } catch (error) {
    logger.error(`뉴스 상세 조회 중 오류 발생 (docId: ${docId}):`, error);
    throw error;
  }
}

/**
 * 문서 ID로 조회수를 1 증가시키는 함수
 * @param docId Firestore 문서 ID
 * @returns Promise<void>
 */
export async function increaseNewsViewCount(docId: string): Promise<void> {
  try {
    const docRef = db.collection('news').doc(docId);
    await docRef.set({
      viewCount: admin.firestore.FieldValue.increment(1)
    }, { merge: true });
  } catch (error) {
    logger.error(`뉴스 조회수 증가 중 오류 발생 (docId: ${docId}):`, error);
    throw error;
  }
} 

/**
 * 조회수 기준으로 뉴스를 가져오는 함수
 * @param limit 가져올 뉴스 개수 (기본값: 10)
 * @returns Promise<NewsItem[]> 뉴스 아이템 배열
 */
export async function getPopularNews(limit: number = 10): Promise<NewsItem[]> {
  try {
    const snapshot = await db.collection('news')
      .orderBy('viewCount', 'desc')
      .limit(limit)
      .get();

    const newsItems: NewsItem[] = [];
    snapshot.forEach(doc => {
      const data = doc.data();
      newsItems.push({
        title: data.title,
        link: data.link,
        description: data.description,
        pubDate: data.pubDate,
        guid: data.guid,
        category: data.category,
        mediaUrl: data.mediaUrl,
        summary: data.summary,
        summary3lines: data.summary3lines,
        easySummary: data.easySummary,
        entities: data.entities,
        viewCount: data.viewCount || 0
      });
    });

    return newsItems;
  } catch (error) {
    logger.error("조회수 기준 뉴스를 가져오는 중 오류 발생:", error);
    throw error;
  }
}

/**
 * 조회수 기준으로 뉴스 목록을 페이지네이션으로 가져오는 함수
 * @param pageSize 페이지 크기
 * @param cursor 커서 (조회수 값)
 * @returns Promise<{news: NewsItem[], nextCursor: number | null, hasMore: boolean}>
 */
export async function getPopularNewsPaginated(
  pageSize: number, 
  cursor?: number
): Promise<{news: NewsItem[], nextCursor: number | null, hasMore: boolean}> {
  try {
    let query: admin.firestore.Query = db.collection('news');
    
    // 조회수 기준 내림차순 정렬
    query = query.orderBy('viewCount', 'desc');
    
    // 커서가 있으면 해당 조회수보다 작은 값부터 조회
    if (cursor !== undefined) {
      query = query.startAfter(cursor);
    }
    
    const snapshot = await query
      .limit(pageSize + 1) // 다음 페이지 존재 여부 확인을 위해 1개 더 가져옴
      .get();

    const newsItems: NewsItem[] = [];
    snapshot.forEach(doc => {
      const data = doc.data();
      newsItems.push({
        title: data.title,
        link: data.link,
        description: data.description,
        pubDate: data.pubDate,
        guid: data.guid,
        category: data.category,
        mediaUrl: data.mediaUrl,
        summary: data.summary,
        summary3lines: data.summary3lines,
        easySummary: data.easySummary,
        entities: data.entities,
        viewCount: data.viewCount || 0
      });
    });

    // 다음 페이지 존재 여부 확인
    const hasMore = newsItems.length > pageSize;
    const news = hasMore ? newsItems.slice(0, pageSize) : newsItems;
    
    // 다음 페이지용 커서 생성 (마지막 문서의 조회수 사용)
    let nextCursor: number | null = null;
    if (hasMore && news.length > 0) {
      const lastNews = news[news.length - 1];
      nextCursor = lastNews.viewCount || 0;
    }

    return {
      news,
      nextCursor,
      hasMore
    };
  } catch (error) {
    logger.error("조회수 기준 뉴스 페이지네이션 조회 중 오류 발생:", error);
    throw error;
  }
} 