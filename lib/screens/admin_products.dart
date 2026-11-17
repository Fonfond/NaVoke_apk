import 'package:flutter/material.dart';
import '../api_service.dart';

class AdminProducts extends StatefulWidget {
  const AdminProducts({super.key});

  @override
  State<AdminProducts> createState() => _AdminProductsState();
}

class _AdminProductsState extends State<AdminProducts> {
  List<dynamic> _products = [];
  List<dynamic> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final products = await ApiService.request('/products/', auth: true);
      final cats = await ApiService.request(
        '/products/categories/',
        auth: true,
      );
      if (mounted) {
        setState(() {
          _products = products['results'] ?? [];
          _categories = cats['results'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Удаление
  Future<void> _deleteProduct(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить товар?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await ApiService.request(
        '/products/$id/delete/',
        method: 'DELETE',
        auth: true,
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('✅ Товар удалён')));
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('❌ Ошибка: $e')));
      }
    }
  }

  // Добавление/редактирование через модалку
  Future<void> _showProductModal({Map<String, dynamic>? product}) async {
    final nameController = TextEditingController(text: product?['name'] ?? '');
    final priceController = TextEditingController(
      text: (product?['price'] ?? '').toString(),
    );
    final weightController = TextEditingController(
      text: (product?['weight'] ?? '').toString(),
    );
    final ingredientsController = TextEditingController(
      text: product?['ingredients'] ?? '',
    );
    String? selectedCategoryId = product?['category']?.toString();
    bool hasVariants = product?['has_variants'] ?? false;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            title: Text(
              product == null ? 'Добавить товар' : 'Редактировать товар',
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Название'),
                  ),
                  TextField(
                    controller: priceController,
                    decoration: const InputDecoration(labelText: 'Цена'),
                  ),
                  TextField(
                    controller: weightController,
                    decoration: const InputDecoration(labelText: 'Вес (г)'),
                  ),
                  TextField(
                    controller: ingredientsController,
                    decoration: const InputDecoration(labelText: 'Состав'),
                    maxLines: 3,
                  ),
                  DropdownButtonFormField<String>(
                    value: selectedCategoryId,
                    decoration: const InputDecoration(labelText: 'Категория'),
                    items: _categories
                        .map(
                          (cat) => DropdownMenuItem(
                            value: cat['id'].toString(),
                            child: Text(cat['name']),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setModalState(() => selectedCategoryId = value),
                  ),
                  CheckboxListTile(
                    title: const Text('Есть вариации?'),
                    value: hasVariants,
                    onChanged: (v) =>
                        setModalState(() => hasVariants = v ?? false),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Отмена'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final parsedPrice = double.tryParse(
                    priceController.text.trim(),
                  );
                  final categoryId = int.tryParse(selectedCategoryId ?? '');

                  if (categoryId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Выберите категорию')),
                    );
                    return;
                  }

                  if (!hasVariants &&
                      (parsedPrice == null || parsedPrice <= 0)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Для товара без вариаций укажите цену больше 0',
                        ),
                      ),
                    );
                    return;
                  }

                  final data = <String, dynamic>{
                    'name': nameController.text.trim(),
                    'weight': int.tryParse(weightController.text) ?? 0,
                    'ingredients': ingredientsController.text,
                    'category': categoryId,
                    'has_variants': hasVariants,
                  };

                  if (!hasVariants) {
                    data['price'] = parsedPrice;
                  }

                  try {
                    if (product == null) {
                      await ApiService.request(
                        '/products/',
                        method: 'POST',
                        body: data,
                        auth: true,
                      );
                    } else {
                      await ApiService.request(
                        '/products/${product['id']}/update/',
                        method: 'PUT',
                        body: data,
                        auth: true,
                      );
                    }
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('✅ Товар сохранён')),
                    );
                    _loadData();
                  } catch (e) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('❌ Ошибка: $e')));
                  }
                },
                child: const Text('Сохранить'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Управление товарами'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _products.length,
        itemBuilder: (context, index) {
          final product = _products[index];
          return Card(
            elevation: 2,
            child: ListTile(
              leading: Image.network(
                ApiService.getFullImageUrl(product['image_url']),
                width: 60,
                height: 60,
                fit: BoxFit.cover,
              ),
              title: Text(product['name'] ?? ''),
              subtitle: Text(
                '${product['price'] ?? 0} ₽ • ${product['ingredients'] ?? ''}',
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => _showProductModal(product: product),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteProduct(product['id']),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showProductModal(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
