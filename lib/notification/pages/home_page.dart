// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_firebase_notification/notification/pages/message_page.dart';
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
    _initializedNotification();
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('forground message: ${message.notification?.title}');
      _showNotification(
        message.notification?.title,
        message.notification?.body,
      );
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {});
  }

  _initializedNotification() async {
    const AndroidInitializationSettings androidInitializationSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: androidInitializationSettings);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    const AndroidNotificationChannel notificationChannel =
        AndroidNotificationChannel(
      'high_importance_channel', // id for the channel
      'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.high,
    );
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(notificationChannel);
  }

  void _showNotification(String? title, String? body) async {
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      "high importance_channer",
      "high importance Notification",
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      notificationDetails,
    );
  }

  _sendData() async {
    String email = _emailController.text.trim();

    if (email.isNotEmpty) {
      NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        String? deviceToken = await messaging.getToken();

        await _firebaseFirestore.collection('users').doc(email).set({
          'email': email,
          'deviceToken': deviceToken,
        });

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const MessagePage(),
          ),
        );
      } else {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Permission denied'),
            content: const Text(
                'You nedd to grant notifucation permission to proceed'),
            actions: [
              TextButton(
                onPressed: () {},
                child: const Text('Ok'),
              )
            ],
          ),
        );
      }
    }
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
