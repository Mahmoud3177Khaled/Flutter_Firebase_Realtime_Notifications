// lib/services/notification_service.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';   // Add this for kIsWeb
import 'package:notification_inbox_app/models/notification_model.dart';

class NotificationService {
  static final FirebaseMessaging messaging = FirebaseMessaging.instance;

  static final FirebaseDatabase db = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    // databaseURL: 'https://realtime-notification-app-default-rtdb.firebaseio.com',
  );

  static String normalizeUsername(String username) {
    return "user_${username.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '')}";
  }

  static Future<void> subscribeToTopic(String username) async {
    String topic = normalizeUsername(username);
    await messaging.subscribeToTopic(topic);
  }

  //i skipped unsubscribeFromTopic because its not supported on web, so i limmited calling it to when the app is build on android;
  static Future<void> unsubscribeFromTopic(String username) async {
    if (kIsWeb) {
      return;
    }

    String topic = normalizeUsername(username);
    // await messaging.unsubscribeFromTopic(topic);
  }

  static Future<void> saveNotification(String username, RemoteMessage message) async {
    try {
      String topic = normalizeUsername(username);

      final notification = AppNotification(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: message.notification?.title ?? message.data['title'] ?? 'No Title',
        body: message.notification?.body ?? message.data['body'] ?? 'No Body',
        receivedAt: DateTime.now().millisecondsSinceEpoch,
      );

      final dbref = db.ref('notifications/$topic').push();
      await dbref.set(notification.toMap());

      print("✅ Notification saved under: $topic");
    } catch (e) {
      print("❌ Error saving notification: $e");
    }
  }

  static DatabaseReference getNotificationsRef(String username) {
    String topic = normalizeUsername(username);
    return db.ref('notifications/$topic');
  }
}