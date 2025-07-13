import * as admin from "firebase-admin";

// 엔터티 타입 정의 (단순화)
export interface Entity {
  text: string;
  type: 'PERSON' | 'LOCATION' | 'ORGANIZATION' | 'COMPANY' | 'COUNTRY';
  description: string;
}

// 뉴스 아이템 인터페이스
export interface NewsItem {
  title: string;
  link: string;
  description: string;
  pubDate: string | admin.firestore.Timestamp;
  guid: string;
  category?: string;
  mediaUrl?: string;
  summary?: string;
  summary3lines?: string;
  easySummary?: string;
  entities?: Entity[]; // 엔터티 정보 추가
}

// RSS 피드 응답 인터페이스
export interface RSSResponse {
  rss: {
    channel: {
      item: RSSItem | RSSItem[];
    };
  };
}

// RSS 아이템 인터페이스
export interface RSSItem {
  title: string;
  link: string;
  description?: string;
  pubDate?: string;
  guid?: string;
  category?: any;
  [key: string]: any;
}

// 뉴스 저장 결과 인터페이스
export interface NewsSaveResult {
  savedCount: number;
  updatedCount: number;
  totalCount: number;
} 