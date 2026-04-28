import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:notification_inbox_app/models/notification_model.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final DatabaseReference dbRef = FirebaseDatabase.instance.ref('notifications');
  List<AppNotification> allNotifications = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllNotifications();
  }

  void _loadAllNotifications() {
    dbRef.onValue.listen((DatabaseEvent event) {
      final data = event.snapshot.value;
      final List<AppNotification> loaded = [];

      if (data != null) {
        (data as Map).forEach((userKey, userNotifications) {
          (userNotifications as Map).forEach((notifId, notifData) {
            loaded.add(AppNotification.fromMap(notifId, notifData));
          });
        });
      }

      loaded.sort((a, b) => b.receivedAt.compareTo(a.receivedAt));

      setState(() {
        allNotifications = loaded;
        isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    return Scaffold(
      appBar: AppBar(title: const Text('All Notifications History')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : allNotifications.isEmpty
              ? const Center(child: Text('No notifications yet'))
              : ListView.builder(
                  itemCount: allNotifications.length,
                  itemBuilder: (context, index) {
                    final notif = allNotifications[index];
                    return Card(
                      margin: const EdgeInsets.all(8),
                      child: ListTile(
                        leading: const Icon(Icons.notifications, color: Colors.orange),
                        title: Text(notif.title, style: const TextStyle(fontWeight: FontWeight.bold)),
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