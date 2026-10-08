import 'package:flutter/material.dart';
import '../models.dart';
import '../providers.dart';
import '../widgets.dart';
import 'order_detail_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});
  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  List<AppOrder> _orders = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await db
          .from('orders')
          .select('*, order_items(*)')
          .eq('user_id', db.auth.currentUser!.id)
          .order('created_at', ascending: false);
      _orders = (data as List).map((e) => AppOrder.fromMap(e)).toList();
      _error = null;
    } catch (_) {
      _error = 'Could not load your orders.';
    }
    if (mounted) setState(() => _loading = false);
  }

  Widget _card(AppOrder o) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => OrderDetailScreen(orderId: o.id)));
          _load();
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text('Order #${o.id}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const Spacer(),
              StatusChip(o.status),
            ]),
            const SizedBox(height: 4),
            Text(fmtDate(o.createdAt), style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            const SizedBox(height: 6),
            Text(o.itemsSummary, maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 8),
            Row(children: [
              Text('Total: ${peso(o.total)}', style: const TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              const Text('Payment: '),
              StatusChip(o.paymentStatus),
            ]),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return ErrorRetry(_error!, _load);
    final current = _orders.where((o) => o.status != 'completed' && o.status != 'cancelled').toList();
    final history = _orders.where((o) => o.status == 'completed' || o.status == 'cancelled').toList();
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(padding: const EdgeInsets.all(16), children: [
        const Text('My Orders', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        const Text('Current Orders', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (current.isEmpty) const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('No current orders.')),
        ...current.map(_card),
        const SizedBox(height: 12),
        const Text('Order History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (history.isEmpty) const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('No past orders yet.')),
        ...history.map(_card),
      ]),
    );
  }
}
