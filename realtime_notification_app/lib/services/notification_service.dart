import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:notification_inbox_app/models/notification_model.dart';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FirebaseDatabase _database = FirebaseDatabase.instance;

  // Subscribe to user topic
  static Future<void> subscribeToTopic(String username) async {
    String topic = _normalizeUsername(username);
    await _messaging.subscribeToTopic(topic);
    print("Subscribed to topic: $topic");
  }

  // Unsubscribe from topic
  static Future<void> unsubscribeFromTopic(String username) async {
    String topic = _normalizeUsername(username);
    await _messaging.unsubscribeFromTopic(topic);
    print("Unsubscribed from topic: $topic");
  }

  static String _normalizeUsername(String username) {
    return "user_${username.trim().toLowerCase().replaceAll(' ', '')}";
  }

  // Save notification to Realtime Database
  static Future<void> saveNotification(String username, RemoteMessage message) async {
    String topic = _normalizeUsername(username);

    final notification = AppNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: message.notification?.title ?? message.data['title'] ?? 'No Title',
      body: message.notification?.body ?? message.data['body'] ?? 'No Body',
      receivedAt: DateTime.now().millisecondsSinceEpoch,
    );

    final ref = _database.ref('notifications/$topic').push();
    await ref.set(notification.toMap());
    print("Notification saved to database");
  }

  // Listen to realtime notifications for inbox
  static DatabaseReference getNotificationsRef(String username) {
    String topic = _normalizeUsername(username);
    return _database.ref('notifications/$topic');
  }
}