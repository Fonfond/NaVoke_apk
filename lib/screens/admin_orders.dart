// lib/screens/admin_orders.dart
import 'package:flutter/material.dart';
import '../api_service.dart';

class AdminOrders extends StatefulWidget {
  const AdminOrders({super.key});

  @override
  State<AdminOrders> createState() => _AdminOrdersState();
}

class _AdminOrdersState extends State<AdminOrders> {
  List<dynamic> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    try {
      final data = await ApiService.request('/orders/list/', auth: true);
      if (mounted) {
        setState(() {
          _orders = data['results'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _changeStatus(int orderId, String newStatus) async {
    try {
      await ApiService.request(
        '/orders/$orderId/update-status/',
        method: 'PUT',
        body: {'status': newStatus},
        auth: true,
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('✅ Статус обновлён')));
        _loadOrders();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('❌ Ошибка: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Управление заказами'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _orders.length,
        itemBuilder: (context, index) {
          final order = _orders[index];
          final status = order['status'] ?? 'new';
          final orderNumber = order['order_number'] ?? order['id'];

          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: InkWell(
              onTap: () {
                // ✅ ОТКРЫВАЕМ ДЕТАЛЬНЫЙ ЭКРАН
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AdminOrderDetailScreen(order: order),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ✅ НОМЕР ЗАКАЗА (ПЕРЕНОС ТЕКСТА)
                    Text(
                      'Заказ #$orderNumber',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // ✅ ИМЯ И ТЕЛЕФОН
                    Text(
                      '👤 ${order['full_name'] ?? order['user_name'] ?? 'Клиент'}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    Text(
                      '📞 ${order['phone'] ?? '—'}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 8),

                    // ✅ СТАТУС
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: status == 'delivered'
                                ? Colors.green.withValues(alpha: 0.2)
                                : Colors.blue.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            status == 'delivered'
                                ? '✅ Доставлен'
                                : '⏳ В процессе',
                            style: TextStyle(
                              color: status == 'delivered'
                                  ? Colors.green
                                  : Colors.blue,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButton<String>(
                            value: status,
                            isExpanded: true,
                            underline: const SizedBox(),
                            items: () {
                              const labels = {
                                'new': 'Новый',
                                'confirmed': 'Подтверждён',
                                'cooking': 'Готовится',
                                'ready': 'Готов',
                                'delivering': 'В доставке',
                                'delivered': 'Доставлен',
                                'cancelled': 'Отменён',
                              };
                              const transitions = {
                                'new': ['confirmed', 'cancelled'],
                                'confirmed': ['cooking', 'cancelled'],
                                'cooking': ['ready', 'cancelled'],
                                'ready': [
                                  'delivering',
                                  'delivered',
                                  'cancelled',
                                ],
                                'delivering': ['delivered', 'cancelled'],
                                'delivered': <String>[],
                                'cancelled': <String>[],
                              };
                              final next = <String>{
                                status,
                                ...(transitions[status] ?? const <String>[]),
                              }.toList();
                              if (status != 'delivered' &&
                                  order['payment_method'] == 'online' &&
                                  order['payment_status'] != 'paid') {
                                next.remove('delivered');
                              }
                              return next
                                  .map(
                                    (value) => DropdownMenuItem(
                                      value: value,
                                      child: Text(labels[value] ?? value),
                                    ),
                                  )
                                  .toList();
                            }(),
                            onChanged: (value) {
                              if (value != null && value != status) {
                                _changeStatus(order['id'], value);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ✅ ДЕТАЛЬНЫЙ ЭКРАН ЗАКАЗА
class AdminOrderDetailScreen extends StatefulWidget {
  final dynamic order;
  const AdminOrderDetailScreen({super.key, required this.order});

  @override
  State<AdminOrderDetailScreen> createState() => _AdminOrderDetailScreenState();
}

class _AdminOrderDetailScreenState extends State<AdminOrderDetailScreen> {
  late dynamic _order;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _order = widget.order;
  }

  Future<void> _markAsPaid() async {
    setState(() => _isUpdating = true);
    try {
      await ApiService.request(
        '/orders/${_order['id']}/update-payment-status/',
        method: 'PUT',
        body: {'payment_status': 'paid'},
        auth: true,
      );
      setState(() {
        _order['payment_status'] = 'paid';
        _isUpdating = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Заказ отмечен как оплаченный!')),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isUpdating = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('❌ Ошибка: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = _order;
    final items = order['items'] ?? [];
    final status = order['status'] ?? 'new';
    final paymentStatus = order['payment_status'] ?? 'pending';
    final orderNumber = order['order_number'] ?? order['id'];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Заказ #$orderNumber'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ СТАТУС И ОПЛАТА
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  status == 'delivered' ? '✅ Доставлен' : '⏳ В процессе',
                  style: TextStyle(
                    color: status == 'delivered' ? Colors.green : Colors.blue,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // ✅ КНОПКА ОТМЕТИТЬ ОПЛАТУ
                if (paymentStatus != 'paid')
                  ElevatedButton(
                    onPressed: _isUpdating ? null : _markAsPaid,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isUpdating
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Оплачен'),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '✅ Оплачен',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),

            // ✅ ИНФОРМАЦИЯ О КЛИЕНТЕ
            const Text(
              'Информация о клиенте',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              'Имя',
              order['full_name'] ?? order['user_name'] ?? '—',
            ),
            _buildInfoRow('Телефон', order['phone'] ?? '—'),
            _buildInfoRow('Email', order['customer_email'] ?? '—'),
            const Divider(height: 32),

            // ✅ АДРЕС ДОСТАВКИ
            const Text(
              'Адрес доставки',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildInfoRow('Адрес', order['delivery_address'] ?? 'Самовывоз'),
            _buildInfoRow('Дата', order['delivery_date'] ?? '—'),
            _buildInfoRow('Время', order['delivery_time_from'] ?? '—'),
            const Divider(height: 32),

            // ✅ СОСТАВ ЗАКАЗА
            const Text(
              'Состав заказа',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (items.isEmpty)
              const Text('Нет товаров', style: TextStyle(color: Colors.grey))
            else
              ...items.map((item) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${item['quantity'] ?? 1}x ${item['product_name'] ?? 'Товар'}',
                      ),
                      Text(
                        '${item['price_at_order'] ?? 0} ₽',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                );
              }),
            const Divider(height: 32),

            // ✅ КОЛИЧЕСТВО ПЕРСОН И ПРИБОРОВ
            const Text(
              'Дополнительно',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              'Количество персон',
              '${order['persons_count'] ?? 1}',
            ),
            _buildInfoRow(
              'Количество приборов',
              '${order['cutlery_count'] ?? 1}',
            ),
            const Divider(height: 32),

            // ✅ ИТОГО
            const Text(
              'Итого',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Сумма заказа'),
                Text(
                  '${order['total_amount'] ?? 0} ₽',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Color(0xFFEF7F1A),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
