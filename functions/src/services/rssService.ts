import axios from "axios";
import * as xml2js from "xml2js";
import * as logger from "firebase-functions/logger";
import * as admin from "firebase-admin";
import { NewsItem, RSSItem } from "../models/news";
import { extractSBSNewsContent } from "../utils/htmlUtils";

// SBS 뉴스 RSS 피드 URL
const RSS_URL = "https://news.sbs.co.kr/news/newsflashRssFeed.do?plink=RSSREADER";

/**
 * category에서 문자열만 추출하는 함수
 */
function extractCategory(category: any): string | undefined {
  if (!category) return undefined;
  if (typeof category === 'string') return category.trim();
  if (Array.isArray(category)) {
    // 배열이면 첫 번째 문자열만
    for (const c of category) {
      const str = extractCategory(c);
      if (str) return str;
    }
    return undefined;
  }
  // 객체({ _: '사회', ... }) 구조
  if (typeof category === 'object' && '_' in category) {
    return typeof category._ === 'string' ? category._.trim() : undefined;
  }
  return undefined;
}

/**
 * pubDate를 Firestore Timestamp로 변환
 */
function toTimestamp(pubDate: string | undefined): admin.firestore.Timestamp {
  if (!pubDate) return admin.firestore.Timestamp.now();
  const date = new Date(pubDate);
  if (isNaN(date.getTime())) return admin.firestore.Timestamp.now();
  return admin.firestore.Timestamp.fromDate(date);
}

/**
 * RSS 피드에서 뉴스 데이터를 가져오는 함수
 * @returns Promise<NewsItem[]> 뉴스 아이템 배열
 */
export async function fetchNewsFromRSS(): Promise<NewsItem[]> {
  try {
    logger.info("RSS 피드에서 뉴스 데이터를 가져오는 중...");
    
    const response = await axios.get(RSS_URL, {
      timeout: 10000,
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
      }
    });

    const parser = new xml2js.Parser({ explicitArray: false });
    const result = await parser.parseStringPromise(response.data);

    const items = result.rss.channel.item;
    const newsItems: NewsItem[] = [];

    // 단일 아이템인 경우 배열로 변환
    const itemArray = Array.isArray(items) ? items : [items];

    for (const item of itemArray) {
      if (item && item.title && item.link) {
        // media:content url 추출
        let mediaUrl: string | undefined = undefined;
        if (item['media:content'] && item['media:content'].$ && item['media:content'].$.url) {
          mediaUrl = item['media:content'].$.url;
        } else if (item['media:content'] && item['media:content'].url) {
          mediaUrl = item['media:content'].url;
        }

        // 안정적인 guid 생성
        const guid = generateStableGuid(item);
        
        // pubDate를 Timestamp로 변환
        const pubDate = toTimestamp(item.pubDate);
        
        // 기본 뉴스 아이템 생성
        const newsItem: NewsItem = {
          title: item.title.trim(),
          link: item.link.trim(),
          description: item.description ? item.description.trim() : "",
          pubDate: pubDate,
          guid: guid,
          category: extractCategory(item.category),
          mediaUrl: mediaUrl
        };

        logger.info(`뉴스 아이템 생성: guid=${guid}, title=${item.title.trim()}`);

        // 뉴스 본문 가져와서 description 보강
        try {
          const fullContent = await extractSBSNewsContent(item.link.trim());
          if (fullContent) {
            // 본문이 있으면 description에 추가 (최대 500자)
            const enhancedDescription = fullContent.length > 500 
              ? fullContent.substring(0, 500) + '...' 
              : fullContent;
            newsItem.description = enhancedDescription;
          }
        } catch (error) {
          logger.warn(`뉴스 본문 가져오기 실패 (${item.link}):`, error);
          // 본문 가져오기 실패해도 기본 description 유지
        }

        newsItems.push(newsItem);
      }
    }

    logger.info(`${newsItems.length}개의 뉴스 아이템을 성공적으로 가져왔습니다.`);
    return newsItems;
  } catch (error) {
    logger.error("RSS 피드에서 데이터를 가져오는 중 오류 발생:", error);
    throw error;
  }
}

/**
 * 안정적인 guid를 생성하는 함수
 * @param item RSS 아이템
 * @returns string guid
 */
function generateStableGuid(item: any): string {
  if (item.guid && typeof item.guid === 'string' && item.guid.trim()) {
    return item.guid.trim();
  }
  if (item.link && typeof item.link === 'string') {
    try {
      const url = new URL(item.link);
      const newsId = url.searchParams.get('news_id');
      if (newsId) {
        return `sbs_news_${newsId}`;
      }
    } catch (error) {
      logger.warn(`URL 파싱 실패: ${item.link}`);
    }
  }
  if (item.link && typeof item.link === 'string') {
    const hash = require('crypto').createHash('md5').update(item.link).digest('hex');
    return `sbs_news_${hash}`;
  }
  return `sbs_news_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
}

/**
 * RSS 아이템을 NewsItem으로 변환하는 함수
 * @param item RSS 아이템
 * @returns NewsItem 변환된 뉴스 아이템
 */
export function convertRSSItemToNewsItem(item: RSSItem): NewsItem {
  const guid = generateStableGuid(item);
  return {
    title: item.title.trim(),
    link: item.link.trim(),
    description: item.description ? item.description.trim() : "",
    pubDate: toTimestamp(item.pubDate),
    guid: guid,
    category: extractCategory(item.category),
    mediaUrl: (item['media:content'] && item['media:content'].$ && item['media:content'].$.url) ? item['media:content'].$.url : (item['media:content'] && item['media:content'].url) ? item['media:content'].url : undefined
  };
} 