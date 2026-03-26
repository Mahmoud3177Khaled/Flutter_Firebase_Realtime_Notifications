import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
  final RxList<AppNotification> notifications = <AppNotification>[].obs;

  StreamSubscription<RemoteMessage>? _messageSubscription;

  @override
  void initState() {
    super.initState();
    _setupMessaging();
    _loadNotifications();
  }

  Future<void> _setupMessaging() async {
    await FirebaseMessaging.instance.requestPermission();

    // Subscribe to current user's topic
    await NotificationService.subscribeToTopic(widget.username);

    // Listen to foreground messages → Only save for current user
    _messageSubscription = FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      print("Foreground notification received for ${widget.username}");

      // Save only for the current logged-in user
      await NotificationService.saveNotification(widget.username, message);

      _loadNotifications();

      Get.snackbar(
        message.notification?.title ?? 'New Notification',
        message.notification?.body ?? '',
        snackPosition: SnackPosition.TOP,
      );
    });
  }

  void _loadNotifications() {
    final ref = NotificationService.getNotificationsRef(widget.username);

    ref.onValue.listen((DatabaseEvent event) {
      final data = event.snapshot.value;
      if (data == null) {
        notifications.clear();
        return;
      }

      final List<AppNotification> loaded = [];
      (data as Map).forEach((key, value) {
        loaded.add(AppNotification.fromMap(key, value));
      });

      loaded.sort((a, b) => b.receivedAt.compareTo(a.receivedAt));
      notifications.assignAll(loaded);
    });
  }

  Future<void> _logout() async {
    // Cancel the listener before logout
    _messageSubscription?.cancel();

    await NotificationService.unsubscribeFromTopic(widget.username);

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('username');

    Get.offAll(() => LoginScreen());
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    return Scaffold(
      appBar: AppBar(
        title: Text('Inbox - ${widget.username}'),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: Obx(() => notifications.isEmpty
          ? const Center(
              child: Text(
                'No notifications yet.\nSend one from Firebase Console!',
                textAlign: TextAlign.center,
              ),
            )
          : ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notif = notifications[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: ListTile(
                    leading: const Icon(Icons.notifications, color: Colors.deepPurple),
                    title: Text(notif.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(notif.body),
                    trailing: Text(
                      dateFormat.format(DateTime.fromMillisecondsSinceEpoch(notif.receivedAt)),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                );
              },
            )),
    );
  }
}