// lib/screens/admin_panel.dart
import 'package:flutter/material.dart';
import '../api_service.dart';
import '../auth_service.dart';
import 'auth_screen.dart';
import 'admin_products.dart';
import 'admin_orders.dart';
import 'admin_users.dart';
import 'admin_settings.dart';
import 'main_screen.dart'; // ✅ ИМПОРТ MAIN_SCREEN

class AdminPanel extends StatefulWidget {
  const AdminPanel({super.key});

  @override
  State<AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  bool _isLoading = true;
  bool _isAdmin = false;
  int _todayOrders = 0;
  double _todayRevenue = 0;
  int _totalUsers = 0;
  double _avgRating = 0;
  List<double> _weeklyRevenue = [];
  List<dynamic> _recentOrders = [];

  @override
  void initState() {
    super.initState();
    _checkAccess();
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

  Future<void> _checkAccess() async {
    final token = await AuthService.getToken();
    if (token == null) {
      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AuthScreen()));
      }
      return;
    }
    try {
      final user = await ApiService.request('/users/profile/', auth: true);
      if (!mounted) return;
      if (user['role'] != 'admin') {
        setState(() { _isLoading = false; _isAdmin = false; });
        return;
      }
      _isAdmin = true;
      await _loadDashboardData();
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadDashboardData() async {
    try {
      final data = await ApiService.request('/core/analytics/', auth: true);
      if (!mounted) return;
      List<double> weekly = [];
      try {
        final raw = data['weekly_revenue'];
        if (raw != null && raw is List) {
          weekly = raw.map((e) => (e as num).toDouble()).toList();
        }
      } catch (_) {
        weekly = [];
      }
      setState(() {
        _todayOrders = data['today_orders'] ?? 0;
        _todayRevenue = (data['today_revenue'] ?? 0).toDouble();
        _totalUsers = data['total_users'] ?? 0;
        _avgRating = (data['avg_rating'] ?? 0).toDouble();
        _weeklyRevenue = weekly;
        _recentOrders = data['recent_orders'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (!_isAdmin) {
      return Scaffold(body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.lock, size: 80, color: Colors.grey),
        const Text('Доступ запрещён', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('Только для администраторов', style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 24),
        ElevatedButton(onPressed: _goBack, child: const Text('Назад')), // ✅ БЕЗОПАСНЫЙ ВОЗВРАТ
      ])));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Админ-панель'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _goBack, // ✅ БЕЗОПАСНЫЙ ВОЗВРАТ
        ),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _loadDashboardData)],
      ),
      body: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFFEF7F1A),
            child: const Text('Дашборд 📊', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              _buildMenuItem(Icons.list_alt, 'Заказы 📋', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminOrders()))),
              _buildMenuItem(Icons.fastfood, 'Товары 🍔', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminProducts()))),
              _buildMenuItem(Icons.people, 'Пользователи 👥', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminUsers()))),
              _buildMenuItem(Icons.sell, 'Настройки ⚙️', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminSettings()))),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(children: [
              Expanded(child: _buildStatCard('Заказов сегодня', '$_todayOrders', Colors.orange)),
              const SizedBox(width: 8),
              Expanded(child: _buildStatCard('Выручка сегодня', '${_todayRevenue.toStringAsFixed(0)} ₽', Colors.green)),
            ]),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(children: [
              Expanded(child: _buildStatCard('Пользователей', '$_totalUsers', Colors.blue)),
              const SizedBox(width: 8),
              Expanded(child: _buildStatCard('Средний рейтинг', '$_avgRating ⭐', Colors.yellow)),
            ]),
          ),
          const SizedBox(height: 24),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 4))],
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Продажи за неделю', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              SizedBox(
                height: 120,
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.end, children: [
                  _buildBar('Пн', _weeklyRevenue.isNotEmpty ? _weeklyRevenue[0] : 0),
                  _buildBar('Вт', _weeklyRevenue.isNotEmpty ? _weeklyRevenue[1] : 0),
                  _buildBar('Ср', _weeklyRevenue.isNotEmpty ? _weeklyRevenue[2] : 0),
                  _buildBar('Чт', _weeklyRevenue.isNotEmpty ? _weeklyRevenue[3] : 0),
                  _buildBar('Пт', _weeklyRevenue.isNotEmpty ? _weeklyRevenue[4] : 0),
                  _buildBar('Сб', _weeklyRevenue.isNotEmpty ? _weeklyRevenue[5] : 0),
                  _buildBar('Вс', _weeklyRevenue.isNotEmpty ? _weeklyRevenue[6] : 0),
                ]),
              ),
            ]),
          ),
          const SizedBox(height: 16),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 4))],
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Последние заказы', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              if (_recentOrders.isEmpty) const Center(child: Text('Нет заказов', style: TextStyle(color: Colors.grey)))
              else ..._recentOrders.map((order) => _buildOrderRow(order)),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String label, VoidCallback onTap) => ListTile(
    leading: Icon(icon, size: 28),
    title: Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    trailing: const Icon(Icons.chevron_right),
    onTap: onTap,
    contentPadding: EdgeInsets.zero,
  );

  Widget _buildStatCard(String label, String value, Color color) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.1), blurRadius: 4, offset: const Offset(0, 2))],
    ),
    child: Column(children: [
      Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
      const SizedBox(height: 4),
      Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
    ]),
  );

  Widget _buildBar(String label, double value) {
    if (_weeklyRevenue.isEmpty) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 24,
            height: 10,
            decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4)),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      );
    }

    final maxValue = _weeklyRevenue.reduce((a, b) => a > b ? a : b);
    final height = maxValue > 0 ? ((value / maxValue) * 100).toDouble() : 0.0;
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 24,
          height: height,
          decoration: BoxDecoration(
            color: const Color(0xFFEF7F1A),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
  Widget _buildOrderRow(dynamic order) {
    final status = order['status'] ?? 'new';
    Color statusColor;
    String statusText;
    switch (status) {
      case 'delivered': statusColor = Colors.green; statusText = 'Доставлен'; break;
      case 'new': statusColor = Colors.blue; statusText = 'Новый'; break;
      case 'cooking': statusColor = Colors.orange; statusText = 'Готовится'; break;
      case 'cancelled': statusColor = Colors.red; statusText = 'Отменён'; break;
      default: statusColor = Colors.grey; statusText = 'Неизвестно';
    }
    return Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Row(children: [
        Text('#${order['order_number'] ?? order['id']}', style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(width: 12),
        Text(order['user_name'] ?? 'Клиент', style: const TextStyle(color: Colors.grey)),
      ]),
      Row(children: [
        Text('${order['total_amount'] ?? 0} ₽', style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(width: 8),
        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)), child: Text(statusText, style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold))),
      ]),
    ]));
  }
}