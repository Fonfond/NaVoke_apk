// lib/screens/cart_page.dart
import 'package:flutter/material.dart';
import '../api_service.dart';
import '../auth_service.dart';
import 'auth_screen.dart';
import 'checkout_page.dart';
import 'main_screen.dart'; // ✅ ИМПОРТ MAIN_SCREEN

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  List<dynamic> items = [];
  bool isLoading = true;
  double total = 0;

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  Future<void> _loadCart() async {
    final token = await AuthService.getToken();
    if (token == null) {
      // Если не авторизован — отправляем на вход
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AuthScreen()),
        );
      }
      return;
    }

    try {
      final cart = await ApiService.request('/orders/cart/', auth: true);
      if (mounted) {
        setState(() {
          items = cart['items'] ?? [];
          total = (cart['total'] ?? 0).toDouble();
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // ✅ БЕЗОПАСНЫЙ ВОЗВРАТ НА ГЛАВНУЮ
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

  Future<void> _updateQuantity(int itemId, int newQty) async {
    if (newQty < 1) return;
    try {
      await ApiService.request('/orders/cart/update/$itemId/', method: 'PUT', body: {'quantity': newQty}, auth: true);
      _loadCart();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ Ошибка: $e')));
      }
    }
  }

  Future<void> _removeItem(int itemId) async {
    try {
      await ApiService.request('/orders/cart/remove/$itemId/', method: 'DELETE', auth: true);
      _loadCart();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ Ошибка: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (items.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('Корзина пуста', style: TextStyle(fontSize: 18, color: Colors.grey))),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Корзина', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: _goBack, // ✅ БЕЗОПАСНЫЙ ВОЗВРАТ
        ),
      ),
      body: Column(
        children: [
          // Хлебные крошки
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _goBack,
                  child: const Text('Главная', style: TextStyle(color: Colors.grey)),
                ),
                const Text(' / ', style: TextStyle(color: Colors.grey)),
                const Text('Корзина', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ],
            ),
          ),

          // Список товаров
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final price = (item['product_price'] ?? 0).toDouble();
                final qty = item['quantity'] ?? 1;
                final totalPrice = price * qty;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      // Картинка
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            ApiService.getFullImageUrl(item['product_image']),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Center(child: Icon(Icons.image, color: Colors.grey));
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Инфо
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['product_name'] ?? 'Товар',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${price.toStringAsFixed(0)} ₽',
                              style: const TextStyle(color: Color(0xFFEF7F1A), fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),

                      // Количество и итог
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline, size: 20),
                                onPressed: () => _updateQuantity(item['id'], qty - 1),
                              ),
                              Text('$qty', style: const TextStyle(fontWeight: FontWeight.bold)),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline, size: 20),
                                onPressed: () => _updateQuantity(item['id'], qty + 1),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                                onPressed: () => _removeItem(item['id']),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${totalPrice.toStringAsFixed(0)} ₽',
                            style: const TextStyle(color: Color(0xFFEF7F1A), fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Итог
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey[200]!)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Товары:', style: TextStyle(fontSize: 16, color: Colors.grey)),
                    Text('${total.toStringAsFixed(0)} ₽', style: const TextStyle(fontSize: 16, color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Доставка:', style: TextStyle(fontSize: 16, color: Colors.grey)),
                    Text(total >= 800 ? '0 ₽' : '150 ₽', style: const TextStyle(fontSize: 16, color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Итого:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    Text(
                      '${(total + (total >= 800 ? 0 : 150)).toStringAsFixed(0)} ₽',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFEF7F1A)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const CheckoutPage()));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF7F1A),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    ),
                    child: const Text(
                      'Оформить заказ',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}