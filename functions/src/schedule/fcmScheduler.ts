import { onSchedule } from 'firebase-functions/v2/scheduler';
import { onRequest } from 'firebase-functions/v2/https';
import { logger } from 'firebase-functions/v2';
import { getFirestore } from 'firebase-admin/firestore';
import { getMessaging } from 'firebase-admin/messaging';

const db = getFirestore();
const messaging = getMessaging();

/**
 * 한국시간 기준으로 현재 시간을 가져오는 함수
 */
function getKoreaTime(): Date {
  const now = new Date();
  // UTC+9 (한국시간)
  const koreaTime = new Date(now.getTime() + (9 * 60 * 60 * 1000));
  return koreaTime;
}

/**
 * 3시간마다 실행되는 FCM 스케줄러
 * 최신 뉴스 중 아직 발송하지 않은 항목의 3줄요약을 summary3lines 토픽으로 발송
 */
export const fcmNewsScheduler = onSchedule(
  {
    schedule: '0 */3 * * *', // 3시간마다 실행 (매시 0분)
    timeZone: 'Asia/Seoul',
    timeoutSeconds: 300,
  },
  async (event) => {
    try {
      logger.info('FCM 뉴스 스케줄러 시작');
      
      // 한국시간 기준으로 현재 시간 확인
      const koreaTime = getKoreaTime();
      const currentHour = koreaTime.getHours();
      
      logger.info(`현재 한국시간: ${koreaTime.toLocaleString('ko-KR', { timeZone: 'Asia/Seoul' })}`);
      
      if (currentHour < 6 || currentHour >= 21) {
        logger.info(`현재 시간 ${currentHour}시는 알림 발송 시간이 아닙니다. (06:00~21:00만 발송)`);
        return;
      }
      
      // 최신 뉴스 중 아직 발송하지 않은 항목 조회
      const newsQuery = db.collection('news')
        .where('isSend', '!=', true)
        .orderBy('isSend', 'desc')
        .orderBy('pubDate', 'desc')
        .limit(1);
      
      const newsSnapshot = await newsQuery.get();
      
      if (newsSnapshot.empty) {
        logger.info('발송할 새로운 뉴스가 없습니다.');
        return;
      }
      
      const newsDoc = newsSnapshot.docs[0];
      const newsData = newsDoc.data();
      const newsId = newsDoc.id;
      
      // easySummary 있는지 확인
      if (!newsData.easySummary || newsData.easySummary.trim() === '') {
        logger.warn(`뉴스 ${newsId}에 easySummary가 없습니다.`);
        return;
      }
      
      // 뉴스 제목과 내용 분리
      const title = newsData.title || '인기뉴스';
      const summary = newsData.easySummary;
      
      // 이미지 URL 설정 (뉴스 이미지가 있으면 사용, 없으면 포함하지 않음)
      const imageUrl = newsData.mediaUrl;
      
      if (imageUrl) {
        logger.info(`이미지 URL: ${imageUrl}`);
      } else {
        logger.info('이미지 URL이 없습니다. 이미지 없이 발송합니다.');
      }
      
      // FCM 메시지 구성
      const message: any = {
        topic: 'summary3lines',
        notification: {
          title: `📰 ${title}`,
          body: summary,
        },
        data: {
          newsId: newsId,
          type: 'news_summary',
          timestamp: koreaTime.toISOString(),
          title: title,
          summary: summary,
        },
        android: {
          notification: {
            icon: 'ic_notification_removebg', // 새로운 아이콘 사용
            channelId: 'news_summary',
            priority: 'high' as const,
            title: `📰 ${title}`,
            body: summary,
            clickAction: 'FLUTTER_NOTIFICATION_CLICK',
            defaultSound: true,
            defaultVibrateTimings: true,
            visibility: 'public' as const,
            notificationCount: 1,
          },
          data: {
            newsId: newsId,
            type: 'news_summary',
            timestamp: koreaTime.toISOString(),
            title: title,
            summary: summary,
          },
        },
        apns: {
          payload: {
            aps: {
              badge: 1,
              sound: 'default',
              category: 'NEWS_SUMMARY',
              'mutable-content': 1,
              'content-available': 1,
              alert: {
                title: `📰 ${title}`,
                body: summary,
              },
            },
          },
        },
        webpush: {
          notification: {
            title: `📰 ${title}`,
            body: summary,
            tag: 'news_summary',
            requireInteraction: true,
            actions: [
              {
                action: 'view',
                title: '보기',
              },
            ],
          },
          fcm_options: {
            link: `/news/${newsId}`,
          },
        },
      };

      // 이미지가 있으면 추가
      if (imageUrl) {
        message.notification.imageUrl = imageUrl;
        message.data.imageUrl = imageUrl;
        message.android.notification.imageUrl = imageUrl;
        message.android.data.imageUrl = imageUrl;
        message.apns.payload.fcm_options = { image: imageUrl };
        message.webpush.notification.image = imageUrl;
      }
      
      // FCM 메시지 발송
      const response = await messaging.send(message);
      logger.info(`FCM 메시지 발송 성공: ${response}`);
      
      // 해당 뉴스의 isSend를 true로 업데이트
      await newsDoc.ref.update({
        isSend: true,
        sendAt: koreaTime,
      });
      
      logger.info(`뉴스 ${newsId}의 3줄요약 FCM 발송 완료 (한국시간: ${koreaTime.toLocaleString('ko-KR', { timeZone: 'Asia/Seoul' })})`);
      
    } catch (error) {
      logger.error('FCM 뉴스 스케줄러 실행 중 오류:', error);
      throw error;
    }
  }
);

