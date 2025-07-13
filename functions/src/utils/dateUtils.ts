/**
 * 날짜 관련 유틸리티 함수들
 */

/**
 * 현재 시간을 ISO 문자열로 반환
 * @returns string ISO 형식의 현재 시간
 */
export function getCurrentISODate(): string {
  return new Date().toISOString();
}

/**
 * 날짜 문자열을 한국 시간대로 변환
 * @param dateString 날짜 문자열
 * @returns string 한국 시간대 형식의 날짜
 */
export function convertToKoreaTime(dateString: string): string {
  const date = new Date(dateString);
  return date.toLocaleString('ko-KR', { timeZone: 'Asia/Seoul' });
}

/**
 * 날짜가 유효한지 확인
 * @param dateString 날짜 문자열
 * @returns boolean 유효성 여부
 */
export function isValidDate(dateString: string): boolean {
  const date = new Date(dateString);
  return !isNaN(date.getTime());
}

/**
 * 두 날짜 간의 차이를 시간 단위로 계산
 * @param date1 첫 번째 날짜
 * @param date2 두 번째 날짜
 * @returns number 시간 차이 (시간 단위)
 */
export function getHoursDifference(date1: Date, date2: Date): number {
  const diffInMs = Math.abs(date2.getTime() - date1.getTime());
  return Math.floor(diffInMs / (1000 * 60 * 60));
} 