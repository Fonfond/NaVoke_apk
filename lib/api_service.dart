// lib/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

const String apiUrl = 'https://navoke.relaxdev.ru/api/v1'; // ← ТВОЙ ДОМЕН
const String mediaUrl = 'https://navoke.relaxdev.ru'; // ← ТВОЙ ДОМЕН

class ApiService {
  static Future<dynamic> request(
    String endpoint, {
    String method = 'GET',
    Map<String, dynamic>? body,
    bool auth = false,
  }) async {
    // ✅ ОБЯЗАТЕЛЬНО ПОЛУЧАЕМ ТОКЕН
    final token = await AuthService.getToken();
    final headers = <String, String>{'Content-Type': 'application/json'};

    // ✅ ЕСЛИ НУЖНА АВТОРИЗАЦИЯ, НО ТОКЕНА НЕТ — ВЫБРАСЫВАЕМ ОШИБКУ
    if (auth && token == null) {
      throw Exception('⚠️ Пожалуйста, войдите в систему');
    }

    // ✅ ЕСЛИ ТОКЕН ЕСТЬ — ДОБАВЛЯЕМ В ЗАГОЛОВОК
    if (auth && token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    final url = Uri.parse('$apiUrl$endpoint');
    http.Response response;

    if (method == 'GET') {
      response = await http.get(url, headers: headers);
    } else if (method == 'POST') {
      response = await http.post(url, headers: headers, body: jsonEncode(body));
    } else if (method == 'PUT') {
      response = await http.put(url, headers: headers, body: jsonEncode(body));
    } else {
      response = await http.delete(url, headers: headers);
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return {};
      return jsonDecode(response.body);
    } else {
      // ✅ ЧИТАЕМ ОШИБКУ ОТ СЕРВЕРА ПОДРОБНЕЕ
      String errorMessage = 'Ошибка ${response.statusCode}';
      try {
        final errorData = jsonDecode(response.body);
        if (errorData is Map) {
          final detail = errorData['detail'] ?? errorData['error'];
          if (detail != null) {
            errorMessage = detail.toString();
          } else if (errorData.isNotEmpty) {
            final entry = errorData.entries.first;
            final value = entry.value;
            errorMessage =
                '${entry.key}: ${value is List ? value.join(' ') : value}';
          }
        } else if (errorData is List && errorData.isNotEmpty) {
          errorMessage = errorData.join(', ');
        }
      } catch (_) {}
      throw Exception(errorMessage);
    }
  }

  // ✅ НОВАЯ ФУНКЦИЯ: превращает относительный путь в полный URL
  static String getFullImageUrl(String? path) {
    if (path == null || path.isEmpty)
      return 'https://via.placeholder.com/300x200';
    if (path.startsWith('http')) return path; // Если уже полный URL
    return '$mediaUrl$path'; // Склеиваем с доменом
  }
}
