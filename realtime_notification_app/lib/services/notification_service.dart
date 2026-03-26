import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:notification_inbox_app/models/notification_model.dart';

class NotificationService {
  static final FirebaseMessaging messaging = FirebaseMessaging.instance;
  static final FirebaseDatabase db = FirebaseDatabase.instance;

  static String normalizeUsername(String username) {
    return "user_${username.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '')}";  //regex to remove all whitespace (helped with ai)
  }

  static Future<void> subscribeToTopic(String username) async {

    String topic = normalizeUsername(username);
    await messaging.subscribeToTopic(topic);
    // print("subscribed to topic $topic");
  }

  static Future<void> unsubscribeFromTopic(String username) async {
    String topic = normalizeUsername(username);
    await messaging.unsubscribeFromTopic(topic);
    // print("unsubscribed from topic $topic");
  }

  static Future<void> saveNotification(String username, RemoteMessage message) async {

    try {
      String topic = normalizeUsername(username);

      // create notification model
      final notification = AppNotification(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: message.notification?.title ?? 'No Title',
        body: message.notification?.body ?? 'no body',
        receivedAt: DateTime.now().millisecondsSinceEpoch,
      );

      //save notification as map
      final dbref = db.ref('notifications/$topic').push();
      await dbref.set(notification.toMap());

      // print("Notification saved in $topic");
    } catch (e) {
      // print("error saving notification: $e");
    }
  }

  static DatabaseReference getNotificationsRef(String username) {
    String topic = normalizeUsername(username);
    return db.ref('notifications/$topic');
  }
}