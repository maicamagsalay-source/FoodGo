import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models.dart';
import '../providers.dart';
import '../widgets.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback onSearchTap;
  const HomeScreen({super.key, required this.onSearchTap});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Category> _cats = [];
  List<Food> _foods = [];
  int? _selectedCat; // null = All
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final cats = await db.from('categories').select().order('id');
      final foods = await db.from('foods').select().eq('is_available', true).order('name');
      _cats = (cats as List).map((e) => Category.fromMap(e)).toList();
      _foods = (foods as List).map((e) => Food.fromMap(e)).toList();
    } catch (e) {
      _error = 'Could not load the menu.';
    }
    if (mounted) setState(() => _loading = false);
  }

  Widget _section(String title, List<Food> foods) {
    if (foods.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 8),
        child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
      LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final columns = width >= 1080
              ? 4
              : width >= 820
                  ? 3
                  : width >= 560
                      ? 2
                      : 1;
          const spacing = 12.0;
          final cardWidth = (width - spacing * (columns - 1)) / columns;
          return Wrap(
            spacing: spacing,
            children: foods
                .map((food) => SizedBox(width: cardWidth, child: FoodCard(food)))
                .toList(),
          );
        },
      ),
    ]);
  }

  Widget _featuredPick(Food? food) {
    return Container(
      margin: const EdgeInsets.only(top: 16, bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFB83F20),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('TODAY\'S PICK',
                style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(food?.name ?? 'Find your next favorite',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(food == null ? 'Fresh flavors, made for your cravings.' : peso(food.price),
                style: const TextStyle(color: Colors.white, fontSize: 14)),
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              style: FilledButton.styleFrom(
                foregroundColor: const Color(0xFF8F2D16),
                backgroundColor: Colors.white,
                minimumSize: const Size(0, 40),
              ),
              onPressed: food == null
                  ? widget.onSearchTap
                  : () {
                      context.read<CartProvider>().add(food);
                      snack(context, '${food.name} added to cart');
                    },
              icon: Icon(food == null ? Icons.search : Icons.add, size: 18),
              label: Text(food == null ? 'Explore menu' : 'Add to cart'),
            ),
          ]),
        ),
        if (food?.imageUrl != null && food!.imageUrl!.isNotEmpty) ...[
          const SizedBox(width: 12),
          FoodImage(food.imageUrl, size: 112, height: 128),
        ] else ...[
          const SizedBox(width: 12),
          const Icon(Icons.restaurant, color: Colors.white70, size: 64),
        ],
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = context.watch<AuthProvider>().name;
    final firstName = name.split(' ').first;
    final featured = _foods.where((food) => food.isFeatured).toList();

    return RefreshIndicator(
      onRefresh: _load,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1220),
          child: ListView(
            padding: EdgeInsets.symmetric(
              horizontal: MediaQuery.sizeOf(context).width >= 850 ? 28 : 16,
              vertical: 20,
            ),
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final greeting = Text(
                    'Good day, ${firstName.isEmpty ? 'Foodie' : firstName}!',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  );
                  final search = GestureDetector(
                    onTap: widget.onSearchTap,
                    child: AbsorbPointer(
                      child: TextField(
                        decoration: const InputDecoration(
                          hintText: 'What are you craving?',
                          prefixIcon: Icon(Icons.search),
                        ),
                      ),
                    ),
                  );
                  if (constraints.maxWidth >= 700) {
                    return Row(
                      children: [
                        Expanded(child: greeting),
                        const SizedBox(width: 24),
                        SizedBox(width: constraints.maxWidth * 0.48, child: search),
                      ],
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [greeting, const SizedBox(height: 12), search],
                  );
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 40,
                child: ListView(scrollDirection: Axis.horizontal, children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                        label: const Text('All'),
                        selected: _selectedCat == null,
                        onSelected: (_) => setState(() => _selectedCat = null)),
                  ),
                  ..._cats.map((c) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                            label: Text(c.name),
                            selected: _selectedCat == c.id,
                            onSelected: (_) => setState(() => _selectedCat = c.id)),
                      )),
                ]),
              ),
              if (_loading)
                const Padding(
                    padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()))
              else if (_error != null)
                SizedBox(height: 200, child: ErrorRetry(_error!, _load))
              else if (_selectedCat != null) ...[
                _section('Menu', _foods.where((f) => f.categoryId == _selectedCat).toList()),
                if (!_foods.any((f) => f.categoryId == _selectedCat))
                  const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: Text('No food in this category yet.'))),
              ] else ...[
                _featuredPick(featured.firstOrNull),
                _section('Featured Food', featured.skip(1).toList()),
                _section('Popular Food', _foods.where((f) => f.isPopular).toList()),
                _section('All Food', _foods),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
