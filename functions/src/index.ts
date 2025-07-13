/**
 * Import function triggers from their respective submodules:
 *
 * import {onCall} from "firebase-functions/v2/https";
 * import {onDocumentWritten} from "firebase-functions/v2/firestore";
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

import * as admin from "firebase-admin";

// Firebase Admin 초기화
admin.initializeApp();

// 스케줄러 함수만 export
export { sbsNewsScheduler } from './schedule/sbsNewsScheduler';
export { fetchNewsManually } from './schedule/httpFunctions';

// utils export (내부 사용용)
export * from './utils/htmlUtils';
