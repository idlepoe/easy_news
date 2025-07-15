import * as admin from "firebase-admin";

// Firebase Admin 초기화
admin.initializeApp();

// 스케줄러 함수만 export
export { sbsNewsScheduler } from './schedule/sbsNewsScheduler';
export { fcmNewsScheduler, fcmTestAPI } from './schedule/fcmScheduler';
export { fetchNewsManually, getNewsListAPI, getNewsDetailAPI, updateNewsViewCountAPI } from './schedule/httpFunctions';

// utils export (내부 사용용)
export * from './utils/htmlUtils';
