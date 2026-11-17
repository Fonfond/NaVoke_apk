// lib/screens/checkout_page.dart
import 'package:flutter/material.dart';
import '../api_service.dart';
import 'main_screen.dart'; // ✅ ИМПОРТ MAIN_SCREEN

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _commentController = TextEditingController();
  String _paymentMethod = 'online';
  String _deliveryType = 'delivery'; // 'delivery' или 'pickup'
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final user = await ApiService.request('/users/profile/', auth: true);
      if (!mounted) return;
      setState(() {
        _nameController.text = user['full_name'] ?? '';
        _phoneController.text = user['phone'] ?? '';
        _emailController.text = user['email'] ?? '';
      });
    } catch (_) {
      // Пользователь заполнит контакты вручную.
    }
  }

  // ✅ ВОЗВРАТ НА ГЛАВНУЮ
  void _goBack() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    }
  }

  Future<void> _createOrder() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();

    if (name.isEmpty || phone.isEmpty || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Заполните имя, телефон и email')),
      );
      return;
    }

    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Введите корректный email')));
      return;
    }

    if (_deliveryType == 'delivery' && _addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Укажите адрес доставки')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ApiService.request(
        '/orders/',
        method: 'POST',
        body: {
          'full_name': name,
          'phone': phone,
          'email': email,
          'delivery_type': _deliveryType,
          'delivery_address': _deliveryType == 'delivery'
              ? _addressController.text.trim()
              : 'Самовывоз',
          'payment_method': _paymentMethod,
          'comment': _commentController.text.trim(),
        },
        auth: true,
      );

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('✅ Заказ оформлен!')));
        // ✅ ВСЕГДА ПЕРЕХОДИМ НА ГЛАВНУЮ
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('❌ Ошибка: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Оформление заказа'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _goBack,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Контактные данные
            const Text(
              'Контактные данные',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Имя *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Телефон *',
                hintText: '+7 (999) 123-45-67',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email *',
                hintText: 'example@mail.ru',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            // Способ получения
            const Text(
              'Способ получения',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            RadioGroup<String>(
              groupValue: _deliveryType,
              onChanged: (value) => setState(() => _deliveryType = value!),
              child: const Row(
                children: [
                  Radio(value: 'delivery'),
                  Text('Доставка'),
                  SizedBox(width: 24),
                  Radio(value: 'pickup'),
                  Text('Самовывоз'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Адрес (только для доставки)
            if (_deliveryType == 'delivery') ...[
              const Text(
                'Адрес доставки',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              TextField(
                controller: _addressController,
                decoration: const InputDecoration(
                  hintText: 'Улица, дом, квартира',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Комментарий
            const Text(
              'Комментарий',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            TextField(
              controller: _commentController,
              decoration: const InputDecoration(
                hintText: 'Позвоните в домофон',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // Способ оплаты
            const Text(
              'Способ оплаты',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            RadioGroup<String>(
              groupValue: _paymentMethod,
              onChanged: (value) => setState(() => _paymentMethod = value!),
              child: const Row(
                children: [
                  Radio(value: 'online'),
                  Text('Онлайн картой'),
                  SizedBox(width: 24),
                  Radio(value: 'cash'),
                  Text('Наличными курьеру'),
                ],
              ),
            ),

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _createOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF7F1A),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Подтвердить заказ',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
