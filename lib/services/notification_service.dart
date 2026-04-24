import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static Future<void> init() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onMessage.listen((message) {
      debugPrint(
        'FCM foreground: ${message.notification?.title} - ${message.notification?.body}',
      );
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint('FCM app opened from notification: ${message.messageId}');
    });

    _messaging.onTokenRefresh.listen((newToken) {
      saveToken(token: newToken);
    });
  }

  static Future<void> saveToken({String? token}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final fcmToken = token ?? await _messaging.getToken();
    if (fcmToken == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .set({'fcmToken': fcmToken}, SetOptions(merge: true));

    debugPrint('FCM token saved for ${user.email}: $fcmToken');
  }
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('FCM background: ${message.notification?.title}');
}
