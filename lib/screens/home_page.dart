// lib/screens/home_page.dart
import 'package:flutter/material.dart';
import '../api_service.dart';
import '../auth_service.dart';
import 'catalog_page.dart';
import 'product_detail_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<dynamic> categories = [];
  List<dynamic> popularProducts = [];
  bool isLoading = true;

  // ✅ ДЛЯ БИЗНЕС-ЛАНЧА
  Map<String, dynamic>? _lunchMenu;

  // ✅ ДЛЯ БАННЕРА
  bool _bannerEnabled = true;
  String _bannerTitle = 'Скидка 20%';
  String _bannerSubtitle = 'на первый заказ';

  // Для поиска
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      // ✅ ЗАПРАШИВАЕМ ПУБЛИЧНЫЕ НАСТРОЙКИ
      final settings = await ApiService.request('/core/settings/public/');

      // ✅ ЗАГРУЖАЕМ КАТЕГОРИИ
      final cats = await ApiService.request('/products/categories/');

      // ✅ ЗАГРУЖАЕМ ТОВАРЫ
      final prods = await ApiService.request('/products/');

      // ✅ ЗАГРУЖАЕМ МЕНЮ БИЗНЕС-ЛАНЧА
      final lunchMenu = await ApiService.request('/products/lunch-menu/');

      // ✅ ФИЛЬТРУЕМ ТОЛЬКО ХИТЫ
      List<dynamic> allProducts = prods['results'] ?? [];
      List<dynamic> hits = allProducts.where((p) => p['is_hit'] == true).toList();
      if (hits.isEmpty) {
        hits = allProducts.take(6).toList();
      }

      if (mounted) {
        setState(() {
          // ✅ ПРИМЕНЯЕМ НАСТРОЙКИ БАННЕРА
          _bannerEnabled = settings['banner_enabled'] ?? true;
          _bannerTitle = settings['banner_title'] ?? 'Скидка 20%';
          _bannerSubtitle = settings['banner_subtitle'] ?? 'на первый заказ';

          categories = cats['results'] ?? [];
          popularProducts = hits;

          // ✅ СОХРАНЯЕМ МЕНЮ БИЗНЕС-ЛАНЧА
          _lunchMenu = lunchMenu;

          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
      debugPrint('Ошибка загрузки: $e');
    }
  }

  Future<void> _onSearchChanged() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      if (mounted) {
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });
      }
      return;
    }
    if (query.length < 2) return;

    if (mounted) setState(() => _isSearching = true);
    try {
      final result = await ApiService.request('/products/live-search/?q=$query');
      if (mounted) {
        setState(() {
          _searchResults = result['results'] ?? [];
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isSearching = false);
      debugPrint('Ошибка поиска: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          if (!_isSearching)
            SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ✅ ЛОГОТИП И ПОИСК (СВОЙ HEADER)
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 40, 16, 16),
                    child: Column(
                      children: [
                        const Text(
                          'НаVoke',
                          style: TextStyle(
                            color: Color(0xFFEF7F1A),
                            fontWeight: FontWeight.bold,
                            fontSize: 28,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: TextField(
                            controller: _searchController,
                            textAlign: TextAlign.center,
                            decoration: const InputDecoration(
                              hintText: 'Поиск блюд...',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              suffixIcon: Icon(Icons.search, color: Colors.grey),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // ✅ БАННЕР (если включен)
                  if (_bannerEnabled)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFFFB300), Color(0xFFA68D6F)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            _bannerTitle,
                            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          Text(
                            _bannerSubtitle,
                            style: TextStyle(fontSize: 20, color: Colors.white),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const CatalogPage()),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                            child: const Text('Заказать'),
                          ),
                        ],
                      ),
                    ),
                  // ✅ БИЗНЕС-ЛАНЧ (если есть позиции)
                  if (_lunchMenu != null && _lunchMenu!['items'] != null && (_lunchMenu!['items'] as List).isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Column(
                        children: [
                          Text(
                            _lunchMenu!['title'] ?? 'Бизнес-ланч',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          ...(_lunchMenu!['items'] as List).map((item) {
                            return Card(
                              child: ListTile(
                                title: Text(item['name'] ?? ''),
                                subtitle: Text('${item['price'] ?? 0} ₽'),
                                trailing: ElevatedButton(
                                  onPressed: () => _addToCart(context, item['product_id']),
                                  child: const Text('В корзину'),
                                ),
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  // ✅ КАТЕГОРИИ
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text('Категории', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ),
                  SizedBox(
                    height: 130,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final cat = categories[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CatalogPage(initialCategory: cat['slug']),
                              ),
                            );
                          },
                          child: Container(
                            width: 90,
                            height: 120,
                            margin: const EdgeInsets.only(right: 12),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(color: Colors.grey.withValues(alpha: 0.1), blurRadius: 4, offset: const Offset(0, 2)),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    ApiService.getFullImageUrl(cat['image_url']),
                                    width: 40, height: 40, fit: BoxFit.contain,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(cat['name'] ?? '', textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  // ✅ ПОПУЛЯРНЫЕ ТОВАРЫ (ВЕРТИКАЛЬНО)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Text('Популярное', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisExtent: 290,  // ✅ ИЗМЕНЕНО С 0.75 НА 0.85
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: popularProducts.length,
                      itemBuilder: (context, index) {
                        return _buildProductCard(context, popularProducts[index]);
                      },
                    ),
                  ),
                ],
              ),
            ),

          // ✅ ВЫПАДАЮЩИЙ СПИСОК РЕЗУЛЬТАТОВ ПОИСКА
          if (_isSearching)
            Positioned.fill(
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: _searchResults.isEmpty
                    ? const Center(child: Text('Ничего не найдено'))
                    : ListView.builder(
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final item = _searchResults[index];
                    return ListTile(
                      leading: Image.network(ApiService.getFullImageUrl(item['image_url']), width: 40, height: 40, fit: BoxFit.cover),
                      title: Text(item['name'] ?? ''),
                      subtitle: Text('${item['price'] ?? 0} ₽'),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProductDetailScreen(product: item),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, dynamic product) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProductDetailScreen(product: product),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.grey.withValues(alpha: 0.1), blurRadius: 8),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.network(
                ApiService.getFullImageUrl(product['image_url']),
                height: 110, // ✅ УМЕНЬШЕНА ВЫСОТА
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      product['name'] ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    Text(
                      '${product['price'] ?? 0} ₽',
                      style: const TextStyle(color: Color(0xFFEF7F1A), fontWeight: FontWeight.bold, fontSize: 17),
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _addToCart(context, product['id']),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEF7F1A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 4),
                        ),
                        child: const Text('В корзину', style: TextStyle(fontSize: 12)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addToCart(BuildContext context, int productId) async {
    try {
      final token = await AuthService.getToken();

      if (token != null) {
        await ApiService.request(
            '/orders/cart/add/',
            method: 'POST',
            body: {'product_id': productId, 'quantity': 1},
            auth: true
        );
      } else {
        await ApiService.request(
            '/orders/guest-cart/',
            method: 'POST',
            body: {'product_id': productId, 'quantity': 1}
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