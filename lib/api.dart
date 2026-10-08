import 'dart:convert';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'providers.dart';

/// Asks our Supabase Edge Function to create a PayMongo checkout link.
Future<String> createPaymentLink(int orderId) async {
  final res = await db.functions.invoke('create-payment', body: {'order_id': orderId});
  final data = res.data;
  if (data is Map && data['checkout_url'] != null) return data['checkout_url'] as String;
  throw Exception(
      data is Map ? (data['error'] ?? 'Could not start payment') : 'Could not start payment');
}

/// Creates the payment link and opens PayMongo's secure checkout page.
Future<void> openPayment(int orderId) async {
  final url = await createPaymentLink(orderId);
  final ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  if (!ok) throw Exception('Could not open the payment page');
}

/// A dynamic QR Ph code: exact amount, single use.
class QrPayment {
  final Uint8List bytes;
  final DateTime expiresAt;
  QrPayment(this.bytes, this.expiresAt);
}

Future<QrPayment> createQrPayment(int orderId) async {
  try {
    final res = await db.functions.invoke('create-qrph', body: {'order_id': orderId});
    final d = res.data;
    if (d is Map && d['qr_image'] != null) {
      final b64 = (d['qr_image'] as String).split(',').last;
      return QrPayment(base64Decode(b64), DateTime.parse(d['expires_at'] as String));
    }
    throw Exception('Could not create the QR code');
  } on FunctionException catch (e) {
    final d = e.details;
    throw Exception(d is Map && d['error'] != null ? d['error'] : 'Could not create the QR code');
  }
}

/// Returns 'paid' or 'pending'.
Future<String> checkQrPayment(int orderId) async {
  final res = await db.functions.invoke('check-qrph', body: {'order_id': orderId});
  final d = res.data;
  return d is Map ? (d['payment_status'] ?? 'pending') as String : 'pending';
}
