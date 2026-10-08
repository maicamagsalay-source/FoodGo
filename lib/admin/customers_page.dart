import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../providers.dart';
import '../widgets.dart';

class CustomersPage extends StatefulWidget {
  const CustomersPage({super.key});
  @override
  State<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends State<CustomersPage> {
  List<Map<String, dynamic>> _rows = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      // Passwords are never stored in our tables (Supabase Auth handles them), so admins can't see them.
      final data = await db
          .from('profiles')
          .select('full_name, email, phone, created_at')
          .eq('role', 'customer')
          .order('created_at', ascending: false);
      _rows = List<Map<String, dynamic>>.from(data as List);
      _error = null;
    } catch (_) {
      _error = 'Could not load customers.';
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return ErrorRetry(_error!, _load);
    return RefreshIndicator(
      onRefresh: _load,
      child: _rows.isEmpty
          ? ListView(children: const [Padding(padding: EdgeInsets.all(40), child: Center(child: Text('No customers yet.')))])
          : ListView(
              padding: const EdgeInsets.all(12),
              children: _rows
                  .map((r) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(child: Text((r['full_name'] as String).isEmpty ? '?' : (r['full_name'] as String)[0].toUpperCase())),
                          title: Text(r['full_name'] ?? ''),
                          subtitle: Text('${r['email'] ?? ''}\n${r['phone'] ?? ''}'),
                          isThreeLine: true,
                          trailing: Text(DateFormat('MMM d, y').format(DateTime.parse(r['created_at']).toLocal()),
                              style: const TextStyle(fontSize: 12)),
                        ),
                      ))
                  .toList(),
            ),
    );
  }
}
