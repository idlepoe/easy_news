/**
 * 문자열 관련 유틸리티 함수들
 */

/**
 * 문자열을 안전하게 trim하고 빈 문자열인 경우 기본값 반환
 * @param str 원본 문자열
 * @param defaultValue 기본값 (기본값: "")
 * @returns string 처리된 문자열
 */
export function safeTrim(str: string | undefined | null, defaultValue: string = ""): string {
  if (!str) return defaultValue;
  const trimmed = str.trim();
  return trimmed || defaultValue;
}

/**
 * 문자열이 유효한 URL인지 확인
 * @param url 확인할 URL 문자열
 * @returns boolean 유효성 여부
 */
export function isValidUrl(url: string): boolean {
  try {
    new URL(url);
    return true;
  } catch {
    return false;
  }
}

/**
 * 문자열에서 HTML 태그 제거
 * @param html HTML 문자열
 * @returns string 태그가 제거된 문자열
 */
export function stripHtmlTags(html: string): string {
  return html.replace(/<[^>]*>/g, '');
}

/**
 * 문자열을 지정된 길이로 자르고 말줄임표 추가
 * @param str 원본 문자열
 * @param maxLength 최대 길이
 * @returns string 잘린 문자열
 */
export function truncateString(str: string, maxLength: number): string {
  if (str.length <= maxLength) return str;
  return str.substring(0, maxLength) + '...';
}

/**
 * 문자열에서 특수문자 제거
 * @param str 원본 문자열
 * @returns string 특수문자가 제거된 문자열
 */
export function removeSpecialCharacters(str: string): string {
  return str.replace(/[^\w\s가-힣]/g, '');
} 