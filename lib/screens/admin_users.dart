import 'package:flutter/material.dart';
import '../api_service.dart';

class AdminUsers extends StatefulWidget {
  const AdminUsers({super.key});

  @override
  State<AdminUsers> createState() => _AdminUsersState();
}

class _AdminUsersState extends State<AdminUsers> {
  List<dynamic> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      final data = await ApiService.request('/users/list/', auth: true);
      if (mounted) {
        setState(() {
          _users = data['results'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _changeRole(int userId, String role) async {
    try {
      await ApiService.request('/users/$userId/update-role/', method: 'PUT', body: {'role': role}, auth: true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Роль обновлена')));
        _loadUsers();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ Ошибка: $e')));
      }
    }
  }

  Future<void> _toggleStatus(int userId, bool isActive) async {
    try {
      await ApiService.request('/users/$userId/toggle-status/', method: 'PUT', body: {'is_active': !isActive}, auth: true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✅ Статус обновлён')));
        _loadUsers();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ Ошибка: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(title: const Text('Управление пользователями'), backgroundColor: Colors.white, foregroundColor: Colors.black, elevation: 0),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _users.length,
        itemBuilder: (context, index) {
          final user = _users[index];
          final role = user['role'] ?? 'client';
          final isActive = user['is_active'] ?? true;
          return Card(
            elevation: 2,
            child: ListTile(
              leading: CircleAvatar(child: Text((user['username'] ?? 'U')[0].toUpperCase())),
              title: Text(user['username'] ?? ''),
              subtitle: Text('${user['full_name'] ?? ''} • ${user['phone'] ?? ''}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButton<String>(
                    value: role,
                    items: const [
                      DropdownMenuItem(value: 'client', child: Text('Клиент')),
                      DropdownMenuItem(value: 'manager', child: Text('Менеджер')),
                      DropdownMenuItem(value: 'admin', child: Text('Админ')),
                    ],
                    onChanged: (value) {
                      if (value != null) _changeRole(user['id'], value);
                    },
                  ),
                  IconButton(
                    icon: Icon(isActive ? Icons.lock : Icons.lock_open, color: isActive ? Colors.red : Colors.green),
                    onPressed: () => _toggleStatus(user['id'], isActive),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}