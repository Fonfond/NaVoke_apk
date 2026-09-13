// lib/screens/product_detail_screen.dart
import 'package:flutter/material.dart';
import '../api_service.dart';
import '../auth_service.dart';
import 'main_screen.dart'; // ✅ ИМПОРТ MAIN_SCREEN

class ProductDetailScreen extends StatefulWidget {
  final dynamic product;
  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1;
  List<dynamic> _reviews = [];
  bool _isLoadingReviews = true;
  bool _isFavorite = false;

  // Для формы отзыва
  final TextEditingController _reviewTextController = TextEditingController();
  int _rating = 0;

  @override
  void initState() {
    super.initState();
    _loadReviews();
    _checkFavorite();
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

  Future<void> _checkFavorite() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return;

      final result = await ApiService.request(
        '/products/${widget.product['id']}/favorite/check/',
        auth: true,
      );
      if (mounted) {
        setState(() {
          _isFavorite = result['is_favorite'] ?? false;
        });
      }
    } catch (e) {
      // Молча игнорируем ошибку
    }
  }

  Future<void> _loadReviews() async {
    try {
      final response = await ApiService.request('/products/${widget.product['id']}/reviews/');
      setState(() {
        _reviews = response['results'] ?? [];
        _isLoadingReviews = false;
      });
    } catch (e) {
      setState(() => _isLoadingReviews = false);
    }
  }

  Future<void> _submitReview() async {
    if (_rating < 1) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Поставьте оценку')));
      return;
    }
    try {
      await ApiService.request(
        '/products/${widget.product['id']}/reviews/create/',
        method: 'POST',
        body: {'rating': _rating, 'text': _reviewTextController.text.trim()},
        auth: true,
      );
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Отзыв опубликован!')));
      _reviewTextController.clear();
      _rating = 0;
      _loadReviews();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ Ошибка: $e')));
    }
  }

  Future<void> _toggleFavorite() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('⚠️ Пожалуйста, войдите в систему')),
        );
        return;
      }

      final result = await ApiService.request(
        '/products/${widget.product['id']}/favorite/',
        method: 'POST',
        auth: true,
      );
      setState(() {
        _isFavorite = result['status'] == 'added';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isFavorite ? '❤️ Добавлено в избранное' : '💔 Удалено из избранного')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Ошибка: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final price = (product['price'] ?? 0).toDouble();
    final imageUrl = ApiService.getFullImageUrl(product['image_url']);
    final hasVariants = product['has_variants'] ?? false;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: _goBack, // ✅ БЕЗОПАСНЫЙ ВОЗВРАТ
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Хлебные крошки
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _goBack,
                    child: const Text('Главная', style: TextStyle(color: Colors.grey)),
                  ),
                  const Text(' / ', style: TextStyle(color: Colors.grey)),
                  const Text('Каталог', style: TextStyle(color: Colors.grey)),
                  const Text(' / ', style: TextStyle(color: Colors.grey)),
                  Text(product['name'] ?? '', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Картинка
            Center(
              child: Container(
                width: double.infinity,
                height: 220,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF7F1A),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey.shade200,
                        child: const Center(child: Icon(Icons.image_not_supported, size: 60, color: Colors.grey)),
                      );
                    },
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Название и цена
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['name'] ?? 'Товар',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    product['category_name'] ?? '',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${product['weight'] ?? 0} г · ${product['ingredients'] ?? ''}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${price.toStringAsFixed(0)} ₽',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFFEF7F1A)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Количество и Избранное
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove, size: 20),
                          onPressed: () {
                            if (_quantity > 1) setState(() => _quantity--);
                          },
                        ),
                        Text(
                          '$_quantity',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add, size: 20),
                          onPressed: () => setState(() => _quantity++),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      _isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: Colors.red,
                    ),
                    onPressed: _toggleFavorite,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Кнопка "В корзину"
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    await _addToCart(context, product['id'], _quantity);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF7F1A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    elevation: 0,
                  ),
                  child: const Text('В корзину', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ===== ОТЗЫВЫ =====
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text('Отзывы', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),

            if (_isLoadingReviews)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_reviews.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('У этого товара пока нет отзывов. Будьте первым!', style: TextStyle(color: Colors.grey)),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _reviews.length,
                itemBuilder: (context, index) {
                  final rev = _reviews[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(rev['user_name'] ?? 'Аноним', style: const TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(width: 8),
                            Row(
                              children: List.generate(5, (i) {
                                return Icon(
                                  i < (rev['rating'] ?? 0) ? Icons.star : Icons.star_border,
                                  color: Colors.amber,
                                  size: 16,
                                );
                              }),
                            ),
                          ],
                        ),
                        if (rev['text'] != null && rev['text'].isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(rev['text'] ?? ''),
                        ],
                      ],
                    ),
                  );
                },
              ),

            // ===== ФОРМА ОТЗЫВА =====
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text('Оставить отзыв', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: List.generate(5, (index) {
                  final starValue = index + 1;
                  return IconButton(
                    icon: Icon(
                      starValue <= _rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 28,
                    ),
                    onPressed: () => setState(() => _rating = starValue),
                  );
                }),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _reviewTextController,
                decoration: const InputDecoration(
                  hintText: 'Поделитесь впечатлениями...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitReview,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF7F1A),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Отправить отзыв'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addToCart(BuildContext context, int productId, int quantity) async {
    try {
      final token = await AuthService.getToken();

      if (token != null) {
        await ApiService.request(
            '/orders/cart/add/',
            method: 'POST',
            body: {'product_id': productId, 'quantity': quantity},
            auth: true
        );
      } else {
        await ApiService.request(
            '/orders/guest-cart/',
            method: 'POST',
            body: {'product_id': productId, 'quantity': quantity}
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Товар добавлен в корзину!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Ошибка: $e')),
        );
      }
    }
  }
}