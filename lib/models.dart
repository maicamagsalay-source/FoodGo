double _d(dynamic v) => (v as num).toDouble();

class Category {
  final int id;
  final String name;
  Category(this.id, this.name);
  factory Category.fromMap(Map<String, dynamic> m) => Category(m['id'], m['name']);
}

class Food {
  final int id;
  final String name, description;
  final double price;
  final int? categoryId;
  final String? imageUrl;
  final bool isAvailable, isFeatured, isPopular;

  Food({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.categoryId,
    this.imageUrl,
    this.isAvailable = true,
    this.isFeatured = false,
    this.isPopular = false,
  });

  factory Food.fromMap(Map<String, dynamic> m) => Food(
        id: m['id'],
        name: m['name'],
        description: m['description'] ?? '',
        price: _d(m['price']),
        categoryId: m['category_id'],
        imageUrl: m['image_url'],
        isAvailable: m['is_available'] ?? true,
        isFeatured: m['is_featured'] ?? false,
        isPopular: m['is_popular'] ?? false,
      );
}

class CartItem {
  final Food food;
  int qty;
  CartItem(this.food, this.qty);
  double get total => food.price * qty;
}

class OrderItem {
  final String name;
  final double price;
  final int qty;
  OrderItem(this.name, this.price, this.qty);
  factory OrderItem.fromMap(Map<String, dynamic> m) =>
      OrderItem(m['food_name'], _d(m['price']), m['quantity']);
}

class AppOrder {
  final int id;
  final String customerName, phone, address, status, paymentStatus, paymentMethod;
  final double subtotal, deliveryFee, total;
  final DateTime createdAt;
  final List<OrderItem> items;

  AppOrder({
    required this.id,
    required this.customerName,
    required this.phone,
    required this.address,
    required this.status,
    required this.paymentStatus,
    required this.paymentMethod,
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
    required this.createdAt,
    required this.items,
  });

  factory AppOrder.fromMap(Map<String, dynamic> m) => AppOrder(
        id: m['id'],
        customerName: m['customer_name'],
        phone: m['phone'],
        address: m['address'],
        status: m['status'],
        paymentStatus: m['payment_status'],
        paymentMethod: m['payment_method'] ?? 'PayMongo',
        subtotal: _d(m['subtotal']),
        deliveryFee: _d(m['delivery_fee']),
        total: _d(m['total']),
        createdAt: DateTime.parse(m['created_at']),
        items: ((m['order_items'] ?? []) as List)
            .map((e) => OrderItem.fromMap(e as Map<String, dynamic>))
            .toList(),
      );

  String get itemsSummary => items.map((i) => '${i.qty}x ${i.name}').join(', ');
}

class PaymentRecord {
  final int id, orderId;
  final String customerName, method, transactionId, status;
  final double amount;
  final DateTime? paidAt;
  final DateTime createdAt;

  PaymentRecord({
    required this.id,
    required this.orderId,
    required this.customerName,
    required this.method,
    required this.transactionId,
    required this.status,
    required this.amount,
    required this.paidAt,
    required this.createdAt,
  });

  factory PaymentRecord.fromMap(Map<String, dynamic> m) => PaymentRecord(
        id: m['id'],
        orderId: m['order_id'],
        customerName: m['orders']?['customer_name'] ?? '-',
        method: m['method'] ?? '-',
        transactionId: m['paymongo_payment_id'] ?? m['paymongo_checkout_id'] ?? '-',
        status: m['status'],
        amount: _d(m['amount']),
        paidAt: m['paid_at'] == null ? null : DateTime.parse(m['paid_at']),
        createdAt: DateTime.parse(m['created_at']),
      );
}
