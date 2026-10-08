import 'package:flutter/material.dart';
import '../models.dart';
import '../providers.dart';
import '../widgets.dart';

/// Read-only list. There are no edit buttons on purpose: PayMongo data must not be changed by hand.
class PaymentsPage extends StatefulWidget {
  const PaymentsPage({super.key});
  @override
  State<PaymentsPage> createState() => _PaymentsPageState();
}

class _PaymentsPageState extends State<PaymentsPage> {
  List<PaymentRecord> _rows = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await db.from('payments').select('*, orders(customer_name)').order('created_at', ascending: false);
      _rows = (data as List).map((e) => PaymentRecord.fromMap(e)).toList();
      _error = null;
    } catch (_) {
      _error = 'Could not load payments.';
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
          ? ListView(children: const [Padding(padding: EdgeInsets.all(40), child: Center(child: Text('No payments yet.')))])
          : ListView(
              padding: const EdgeInsets.all(12),
              children: _rows
                  .map((p) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [
                              Text('Payment #${p.id} • Order #${p.orderId}', style: const TextStyle(fontWeight: FontWeight.bold)),
                              const Spacer(),
                              StatusChip(p.status),
                            ]),
                            const SizedBox(height: 6),
                            Text('${p.customerName} • ${peso(p.amount)}'),
                            Text('Method: ${p.method}'),
                            Text('PayMongo ID: ${p.transactionId}', style: const TextStyle(fontSize: 12)),
                            Text('Date: ${fmtDate(p.paidAt ?? p.createdAt)}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                          ]),
                        ),
                      ))
                  .toList(),
            ),
    );
  }
}
