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
    
    // SBS 뉴스 본문 선택자
    const contentSelector = '.main_text .text_area[itemprop="articleBody"]';
    const contentElement = $(contentSelector);
    
    if (contentElement.length > 0) {
      // br 태그를 \n으로 변환한 후 텍스트 추출
      let html = contentElement.html() || '';
      html = html.replace(/<br\s*\/?>/gi, '\n'); // <br>, <br/>, <br /> 모두 처리
      
      // 변환된 HTML에서 텍스트 추출
      const $temp = cheerio.load(html);
      let text = $temp('body').text()
        .replace(/\s+/g, ' ')  // 연속된 공백을 하나로
        .replace(/\n+/g, '\n') // 연속된 줄바꿈을 하나로
        .trim();
      
      return text;
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
    return element.text()
      .replace(/\s+/g, ' ')
      .replace(/\n+/g, '\n')
      .trim();
  }
  
  return '';
} 