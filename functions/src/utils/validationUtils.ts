import { NewsItem } from "../models/news";
import { isValidUrl, safeTrim } from "./stringUtils";

/**
 * 데이터 검증 관련 유틸리티 함수들
 */

/**
 * 뉴스 아이템이 유효한지 검증
 * @param item 검증할 뉴스 아이템
 * @returns boolean 유효성 여부
 */
export function isValidNewsItem(item: any): item is NewsItem {
  if (!item || typeof item !== 'object') return false;
  
  // 필수 필드 검증
  if (!safeTrim(item.title)) return false;
  if (!safeTrim(item.link)) return false;
  if (!isValidUrl(item.link)) return false;
  if (!safeTrim(item.guid)) return false;
  
  return true;
}

/**
 * 뉴스 아이템 배열이 유효한지 검증
 * @param items 검증할 뉴스 아이템 배열
 * @returns boolean 유효성 여부
 */
export function isValidNewsItems(items: any[]): items is NewsItem[] {
  if (!Array.isArray(items)) return false;
  
  return items.every(item => isValidNewsItem(item));
}

/**
 * 숫자가 유효한 범위 내에 있는지 확인
 * @param value 확인할 값
 * @param min 최소값
 * @param max 최대값
 * @returns boolean 유효성 여부
 */
export function isInRange(value: number, min: number, max: number): boolean {
  return value >= min && value <= max;
}

/**
 * 객체가 비어있는지 확인
 * @param obj 확인할 객체
 * @returns boolean 비어있는지 여부
 */
export function isEmptyObject(obj: any): boolean {
  return obj && typeof obj === 'object' && Object.keys(obj).length === 0;
}

/**
 * 배열이 비어있는지 확인
 * @param arr 확인할 배열
 * @returns boolean 비어있는지 여부
 */
export function isEmptyArray(arr: any[]): boolean {
  return !Array.isArray(arr) || arr.length === 0;
} 