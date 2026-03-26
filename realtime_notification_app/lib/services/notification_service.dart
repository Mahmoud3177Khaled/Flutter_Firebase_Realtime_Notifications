import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:notification_inbox_app/models/notification_model.dart';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FirebaseDatabase _database = FirebaseDatabase.instance;

  static String _normalizeUsername(String username) {
    return "user_${username.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '')}";
  }

  static Future<void> subscribeToTopic(String username) async {
    String topic = _normalizeUsername(username);
    await _messaging.subscribeToTopic(topic);
    print("✅ Subscribed to topic: $topic");
  }

  static Future<void> unsubscribeFromTopic(String username) async {
    String topic = _normalizeUsername(username);
    await _messaging.unsubscribeFromTopic(topic);
    print("✅ Unsubscribed from topic: $topic");
  }

  static Future<void> saveNotification(String username, RemoteMessage message) async {
    try {
      String topic = _normalizeUsername(username);

      String title = message.notification?.title ??
          message.data['title'] ??
          message.data['notification_title'] ??
          'No Title';

      String body = message.notification?.body ??
          message.data['body'] ??
          message.data['notification_body'] ??
          'No Body';

      final notification = AppNotification(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        body: body,
        receivedAt: DateTime.now().millisecondsSinceEpoch,
      );

      final ref = _database.ref('notifications/$topic').push();
      await ref.set(notification.toMap());

      print("✅ SUCCESS: Notification SAVED → $topic");
    } catch (e) {
      print("❌ ERROR saving notification: $e");
    }
  }

  static DatabaseReference getNotificationsRef(String username) {
    String topic = _normalizeUsername(username);
    return _database.ref('notifications/$topic');
  }
}