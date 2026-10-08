import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'models.dart';

SupabaseClient get db => Supabase.instance.client;

/// Keeps track of the logged-in user and their profile (name, role...).
class AuthProvider extends ChangeNotifier {
  Map<String, dynamic>? profile;

  bool get loggedIn => db.auth.currentUser != null;
  bool get isAdmin => profile?['role'] == 'admin';
  String get name => (profile?['full_name'] ?? '') as String;
  String get email => (profile?['email'] ?? db.auth.currentUser?.email ?? '') as String;
  String get phone => (profile?['phone'] ?? '') as String;

  Future<void> loadProfile() async {
    final user = db.auth.currentUser;
    if (user == null) {
      profile = null;
    } else {
      try {
        profile = await db.from('profiles').select().eq('id', user.id).single();
      } catch (_) {
        profile = null;
      }
    }
    notifyListeners();
  }

  /// Returns an error message, or null when successful.
  Future<String?> login(String email, String password) async {
    try {
      await db.auth.signInWithPassword(email: email, password: password);
      await loadProfile();
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (_) {
      return 'Could not log in. Check your internet connection.';
    }
  }

  Future<String?> register(String name, String email, String phone, String password) async {
    try {
      await db.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': name, 'phone': phone},
      );
      await loadProfile();
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (_) {
      return 'Could not create account. Check your internet connection.';
    }
  }

  Future<void> logout() async {
    await db.auth.signOut();
    profile = null;
    notifyListeners();
  }
}

/// The shopping cart (kept in memory).
class CartProvider extends ChangeNotifier {
  static const double deliveryFeeAmount = 49;

  final Map<int, CartItem> _items = {};

  List<CartItem> get items => _items.values.toList();
  int get count => _items.values.fold(0, (s, i) => s + i.qty);
  double get subtotal => _items.values.fold(0.0, (s, i) => s + i.total);
  double get deliveryFee => _items.isEmpty ||
          _items.values.any((item) => item.food.name.trim().toLowerCase() == 'lemonade')
      ? 0
      : deliveryFeeAmount;
  double get total => subtotal + deliveryFee;

  void add(Food food, [int qty = 1]) {
    if (_items.containsKey(food.id)) {
      _items[food.id]!.qty += qty;
    } else {
      _items[food.id] = CartItem(food, qty);
    }
    notifyListeners();
  }

  void increase(int foodId) {
    _items[foodId]?.qty++;
    notifyListeners();
  }

  void decrease(int foodId) {
    final item = _items[foodId];
    if (item == null) return;
    item.qty--;
    if (item.qty <= 0) _items.remove(foodId);
    notifyListeners();
  }

  void remove(int foodId) {
    _items.remove(foodId);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
