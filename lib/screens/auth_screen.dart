// lib/screens/auth_screen.dart
import 'package:flutter/material.dart';
import '../auth_service.dart';
import 'main_screen.dart';
import '../firebase_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;

  // ✅ ФУНКЦИЯ ВОЗВРАТА НА ГЛАВНУЮ
  void _goBack() {
    // Если экран был открыт через push — возвращаемся
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      // Если это корневой экран — переходим на MainScreen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    }
  }

  Future<void> _handleSubmit() async {
    setState(() => _isLoading = true);
    try {
      if (_isLogin) {
        // ✅ Вход по телефону
        await AuthService.login(_phoneController.text.trim(), _passwordController.text);
      } else {
        // ✅ Регистрация
        await AuthService.register({
          'phone': _phoneController.text.trim(),
          'full_name': _fullNameController.text.trim(),
          'password': _passwordController.text,
          'password2': _passwordController.text,
        });
        await FirebaseService().init();
      }
      if (mounted) {
        // ✅ ВСЕГДА ПЕРЕХОДИМ НА ГЛАВНУЮ ПОСЛЕ УСПЕХА
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ✅ ДОБАВЛЯЕМ APP BAR С КНОПКОЙ НАЗАД
      appBar: AppBar(
        title: Text(_isLogin ? 'Вход' : 'Регистрация'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _goBack, // ✅ Возврат на главную
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ✅ ТЕЛЕФОН
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Телефон',
                  hintText: '+7 (999) 123-45-67',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                ),
              ),
              const SizedBox(height: 16),

              // ✅ ПОЛНОЕ ИМЯ (только для регистрации)
              if (!_isLogin) ...[
                TextField(
                  controller: _fullNameController,
                  decoration: InputDecoration(
                    labelText: 'Полное имя',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ✅ ПАРОЛЬ
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Пароль',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                ),
              ),
              const SizedBox(height: 24),

              // ✅ КНОПКА ОТПРАВКИ
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF7F1A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                      : Text(
                    _isLogin ? 'Войти' : 'Зарегистрироваться',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ✅ ПЕРЕКЛЮЧЕНИЕ
              TextButton(
                onPressed: () => setState(() => _isLogin = !_isLogin),
                child: Text(
                  _isLogin ? 'Нет аккаунта? Зарегистрироваться' : 'Уже есть аккаунт? Войти',
                  style: const TextStyle(color: Color(0xFFEF7F1A), fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}