/**
 * 테스트용 FCM 발송 API
 * GET 요청으로 즉시 FCM 발송 (isSend 업데이트하지 않음)
 */
export const fcmTestAPI = onRequest(
  {
    cors: true,
    timeoutSeconds: 60,
  },
  async (req, res) => {
    try {
      // GET 요청만 허용
      if (req.method !== 'GET') {
        res.status(405).json({ error: 'Method not allowed. Use GET.' });
        return;
      }

      logger.info('테스트용 FCM 발송 API 호출');
      
      // 한국시간 기준으로 현재 시간
      const koreaTime = getKoreaTime();
      logger.info(`현재 한국시간: ${koreaTime.toLocaleString('ko-KR', { timeZone: 'Asia/Seoul' })}`);
      
      // 최신 뉴스 1개 조회 (isSend 상태와 관계없이)
      const newsQuery = db.collection('news')
        .orderBy('pubDate', 'desc')
        .limit(1);
      
      const newsSnapshot = await newsQuery.get();
      
      if (newsSnapshot.empty) {
        logger.info('발송할 뉴스가 없습니다.');
        res.status(404).json({ error: '발송할 뉴스가 없습니다.' });
        return;
      }
      
      const newsDoc = newsSnapshot.docs[0];
      const newsData = newsDoc.data();
      const newsId = newsDoc.id;
      
      // easySummary 있는지 확인
      if (!newsData.easySummary || newsData.easySummary.trim() === '') {
        logger.warn(`뉴스 ${newsId}에 summary3lines가 없습니다.`);
        res.status(400).json({ error: '뉴스에 summary3lines가 없습니다.' });
        return;
      }
      
      // 뉴스 제목과 내용 분리
      const title = newsData.title || '테스트 뉴스';
      const summary = newsData.easySummary;
      
      // 이미지 URL 설정 (뉴스 이미지가 있으면 사용, 없으면 포함하지 않음)
      const imageUrl = newsData.mediaUrl;
      
      if (imageUrl) {
        logger.info(`테스트 이미지 URL: ${imageUrl}`);
      } else {
        logger.info('테스트 이미지 URL이 없습니다. 이미지 없이 발송합니다.');
      }
      
      // FCM 메시지 구성 (테스트용)
      const message: any = {
        topic: 'summary3lines',
        notification: {
          title: `🧪 테스트 - ${title}`,
          body: summary,
        },
        data: {
          newsId: newsId,
          type: 'news_summary_test',
          timestamp: koreaTime.toISOString(),
          isTest: 'true',
          title: title,
          summary: summary,
        },
        android: {
          notification: {
            icon: 'ic_notification_removebg', // 새로운 아이콘 사용
            channelId: 'news_summary',
            priority: 'high' as const,
            title: `🧪 테스트 - ${title}`,
            body: summary,
            clickAction: 'FLUTTER_NOTIFICATION_CLICK',
            defaultSound: true,
            defaultVibrateTimings: true,
            visibility: 'public' as const,
            notificationCount: 1,
          },
          data: {
            newsId: newsId,
            type: 'news_summary_test',
            timestamp: koreaTime.toISOString(),
            isTest: 'true',
            title: title,
            summary: summary,
          },
        },
        apns: {
          payload: {
            aps: {
              badge: 1,
              sound: 'default',
              category: 'NEWS_SUMMARY_TEST',
              'mutable-content': 1,
              'content-available': 1,
              alert: {
                title: `🧪 테스트 - ${title}`,
                body: summary,
              },
            },
          },
        },
        webpush: {
          notification: {
            title: `🧪 테스트 - ${title}`,
            body: summary,
            icon: 'https://firebasestorage.googleapis.com/v0/b/easy-news-12345.appspot.com/o/default%2Fapp_icon.png?alt=media',
            badge: 'https://firebasestorage.googleapis.com/v0/b/easy-news-12345.appspot.com/o/default%2Fbadge.png?alt=media',
            tag: 'news_summary_test',
            requireInteraction: true,
            actions: [
              {
                action: 'view',
                title: '보기',
              },
            ],
          },
          fcm_options: {
            link: `/news/${newsId}`,
          },
        },
      };

      // 이미지가 있으면 추가
      if (imageUrl) {
        message.notification.imageUrl = imageUrl;
        message.data.imageUrl = imageUrl;
        message.android.notification.imageUrl = imageUrl;
        message.android.data.imageUrl = imageUrl;
        message.apns.payload.fcm_options = { image: imageUrl };
        message.webpush.notification.image = imageUrl;
      }
      
      // FCM 메시지 발송
      const response = await messaging.send(message);
      logger.info(`테스트용 FCM 메시지 발송 성공: ${response}`);
      
      // isSend는 업데이트하지 않음 (테스트용이므로)
      logger.info(`테스트용 뉴스 ${newsId}의 3줄요약 FCM 발송 완료 (isSend 미업데이트)`);
      
      // 성공 응답
      res.status(200).json({
        success: true,
        message: '테스트용 FCM 발송 완료',
        newsId: newsId,
        title: title,
        summary: summary,
        imageUrl: imageUrl,
        fcmResponse: response,
        timestamp: koreaTime.toISOString(),
        koreaTime: koreaTime.toLocaleString('ko-KR', { timeZone: 'Asia/Seoul' }),
      });
      
    } catch (error) {
      logger.error('테스트용 FCM 발송 API 실행 중 오류:', error);
      res.status(500).json({
        error: 'FCM 발송 중 오류가 발생했습니다.',
        details: error instanceof Error ? error.message : 'Unknown error',
      });
    }
  }
); 