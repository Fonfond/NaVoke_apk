import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'auth_service.dart';

const String apiUrl = 'https://navoke.relaxdev.ru/api/v1';

class FirebaseService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> init() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission();
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      String? token = await _firebaseMessaging.getToken();
      await _sendTokenToServer(token);
      await _firebaseMessaging.subscribeToTopic('orders');
    }
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {});
  }

  Future<void> _sendTokenToServer(String? token) async {
    if (token == null) return;
    final accessToken = await AuthService.getToken();
    if (accessToken == null) return;
    await http.post(
      Uri.parse('$apiUrl/users/save-fcm-token/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode({'fcm_token': token}),
    );
  }
}