import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:notification_inbox_app/models/notification_model.dart';
import 'package:notification_inbox_app/screens/login_screen.dart';
import 'package:notification_inbox_app/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  final String username;

  const HomeScreen({super.key, required this.username});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<AppNotification> _notifications = [];
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  @override
  void initState() {
    super.initState();
    _setupMessaging();
    _loadNotifications();
  }

  Future<void> _setupMessaging() async {
    // Request permission
    await _messaging.requestPermission();

    // Subscribe to topic
    await NotificationService.subscribeToTopic(widget.username);

    // Foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      print("Foreground notification received");
      await NotificationService.saveNotification(widget.username, message);

      // Refresh list
      _loadNotifications();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message.notification?.title ?? 'New Notification')),
      );
    });

    // When notification is tapped (app in background)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _loadNotifications();
    });
  }

  void _loadNotifications() {
    final ref = NotificationService.getNotificationsRef(widget.username);

    ref.onValue.listen((DatabaseEvent event) {
      final data = event.snapshot.value;
      if (data == null) {
        setState(() => _notifications = []);
        return;
      }

      final List<AppNotification> loaded = [];
      (data as Map).forEach((key, value) {
        loaded.add(AppNotification.fromMap(key, value));
      });

      // Sort by received time (newest first)
      loaded.sort((a, b) => b.receivedAt.compareTo(a.receivedAt));

      setState(() => _notifications = loaded);
    });
  }

  Future<void> _logout() async {
    await NotificationService.unsubscribeFromTopic(widget.username);

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('username');

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    return Scaffold(
      appBar: AppBar(
        title: Text('Inbox - ${widget.username}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _notifications.isEmpty
          ? const Center(
              child: Text(
                'No notifications yet.\nSend one from Firebase Console!',
                textAlign: TextAlign.center,
              ),
            )
          : ListView.builder(
              itemCount: _notifications.length,
              itemBuilder: (context, index) {
                final notif = _notifications[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: ListTile(
                    leading: const Icon(Icons.notifications, color: Colors.deepPurple),
                    title: Text(
                      notif.title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(notif.body),
                    trailing: Text(
                      dateFormat.format(DateTime.fromMillisecondsSinceEpoch(notif.receivedAt)),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                );
              },
            ),
    );
  }
}