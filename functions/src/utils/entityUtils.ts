import { Entity } from "../models/news";

/**
 * 엔터티 타입별 표시명
 */
export const ENTITY_TYPE_NAMES = {
  PERSON: '인명',
  COUNTRY: '국가',
  ORGANIZATION: '기관',
  LOCATION: '장소',
  COMPANY: '회사명'
};

/**
 * 엔터티 정보를 간단한 리스트로 변환하는 함수
 * @param entities 엔터티 배열
 * @returns 엔터티 정보 리스트
 */
export function getEntitiesList(entities: Entity[]): Array<{
  text: string;
  type: string;
  description: string;
}> {
  if (!entities || entities.length === 0) {
    return [];
  }

  return entities.map(entity => ({
    text: entity.text,
    type: ENTITY_TYPE_NAMES[entity.type] || entity.type,
    description: entity.description
  }));
}

/**
 * 엔터티를 타입별로 그룹화하는 함수
 * @param entities 엔터티 배열
 * @returns 타입별로 그룹화된 엔터티
 */
export function groupEntitiesByType(entities: Entity[]): Record<string, Entity[]> {
  const grouped: Record<string, Entity[]> = {};
  
  for (const entity of entities) {
    if (!grouped[entity.type]) {
      grouped[entity.type] = [];
    }
    grouped[entity.type].push(entity);
  }
  
  return grouped;
}

/**
 * 엔터티 정보를 JSON 형태로 반환하는 함수
 * @param entities 엔터티 배열
 * @returns JSON 형태의 엔터티 정보
 */
export function getEntitiesAsJSON(entities: Entity[]): string {
  if (!entities || entities.length === 0) {
    return '[]';
  }

  const entitiesList = entities.map(entity => ({
    text: entity.text,
    type: ENTITY_TYPE_NAMES[entity.type] || entity.type,
    description: entity.description
  }));

  return JSON.stringify(entitiesList, null, 2);
}

/**
 * 엔터티 통계 정보를 반환하는 함수
 * @param entities 엔터티 배열
 * @returns 엔터티 통계 정보
 */
export function getEntitiesStats(entities: Entity[]): {
  total: number;
  byType: Record<string, number>;
} {
  if (!entities || entities.length === 0) {
    return { total: 0, byType: {} };
  }

  const byType: Record<string, number> = {};
  
  for (const entity of entities) {
    const typeName = ENTITY_TYPE_NAMES[entity.type] || entity.type;
    byType[typeName] = (byType[typeName] || 0) + 1;
  }

  return {
    total: entities.length,
    byType
  };
} 