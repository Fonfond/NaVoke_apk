// lib/screens/order_screen.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../auth_service.dart';

const String apiUrl = 'https://navoke.relaxdev.ru/api/v1';

class OrderScreen extends StatefulWidget {
  const OrderScreen({super.key});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  List<dynamic> orders = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    final token = await AuthService.getToken();
    final response = await http.get(
      Uri.parse('$apiUrl/orders/list/'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      setState(() {
        orders = jsonDecode(response.body)['results'] ?? [];
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());
    return ListView.builder(
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return Card(
          margin: const EdgeInsets.all(8),
          child: ListTile(
            title: Text('Заказ #${order['order_number']}'),
            subtitle: Text('Статус: ${order['status']} • ${order['total_amount']} ₽'),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => OrderDetailScreen(orderId: order['id'])));
            },
          ),
        );
      },
    );
  }
}

class OrderDetailScreen extends StatefulWidget {
  final int orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  Map<String, dynamic>? order;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrderDetail();
  }

  Future<void> _loadOrderDetail() async {
    final token = await AuthService.getToken();
    final response = await http.get(
      Uri.parse('$apiUrl/orders/${widget.orderId}/'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      setState(() {
        order = jsonDecode(response.body);
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());
    return Scaffold(
      appBar: AppBar(title: Text('Заказ #${order!['order_number']}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Статус: ${order!['status']}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text('Адрес: ${order!['delivery_address']}'),
            Text('Дата: ${order!['order_date']}'),
            const Divider(),
            const Text('Состав заказа:', style: TextStyle(fontWeight: FontWeight.bold)),
            ...((order!['items'] ?? []) as List).map((item) {
              return ListTile(
                title: Text(item['product_name']),
                subtitle: Text('${item['quantity']} шт.'),
                trailing: Text('${item['price_at_order']} ₽'),
              );
            }),
            const Divider(),
            Text('Итого: ${order!['total_amount']} ₽', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}