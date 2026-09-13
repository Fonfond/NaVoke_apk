// lib/screens/admin_settings.dart
import 'package:flutter/material.dart';
import '../api_service.dart';

class AdminSettings extends StatefulWidget {
  const AdminSettings({super.key});

  @override
  State<AdminSettings> createState() => _AdminSettingsState();
}

class _AdminSettingsState extends State<AdminSettings> {
  bool _isLoading = true;

  // Поля для баннера
  final TextEditingController _bannerTitle = TextEditingController();
  final TextEditingController _bannerSubtitle = TextEditingController();
  final TextEditingController _deliveryCost = TextEditingController();
  final TextEditingController _bonusRate = TextEditingController();

  // ✅ ДЛЯ БИЗНЕС-ЛАНЧА
  List<dynamic> _lunchItems = [];
  final TextEditingController _lunchTitle = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final data = await ApiService.request('/core/settings/', auth: true);
      final lunchMenu = await ApiService.request('/products/lunch-menu/', auth: true);
      if (mounted) {
        setState(() {
          _bannerTitle.text = data['banner_title'] ?? '';
          _bannerSubtitle.text = data['banner_subtitle'] ?? '';
          _deliveryCost.text = (data['delivery_base_cost'] ?? '').toString();
          _bonusRate.text = (data['bonus_rate'] ?? '').toString();

          _lunchTitle.text = lunchMenu['title'] ?? 'Бизнес-ланч';
          _lunchItems = lunchMenu['items'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    try {
      await ApiService.request('/core/settings/', method: 'PUT', body: {
        'banner_title': _bannerTitle.text,
        'banner_subtitle': _bannerSubtitle.text,
        'delivery_base_cost': int.tryParse(_deliveryCost.text) ?? 150,
        'bonus_rate': double.tryParse(_bonusRate.text) ?? 5,
      }, auth: true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Настройки сохранены')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ Ошибка: $e')));
      }
    }
  }

  Future<void> _saveLunchMenu() async {
    try {
      await ApiService.request('/products/lunch-menu/', method: 'PUT', body: {
        'title': _lunchTitle.text,
        'items': _lunchItems,
      }, auth: true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Меню бизнес-ланча сохранено!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ Ошибка: $e')));
      }
    }
  }

  void _addLunchItem() {
    setState(() {
      _lunchItems.add({'name': '', 'price': 0, 'product_id': null});
    });
  }

  void _removeLunchItem(int index) {
    setState(() {
      _lunchItems.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройки'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            // ✅ БАННЕР
            const Text('Баннер', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            TextField(
              controller: _bannerTitle,
              decoration: InputDecoration(
                labelText: 'Заголовок баннера',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _bannerSubtitle,
              decoration: InputDecoration(
                labelText: 'Подзаголовок',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),

            // ✅ ДОСТАВКА
            const Text('Доставка', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            TextField(
              controller: _deliveryCost,
              decoration: InputDecoration(
                labelText: 'Стоимость доставки (₽)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),

            // ✅ БОНУСЫ
            const Text('Бонусы', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            TextField(
              controller: _bonusRate,
              decoration: InputDecoration(
                labelText: 'Бонусов за 100 ₽',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 32),

            // ✅ БИЗНЕС-ЛАНЧ
            const Text('Бизнес-ланч', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            TextField(
              controller: _lunchTitle,
              decoration: InputDecoration(
                labelText: 'Заголовок меню',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            ...List.generate(_lunchItems.length, (index) {
              final item = _lunchItems[index];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: TextEditingController(text: item['name']),
                          decoration: const InputDecoration(labelText: 'Название блюда'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 80,
                        child: TextField(
                          controller: TextEditingController(text: item['price'].toString()),
                          decoration: const InputDecoration(labelText: 'Цена'),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _removeLunchItem(index),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _addLunchItem,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Добавить блюдо'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _saveLunchMenu,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF7F1A),
                foregroundColor: Colors.white,
              ),
              child: const Text('Сохранить меню'),
            ),
            const SizedBox(height: 32),

            // ✅ ОБЩИЕ НАСТРОЙКИ
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saveSettings,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF7F1A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                ),
                child: const Text('Сохранить настройки', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}