// lib/auth_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const String apiUrl = 'https://navoke.relaxdev.ru/api/v1'; // ← ТВОЙ ДОМЕН

class AuthService {
  static String? _token;

  static Future<void> saveToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', token);
  }

  static Future<String?> getToken() async {
    if (_token != null) return _token;
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('access_token');
    return _token;
  }

  static Future<void> logout() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
  }

  static String _errorMessage(http.Response response, String fallback) {
    try {
      final data = jsonDecode(response.body);
      if (data is Map) {
        final detail = data['detail'] ?? data['error'];
        if (detail != null) return detail.toString();
        if (data.isNotEmpty) {
          final entry = data.entries.first;
          final value = entry.value;
          return '${entry.key}: ${value is List ? value.join(' ') : value}';
        }
      }
    } catch (_) {}
    return fallback;
  }

  static Future<Map<String, dynamic>> login(String username, String password) async {
    final loginUsername = username.trim();
    if (loginUsername.isEmpty || password.isEmpty) {
      throw Exception('Введите телефон/логин и пароль');
    }

    http.Response response;
    try {
      response = await http
          .post(
            Uri.parse('$apiUrl/users/login/'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'username': loginUsername,
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 15));
    } catch (_) {
      throw Exception('Нет соединения с сервером. Проверьте интернет.');
    }

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await saveToken(data['access']);
      return Map<String, dynamic>.from(data as Map);
    }

    if (response.statusCode == 401) {
      throw Exception('Неверный телефон/логин или пароль');
    }
    throw Exception(_errorMessage(response, 'Ошибка входа'));
  }

  static Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    // ✅ Убираем username и email (они не нужны для API)
    userData.remove('username');
    userData.remove('email');

    http.Response response;
    try {
      response = await http
          .post(
            Uri.parse('$apiUrl/users/register/'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(userData),
          )
          .timeout(const Duration(seconds: 15));
    } catch (_) {
      throw Exception('Нет соединения с сервером. Проверьте интернет.');
    }

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      await saveToken(data['access']);
      return Map<String, dynamic>.from(data as Map);
    }
    throw Exception(_errorMessage(response, 'Ошибка регистрации'));
  }
}