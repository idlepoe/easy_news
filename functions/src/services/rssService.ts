import axios from "axios";
import * as xml2js from "xml2js";
import * as logger from "firebase-functions/logger";
import * as admin from "firebase-admin";
import { NewsItem, RSSItem, Entity } from "../models/news";
import { extractSBSNewsContent } from "../utils/htmlUtils";
import { VertexAI } from "@google-cloud/vertexai";
import 'dotenv/config'

// Vertex AI 설정
const PROJECT_ID = process.env.GOOGLE_CLOUD_PROJECT || "easy-news-9545c";
const LOCATION = "us-central1";
const GEMINI_MODEL = "gemini-2.5-flash";

// Vertex AI 초기화
const vertexAI = new VertexAI({ project: PROJECT_ID, location: LOCATION });
const generativeModel = vertexAI.getGenerativeModel({ model: GEMINI_MODEL });

// SBS 뉴스 RSS 피드 URL
const RSS_URL = "https://news.sbs.co.kr/news/newsflashRssFeed.do?plink=RSSREADER";

/**
 * category에서 문자열만 추출하는 함수
 */
function extractCategory(category: any): string | undefined {
  if (!category) return undefined;
  if (typeof category === 'string') return category.trim();
  if (Array.isArray(category)) {
    for (const c of category) {
      const str = extractCategory(c);
      if (str) return str;
    }
    return undefined;
  }
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
 * Gemini로 10개 뉴스 요약 요청 (일반, 3줄, 쉬운 단어) - 한 번에 처리
 */
async function summarizeNewsBatch(newsList: NewsItem[]): Promise<{
  summary: string[];
  summary3lines: string[];
  easySummary: string[];
}> {

  // 뉴스 제목과 본문 준비
  const newsData = newsList.map((item, index) => ({
    id: index + 1,
    title: item.title,
    content: item.description || item.title
  }));

  // JSON 형태로 한 번에 요청하는 프롬프트
  const batchPrompt = `
다음 ${newsData.length}개의 뉴스 기사를 분석하여 각각 3가지 요약을 제공해주세요.

뉴스 목록:
${newsData.map(news => `
${news.id}. ${news.title}
내용: ${news.content}
`).join('\n')}

각 뉴스에 대해 다음 3가지 요약을 JSON 형태로 응답해주세요:
1. summary: 1문단 요약 (2~3문장, 각 문장 끝에 줄 바꿈(\n) 추가)
2. summary3lines: 3줄 요약 (각 줄은 짧고 간결하게)
3. easySummary: 초등학생도 이해할 수 있는 쉬운 단어로 1문단 요약 (2~3문장, 각 문장 끝에 줄 바꿈(\n) 추가)

**일반 요약과 쉬운 요약은 2~3문장으로 작성하고, 각 문장 끝에는 반드시 줄 바꿈(\\n)을 넣어주세요.**

응답 형식:
{
  "summaries": [
    {
      "id": 1,
      "summary": "1문단 요약 내용",
      "summary3lines": "첫 번째 줄\n두 번째 줄\n세 번째 줄",
      "easySummary": "쉬운 단어로 된 요약 내용"
    },
    ...
  ]
}

JSON만 응답하고 다른 설명은 포함하지 마세요.
`;

  logger.info(`Gemini 배치 요약 요청 시작 (${newsData.length}개 뉴스)`);
  
  try {
    const result = await generativeModel.generateContent({ 
      contents: [{ role: "user", parts: [{ text: batchPrompt }] }] 
    });
    
    const responseText = result.response.candidates?.[0]?.content?.parts?.[0]?.text || '';
    logger.info(`[Gemini] 배치 응답 받음: ${responseText.substring(0, 200)}...`);
    
    // JSON 파싱
    let parsedResponse;
    try {
      // JSON 블록만 추출 (```json ... ``` 형태일 수 있음)
      const jsonMatch = responseText.match(/```json\s*([\s\S]*?)\s*```/) || 
                       responseText.match(/\{[\s\S]*\}/);
      const jsonText = jsonMatch ? jsonMatch[1] || jsonMatch[0] : responseText;
      parsedResponse = JSON.parse(jsonText);
    } catch (parseError) {
      logger.error("JSON 파싱 오류:", parseError, "응답:", responseText);
      throw new Error("AI 응답을 JSON으로 파싱할 수 없습니다.");
    }
    
    // 결과 배열 생성
    const summary: string[] = [];
    const summary3lines: string[] = [];
    const easySummary: string[] = [];
    
    if (parsedResponse.summaries && Array.isArray(parsedResponse.summaries)) {
      for (let i = 0; i < newsData.length; i++) {
        const summaryItem = parsedResponse.summaries.find((item: any) => item.id === i + 1);
        if (summaryItem) {
          summary.push(summaryItem.summary || '');
          summary3lines.push(summaryItem.summary3lines || '');
          easySummary.push(summaryItem.easySummary || '');
          logger.info(`[Gemini] 뉴스 ${i + 1} 요약 완료`);
        } else {
          summary.push('');
          summary3lines.push('');
          easySummary.push('');
          logger.warn(`[Gemini] 뉴스 ${i + 1} 요약 데이터 없음`);
        }
      }
    } else {
      logger.error("예상된 JSON 구조가 아닙니다:", parsedResponse);
      // 빈 배열로 반환
      for (let i = 0; i < newsData.length; i++) {
        summary.push('');
        summary3lines.push('');
        easySummary.push('');
      }
    }
    
    return { summary, summary3lines, easySummary };
  } catch (err) {
    logger.error("Gemini 배치 요약 오류:", err);
    // 오류 시 빈 배열 반환
    const emptyArray = new Array(newsData.length).fill('');
    return { 
      summary: [...emptyArray], 
      summary3lines: [...emptyArray], 
      easySummary: [...emptyArray] 
    };
  }
}

/**
 * Gemini로 뉴스 본문에서 엔터티 추출 (배치 처리)
 */
async function extractEntitiesFromNewsBatch(newsList: NewsItem[]): Promise<Entity[][]> {
  if (newsList.length === 0) {
    return [];
  }

  // 뉴스 제목과 본문 준비
  const newsData = newsList.map((item, index) => ({
    id: index + 1,
    title: item.title,
    content: item.description || item.title
  }));

  const batchPrompt = `
다음 ${newsData.length}개의 뉴스 기사에서 인명, 국가, 기관, 장소, 회사명을 각각 구분하여 JSON 배열로 반환해주세요.

뉴스 목록:
${newsData.map(news => `
${news.id}. ${news.title}
내용: ${news.content}
`).join('\n')}

각 뉴스에 대해 다음 정보를 제공해주세요:
- text: 본문에서 발견된 단어/구문
- type: 엔터티 타입 (PERSON: 인명, COUNTRY: 국가, ORGANIZATION: 기관, LOCATION: 장소, COMPANY: 회사명)
- description: 해당 엔터티에 대한 두 줄 분량의 자세한 설명

응답 형식:
{
  "entities": [
    {
      "newsId": 1,
      "entities": [
        {
          "text": "윤석열",
          "type": "PERSON", 
          "description": "대한민국 대통령. 2022년 5월부터 대한민국의 대통령으로 재임 중이다."
        },
        {
          "text": "서울",
          "type": "LOCATION",
          "description": "대한민국의 수도. 정치, 경제, 문화의 중심지로 다양한 기관과 기업이 위치해 있다."
        }
      ]
    },
    {
      "newsId": 2,
      "entities": [
        {
          "text": "삼성전자",
          "type": "COMPANY",
          "description": "대한민국을 대표하는 글로벌 전자기업. 반도체, 스마트폰 등 다양한 전자제품을 생산한다."
        }
      ]
    }
  ]
}

JSON만 응답하고 다른 설명은 포함하지 마세요. 엔터티가 없으면 빈 배열을 반환하세요.
`;

  logger.info(`[Gemini] 엔터티 배치 추출 요청 시작 (${newsData.length}개 뉴스)`);
  
  try {
    const result = await generativeModel.generateContent({ 
      contents: [{ role: "user", parts: [{ text: batchPrompt }] }] 
    });
    
    const responseText = result.response.candidates?.[0]?.content?.parts?.[0]?.text || '';
    logger.info(`[Gemini] 엔터티 배치 응답 받음: ${responseText.substring(0, 200)}...`);
    
    // JSON 파싱
    let parsedResponse;
    try {
      const jsonMatch = responseText.match(/```json\s*([\s\S]*?)\s*```/) || 
                       responseText.match(/\{[\s\S]*\}/);
      const jsonText = jsonMatch ? jsonMatch[1] || jsonMatch[0] : responseText;
      parsedResponse = JSON.parse(jsonText);
    } catch (parseError) {
      logger.error("엔터티 JSON 파싱 오류:", parseError, "응답:", responseText);
      // 오류 시 빈 배열들 반환
      return new Array(newsData.length).fill([]);
    }
    
    // 결과 배열 생성
    const entitiesResults: Entity[][] = [];
    
    if (parsedResponse.entities && Array.isArray(parsedResponse.entities)) {
      for (let i = 0; i < newsData.length; i++) {
        const newsEntities = parsedResponse.entities.find((item: any) => item.newsId === i + 1);
        if (newsEntities && newsEntities.entities && Array.isArray(newsEntities.entities)) {
          const entities: Entity[] = [];
          for (const entity of newsEntities.entities) {
            if (entity.text && entity.type && entity.description) {
              entities.push({
                text: entity.text,
                type: entity.type,
                description: entity.description
              });
            }
          }
          entitiesResults.push(entities);
          logger.info(`[Gemini] 뉴스 ${i + 1} 엔터티 추출 완료: ${entities.length}개`);
        } else {
          entitiesResults.push([]);
          logger.warn(`[Gemini] 뉴스 ${i + 1} 엔터티 데이터 없음`);
        }
      }
    } else {
      logger.error("예상된 엔터티 JSON 구조가 아닙니다:", parsedResponse);
      // 빈 배열들 반환
      return new Array(newsData.length).fill([]);
    }
    
    return entitiesResults;
  } catch (err) {
    logger.error("Gemini 엔터티 배치 추출 오류:", err);
    // 오류 시 빈 배열들 반환
    return new Array(newsData.length).fill([]);
  }
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
            newsItem.description = fullContent;
          }
        } catch (error) {
          logger.warn(`뉴스 본문 가져오기 실패 (${item.link}):`, error);
        }

        newsItems.push(newsItem);
      }
    }

    logger.info(`${newsItems.length}개의 뉴스 아이템을 성공적으로 가져왔습니다.`);

    // 상위 10개만 Gemini 요약 및 엔터티 추출
    const top10 = newsItems.slice(0, 10);
    const { summary, summary3lines, easySummary } = await summarizeNewsBatch(top10);
    logger.info("Gemini 요약 결과", { summary, summary3lines, easySummary });

    // 엔터티 추출
    const entitiesResults = await extractEntitiesFromNewsBatch(top10);
    logger.info("Gemini 엔터티 추출 결과", { entitiesCount: entitiesResults.map(e => e.length) });

    // 요약 결과와 엔터티를 각 뉴스에 추가
    for (let i = 0; i < top10.length; i++) {
      top10[i].summary = summary[i] || '';
      top10[i].summary3lines = summary3lines[i] || '';
      top10[i].easySummary = easySummary[i] || '';
      top10[i].entities = entitiesResults[i] || [];
    }

    // 나머지 뉴스는 요약 없이 반환
    return [...top10, ...newsItems.slice(10)];
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