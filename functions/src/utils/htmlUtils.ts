import * as cheerio from 'cheerio';
import axios from 'axios';

/**
 * HTML에서 텍스트를 추출하는 함수
 * @param html HTML 문자열
 * @returns string 추출된 텍스트
 */
export function extractTextFromHTML(html: string): string {
  const $ = cheerio.load(html);
  
  // script, style 태그 제거
  $('script, style').remove();
  
  // 텍스트 추출 및 정리
  let text = $('body').text()
    .replace(/\s+/g, ' ')  // 연속된 공백을 하나로
    .replace(/\n+/g, '\n') // 연속된 줄바꿈을 하나로
    .trim();
  
  return text;
}

/**
 * HTML 노드를 순회하며 텍스트를 추출하는 재귀 함수
 * @param $ cheerio 인스턴스
 * @param element 현재 요소
 * @returns string 추출된 텍스트
 */
function extractTextFromNode($: cheerio.Root, element: cheerio.Element): string {
  let text = '';
  
  if (element.type === 'text') {
    // 텍스트 노드인 경우
    text += element.data || '';
  } else if (element.type === 'tag') {
    // 태그 노드인 경우
    const tagName = element.name?.toLowerCase();
    
    // <br> 태그는 줄바꿈으로 변환
    if (tagName === 'br') {
      text += '\n';
    } else {
      // 다른 태그는 내부 텍스트를 재귀적으로 추출
      $(element).contents().each((index, childElement) => {
        text += extractTextFromNode($, childElement);
      });
    }
  }
  
  return text;
}

/**
 * SBS 뉴스 페이지에서 본문 텍스트를 추출하는 함수
 * @param url 뉴스 URL
 * @returns Promise<string> 추출된 본문 텍스트
 */
export async function extractSBSNewsContent(url: string): Promise<string> {
  try {
    const response = await axios.get(url, {
      timeout: 10000,
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
      }
    });

    const $ = cheerio.load(response.data);
    
    // SBS 뉴스 본문 선택자 - articleBody 속성을 가진 요소 찾기
    const contentSelector = '.text_area[itemprop="articleBody"], .main_text .text_area[itemprop="articleBody"]';
    const contentElement = $(contentSelector);
    
    if (contentElement.length > 0) {
      // 모든 텍스트를 순서대로 추출
      let text = '';
      contentElement.contents().each((index, element) => {
        text += extractTextFromNode($, element);
      });
      
      // 텍스트 정리
      text = text
        .replace(/\s+/g, ' ')  // 연속된 공백을 하나로
        .replace(/\n\s*\n/g, '\n') // 빈 줄 제거
        .replace(/\n+/g, '\n') // 연속된 줄바꿈을 하나로
        .trim();
      
      return text;
    }
    
    // articleBody가 없는 경우 대체 선택자 시도
    const alternativeSelectors = [
      '.main_text .text_area',
      '.article_body',
      '.content_body',
      '.news_content'
    ];
    
    for (const selector of alternativeSelectors) {
      const element = $(selector);
      if (element.length > 0) {
        let text = '';
        element.contents().each((index, childElement) => {
          text += extractTextFromNode($, childElement);
        });
        
        text = text
          .replace(/\s+/g, ' ')
          .replace(/\n\s*\n/g, '\n')
          .replace(/\n+/g, '\n')
          .trim();
        
        if (text.length > 100) { // 의미있는 텍스트가 있는 경우
          return text;
        }
      }
    }
    
    return '';
  } catch (error) {
    console.error('뉴스 본문 추출 중 오류:', error);
    return '';
  }
}

/**
 * HTML에서 특정 선택자의 텍스트를 추출하는 함수
 * @param html HTML 문자열
 * @param selector CSS 선택자
 * @returns string 추출된 텍스트
 */
export function extractTextBySelector(html: string, selector: string): string {
  const $ = cheerio.load(html);
  const element = $(selector);
  
  if (element.length > 0) {
    let text = '';
    element.contents().each((index, childElement) => {
      text += extractTextFromNode($, childElement);
    });
    
    return text
      .replace(/\s+/g, ' ')
      .replace(/\n\s*\n/g, '\n')
      .replace(/\n+/g, '\n')
      .trim();
  }
  
  return '';
} 