import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_firebase_notification/notification/service/service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class MessagePage extends StatefulWidget {
  const MessagePage({super.key});

  @override
  State<MessagePage> createState() => _MessagePageState();
}

class _MessagePageState extends State<MessagePage> {
  String? userToken;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  FirebaseFirestore _firestore = FirebaseFirestore.instance;
  FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    _initLocalNotification();
  }

  void _initLocalNotification() {
    const AndroidInitializationSettings androidInitializationSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: androidInitializationSettings);

    _flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> _getTokenAndSendNotification() async {
    String email = _emailController.text.trim();

    if (email.isEmpty) {
      _showDialog('Error', 'Please enter an email address');
      return;
    }

    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(email).get();
      if (userDoc.exists) {
        setState(() {
          userToken = userDoc['deviceToken'];
          debugPrint("Fetched token: $userToken");
        });

        if (userToken != null) {
          _sendNotification();
        } else {
          _showDialog('Error', 'Device token not found for this user.');
        }
      } else {
        _showDialog('Error', 'User not found.');
      }
    } catch (e) {
      debugPrint('Error retrieving document: $e');
      _showDialog('Error', 'Error retrieving user document.');
    }
  }

  _sendNotification() async {
    String title = _titleController.text.trim();
    String body = _bodyController.text.trim();

    if (title.isEmpty || body.isEmpty) {
      _showDialog("error", "title and body cannnot be empty");
      return;
    }

    try {
      final accessToken = await Service().getAccessToken();
      await Service().sendNotificaton(accessToken, userToken!, title, body);
      _showDialog('Success', 'Notification sent successfully.');
    } catch (e) {
      debugPrint('Error sending notification: $e');
      _showDialog('Error', 'Error sending notification.');
    }
  }

  void _showDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
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
          const SizedBox(
            height: 10,
          ),
          TextFormField(
            controller: _titleController,
          ),
          const SizedBox(
            height: 10,
          ),
          TextFormField(
            controller: _bodyController,
          ),
          const SizedBox(
            height: 10,
          ),
          TextButton(
            onPressed: _getTokenAndSendNotification,
            child: const Text("Send Notification"),
          ),
        ],
      ),
    );
  }
}
