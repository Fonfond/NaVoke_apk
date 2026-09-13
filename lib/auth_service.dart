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

  static Future<Map<String, dynamic>> login(String username, String password) async {
    // ✅ ПРЕОБРАЗУЕМ ТЕЛЕФОН В ЧИСТЫЙ ВИД (БЕЗ +, ПРОБЕЛОВ, СКОБОК)
    final cleanPhone = username.replaceAll(RegExp(r'[^0-9]'), '');
    final loginUsername = cleanPhone.startsWith('8') ? '7${cleanPhone.substring(1)}' : cleanPhone;

    final response = await http.post(
      Uri.parse('$apiUrl/users/login/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': loginUsername, 'password': password}),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await saveToken(data['access']);
      return data;
    } else {
      throw Exception('Неверный логин или пароль');
    }
  }

  static Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    // ✅ Убираем username и email (они не нужны для API)
    userData.remove('username');
    userData.remove('email');

    final response = await http.post(
      Uri.parse('$apiUrl/users/register/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(userData),
    );
    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      await saveToken(data['access']);
      return data;
    } else {
      throw Exception(jsonDecode(response.body)['error'] ?? 'Ошибка регистрации');
    }
  }
}