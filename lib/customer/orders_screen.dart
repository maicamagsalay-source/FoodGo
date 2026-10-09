import 'package:flutter/material.dart';
import '../models.dart';
import '../providers.dart';
import '../widgets.dart';
import 'order_cancellation.dart';
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
  final Set<int> _cancellingOrderIds = {};

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
    final canCancel = canCancelOrder(status: o.status, paymentStatus: o.paymentStatus);
    final isCancelling = _cancellingOrderIds.contains(o.id);
    return Card(
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => OrderDetailScreen(orderId: o.id)),
              );
              _load();
            },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text('Order #${o.id}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const Spacer(),
                  StatusChip(o.status),
                ]),
                const SizedBox(height: 4),
                Text(fmtDate(o.createdAt),
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                const SizedBox(height: 6),
                Text(o.itemsSummary, maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 8),
                Row(children: [
                  Text('Total: ${peso(o.total)}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const Spacer(),
                  const Text('Payment: '),
                  StatusChip(o.paymentStatus),
                ]),
              ]),
            ),
          ),
          if (canCancel)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: isCancelling
                    ? null
                    : () async {
                        setState(() => _cancellingOrderIds.add(o.id));
                        final cancelled = await confirmOrderCancellation(context, o.id);
                        if (!mounted) return;
                        setState(() => _cancellingOrderIds.remove(o.id));
                        if (cancelled) await _load();
                      },
                icon: isCancelling
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.cancel_outlined, color: Colors.red),
                label: Text(
                  isCancelling ? 'Cancelling...' : 'Cancel order',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _orderSection(String title, List<AppOrder> orders, double width) {
    final columns = width >= 1080 ? 3 : width >= 700 ? 2 : 1;
    const spacing = 12.0;
    final cardWidth = (width - spacing * (columns - 1)) / columns;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (orders.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(title == 'Current Orders' ? 'No current orders.' : 'No past orders yet.'),
          )
        else
          Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: orders
                .map((order) => SizedBox(width: cardWidth, child: _card(order)))
                .toList(),
          ),
      ],
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth >= 1260 ? 1200.0 : constraints.maxWidth;
          return Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: width,
              child: ListView(
                padding: EdgeInsets.symmetric(
                  horizontal: constraints.maxWidth >= 850 ? 28 : 16,
                  vertical: 20,
                ),
                children: [
                  const Text('My Orders', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _orderSection('Current Orders', current, width - (constraints.maxWidth >= 850 ? 56 : 32)),
                  const SizedBox(height: 24),
                  _orderSection('Order History', history, width - (constraints.maxWidth >= 850 ? 56 : 32)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
