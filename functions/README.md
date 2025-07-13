# SBS 뉴스 스케줄러

SBS 뉴스 RSS 피드에서 1시간마다 뉴스 데이터를 자동으로 가져와서 Firestore에 저장하는 Firebase Functions 프로젝트입니다.

## 기능

- **자동 스케줄링**: 1시간마다 SBS 뉴스 RSS 피드를 자동으로 가져옵니다
- **중복 제거**: 기존 뉴스는 업데이트하고 새로운 뉴스만 추가합니다
- **에러 처리**: 네트워크 오류나 파싱 오류에 대한 적절한 처리
- **수동 실행**: HTTP 엔드포인트를 통한 수동 뉴스 가져오기 기능

## 설치 및 설정

### 1. 의존성 설치
```bash
npm install
```

### 2. Firebase 프로젝트 설정
Firebase 프로젝트가 설정되어 있어야 합니다. 다음 명령어로 Firebase CLI를 통해 프로젝트를 초기화하세요:

```bash
firebase init functions
```

### 3. Firestore 데이터베이스 설정
Firebase Console에서 Firestore 데이터베이스를 생성하고 보안 규칙을 설정하세요.

## 배포

```bash
npm run deploy
```

## 함수 설명

### 1. sbsNewsScheduler
- **트리거**: 1시간마다 자동 실행
- **기능**: SBS 뉴스 RSS 피드에서 뉴스 데이터를 가져와서 Firestore에 저장
- **스케줄**: 매시간 실행 (한국 시간대 기준)
- **재시도**: 최대 3회

### 2. fetchNewsManually
- **트리거**: HTTP 요청
- **기능**: 수동으로 뉴스 데이터를 가져와서 저장
- **사용법**: `POST /fetchNewsManually`

## Firestore 데이터 구조

뉴스 데이터는 `news` 컬렉션에 저장되며, 각 문서는 다음과 같은 구조를 가집니다:

```typescript
interface NewsItem {
  title: string;        // 뉴스 제목
  link: string;         // 뉴스 링크
  description: string;  // 뉴스 설명
  pubDate: string;      // 발행일
  guid: string;         // 고유 식별자 (문서 ID로 사용)
  category?: string;    // 카테고리 (선택사항)
  createdAt: Timestamp; // 생성 시간
  updatedAt: Timestamp; // 업데이트 시간
}
```

## 중복 제거 로직

- `guid` 필드를 문서 ID로 사용하여 중복을 방지합니다
- 기존 문서가 있는 경우 `merge: true` 옵션으로 업데이트합니다
- 새로운 문서는 `createdAt`과 `updatedAt` 타임스탬프를 추가합니다

## 로깅

모든 함수는 Firebase Functions 로그를 통해 실행 상태를 추적할 수 있습니다:

```bash
firebase functions:log
```

## 환경 변수

현재는 하드코딩된 RSS URL을 사용하지만, 필요에 따라 환경 변수로 설정할 수 있습니다:

```typescript
const RSS_URL = process.env.SBS_RSS_URL || "https://news.sbs.co.kr/news/newsflashRssFeed.do?plink=RSSREADER";
```

## 문제 해결

### 1. RSS 피드 접근 오류
- 네트워크 연결 확인
- User-Agent 헤더 설정 확인
- 타임아웃 설정 조정

### 2. Firestore 권한 오류
- Firebase Console에서 Firestore 보안 규칙 확인
- 서비스 계정 권한 확인

### 3. 스케줄러 실행 오류
- Firebase Functions 로그 확인
- 스케줄 설정 확인 (`every 1 hours`)

## 개발

### 로컬 테스트
```bash
npm run serve
```

### 빌드
```bash
npm run build
```

## 라이선스

MIT License 