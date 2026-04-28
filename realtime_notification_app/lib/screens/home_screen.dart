import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:notification_inbox_app/models/notification_model.dart';
import 'package:notification_inbox_app/screens/login_screen.dart';
import 'package:notification_inbox_app/services/notification_service.dart';

class HomeScreen extends StatefulWidget {
  final String username;

  const HomeScreen({super.key, required this.username});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final RxList<AppNotification> notifications = <AppNotification>[].obs;

  StreamSubscription<RemoteMessage>? messageSubscription;

  @override
  void initState() {
    super.initState();
    setupMessaging();
    loadNotifications();
  }

  Future<void> setupMessaging() async {
    await FirebaseMessaging.instance.requestPermission();

    //subscribe to topic
    await NotificationService.subscribeToTopic(widget.username);

    //listen for foreground notifications
    messageSubscription = FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      // print("Foreground notification received for ${widget.username}");

      //save when recieved
      await NotificationService.saveNotification(widget.username, message);

      //reload
      loadNotifications();

      //in app notification
      Get.snackbar(
        message.notification?.title ?? 'New Notification',
        message.notification?.body ?? '',
        snackPosition: SnackPosition.TOP,
      );

    });
  }

  void loadNotifications() {

    //listener for new notification for this user
    final ref = NotificationService.getNotificationsRef(widget.username);

    // load old notification, and listen for more
    ref.onValue.listen((DatabaseEvent event) {

      final data = event.snapshot.value;
      if (data == null) {
        notifications.clear();
        return;
      }

      final List<AppNotification> loaded = [];

      //populate the AppNotification list
      (data as Map).forEach((key, value) {
        loaded.add(AppNotification.fromMap(key, value));
      });

      loaded.sort((a, b) => b.receivedAt.compareTo(a.receivedAt));
      notifications.assignAll(loaded);

    });
  }

  Future<void> logout() async {
    //remove topic subscribtion
    messageSubscription?.cancel();
    await NotificationService.unsubscribeFromTopic(widget.username);

    Get.offAll(() => LoginScreen());
  }

  @override
  void dispose() {
    // make sure subscribtion is cancelled
    messageSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    return Scaffold(
      appBar: AppBar(
        title: Text('Inbox - ${widget.username}'),
        actions: [
        IconButton(
          icon: const Icon(Icons.history),
          onPressed: () => Get.toNamed('/history'),
          tooltip: 'All Notifications History',
        ),
        IconButton(icon: const Icon(Icons.logout), onPressed: logout),
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