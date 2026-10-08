import 'package:flutter/material.dart';
import '../models.dart';
import '../providers.dart';
import '../widgets.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _c = TextEditingController();
  List<Category> _cats = [];
  List<Food> _results = [];
  int? _cat;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final cats = await db.from('categories').select().order('id');
    _cats = (cats as List).map((e) => Category.fromMap(e)).toList();
    await _search();
  }

  Future<void> _search() async {
    setState(() => _loading = true);
    try {
      var q = db.from('foods').select().eq('is_available', true);
      final text = _c.text.trim();
      if (text.isNotEmpty) q = q.ilike('name', '%$text%');
      if (_cat != null) q = q.eq('category_id', _cat!);
      final data = await q.order('name');
      _results = (data as List).map((e) => Food.fromMap(e)).toList();
    } catch (_) {
      _results = [];
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        TextField(
          controller: _c,
          textInputAction: TextInputAction.search,
          onChanged: (_) => _search(),
          decoration: InputDecoration(
            hintText: 'Search food, e.g. burger',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _c.text.isEmpty
                ? null
                : IconButton(icon: const Icon(Icons.clear), onPressed: () { _c.clear(); _search(); }),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 40,
          child: ListView(scrollDirection: Axis.horizontal, children: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                  label: const Text('All'),
                  selected: _cat == null,
                  onSelected: (_) { _cat = null; _search(); }),
            ),
            ..._cats.map((c) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                      label: Text(c.name),
                      selected: _cat == c.id,
                      onSelected: (_) { _cat = c.id; _search(); }),
                )),
          ]),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _results.isEmpty
                  ? const Center(child: Text('No food found.'))
                  : ListView(children: _results.map((f) => FoodCard(f)).toList()),
        ),
      ]),
    );
  }
}
