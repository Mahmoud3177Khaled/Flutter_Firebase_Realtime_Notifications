import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'home_screen.dart';

class LoginScreen extends StatelessWidget {
  LoginScreen({super.key});

  final TextEditingController usernameController = TextEditingController();

  Future<void> login() async {

    String username = usernameController.text.trim();

    if (username.isEmpty) {
      Get.snackbar('Error', 'Please enter a username', snackPosition: SnackPosition.TOP);
      return;
    }

    Get.off(() => HomeScreen(username: username));   // GetX navigation
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notification Inbox')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.notifications_active, size: 100, color: Colors.deepPurple),
            const SizedBox(height: 30),
            const Text('Enter your username to start', style: TextStyle(fontSize: 20)),
            const SizedBox(height: 20),
            TextField(
              controller: usernameController,
              decoration: const InputDecoration(
                labelText: 'Username',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: login,
              child: const Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}