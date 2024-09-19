import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _emailController = TextEditingController();
  final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
  }

  _sendData() async {
    String email = _emailController.text.trim();

    // if (email.isNotEmpty) {
    //   NotificationSettings settings = await messaging.requestPermission(
    //     alert: true,
    //     badge: true,
    //     sound: true,
    //   );

    // if (settings.authorizationStatus == AuthorizationStatus.authorized ||
    //     settings.authorizationStatus == AuthorizationStatus.provisional) {
    String? deviceToken = await messaging.getToken();

    await _firebaseFirestore.collection('users').doc(email).set({
      'email': email,
      'deviceToken': deviceToken,
    });
    // }
    // }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Column(
        children: [
          TextFormField(
            controller: _emailController,
          ),
          // TextFormField(),
          TextButton(onPressed: _sendData, child: const Text('send data'))
        ],
      ),
    );
  }
}
