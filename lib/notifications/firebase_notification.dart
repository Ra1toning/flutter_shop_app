import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class FirebaseMessage {
  final firebaseMessaging = FirebaseMessaging.instance;

  Future<void> initNotification() async {
    await firebaseMessaging.requestPermission();
    final FCMtoken = await firebaseMessaging.getToken();
    debugPrint('FCMtoken: $FCMtoken');

    FirebaseMessaging.instance.getInitialMessage().then(handleNotification);
    FirebaseMessaging.onMessageOpenedApp.listen(handleNotification);
  }

  void handleNotification(RemoteMessage? message) {
    if (message == null) return;

    debugPrint('Message title: ${message.notification?.title.toString()}');
    debugPrint('Message body: ${message.notification?.body.toString()}');
  }
}
