// lib/screens/catalog_page.dart
import 'package:flutter/material.dart';
import '../api_service.dart';
import '../auth_service.dart';
import 'product_detail_screen.dart';
import 'main_screen.dart'; // ✅ ИМПОРТ MAIN_SCREEN

class CatalogPage extends StatefulWidget {
  final String? initialCategory;
  const CatalogPage({super.key, this.initialCategory});

  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  List<dynamic> categories = [];
  List<dynamic> products = [];
  String? selectedCategory;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    selectedCategory = widget.initialCategory;
    _loadData();
  }

  @override
  void didUpdateWidget(CatalogPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialCategory != widget.initialCategory) {
      setState(() {
        selectedCategory = widget.initialCategory;
      });
    }
  }

  Future<void> _loadData() async {
    try {
      final cats = await ApiService.request('/products/categories/');
      final prods = await ApiService.request('/products/');
      setState(() {
        categories = cats['results'] ?? [];
        products = prods['results'] ?? [];
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      debugPrint('Ошибка загрузки каталога: $e');
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

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Фильтрация по выбранной категории
    final filteredProducts = selectedCategory == null
        ? products
        : products
              .where((p) => p['category_slug'] == selectedCategory)
              .toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Каталог', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: _goBack, // ✅ БЕЗОПАСНЫЙ ВОЗВРАТ
        ),
      ),
      body: CustomScrollView(
        slivers: [
          // 1. Хлебные крошки
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _goBack,
                    child: const Text(
                      'Главная',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                  const Text(' / ', style: TextStyle(color: Colors.grey)),
                  const Text(
                    'Каталог',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. Горизонтальные фильтры (чипсы)
          SliverToBoxAdapter(
            child: SizedBox(
              height: 50,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  FilterChip(
                    label: const Text('Все'),
                    selected: selectedCategory == null,
                    onSelected: (selected) =>
                        setState(() => selectedCategory = null),
                    backgroundColor: selectedCategory == null
                        ? const Color(0xFFEF7F1A)
                        : Colors.grey.shade200,
                    labelStyle: TextStyle(
                      color: selectedCategory == null
                          ? Colors.white
                          : Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ...categories.map((cat) {
                    final isSelected = selectedCategory == cat['slug'];
                    return Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: FilterChip(
                        label: Text(cat['name'] ?? ''),
                        selected: isSelected,
                        onSelected: (_) =>
                            setState(() => selectedCategory = cat['slug']),
                        backgroundColor: isSelected
                            ? const Color(0xFFEF7F1A)
                            : Colors.grey.shade200,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),

          // 3. Сетка товаров
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisExtent: 290,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              delegate: SliverChildBuilderDelegate((context, index) {
                final prod = filteredProducts[index];
                return _buildProductCard(context, prod);
              }, childCount: filteredProducts.length),
            ),
          ),

          // 4. Пагинация
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.arrow_left),
                  ),
                  const Text(
                    '1',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFEF7F1A),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text('2'),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text('3'),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.arrow_right),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, dynamic product) {
    final price = product['price'] ?? 0;
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(product: product),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Картинка
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: Image.network(
                ApiService.getFullImageUrl(product['image_url']),
                height: 110,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 110,
                    color: Colors.grey.shade200,
                    child: const Icon(
                      Icons.image_not_supported,
                      size: 40,
                      color: Colors.grey,
                    ),
                  );
                },
              ),
            ),
            // Текст и кнопка
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['name'] ?? 'Товар',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${price} ₽',
                    style: const TextStyle(
                      color: Color(0xFFEF7F1A),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: double.infinity,
                    height: 32,
                    child: ElevatedButton(
                      onPressed: () => _addToCart(context, product['id']),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF7F1A),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'В корзину',
                        style: TextStyle(fontSize: 11),
                      ),
                    ),
                  ),
                ],
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
      if (token == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                '⚠️ Войдите в систему, чтобы добавить товар в корзину',
              ),
            ),
          );
        }
        return;
      }

      await ApiService.request(
        '/orders/cart/add/',
        method: 'POST',
        body: {'product_id': productId, 'quantity': 1},
        auth: true,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Товар добавлен в корзину!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('❌ Ошибка: $e')));
      }
    }
  }
}
