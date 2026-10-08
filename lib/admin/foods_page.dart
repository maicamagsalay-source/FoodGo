import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models.dart';
import '../providers.dart';
import '../widgets.dart';

class FoodsPage extends StatefulWidget {
  const FoodsPage({super.key});
  @override
  State<FoodsPage> createState() => _FoodsPageState();
}

class _FoodsPageState extends State<FoodsPage> {
  List<Food> _foods = [];
  List<Category> _cats = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final f = await db.from('foods').select().order('name');
      final c = await db.from('categories').select().order('id');
      _foods = (f as List).map((e) => Food.fromMap(e)).toList();
      _cats = (c as List).map((e) => Category.fromMap(e)).toList();
      _error = null;
    } catch (_) {
      _error = 'Could not load foods.';
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _openForm([Food? food]) async {
    final saved = await Navigator.push<bool>(
        context, MaterialPageRoute(builder: (_) => FoodFormScreen(food: food, categories: _cats)));
    if (saved == true) _load();
  }

  Future<void> _delete(Food f) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete food?'),
        content: Text('Delete "${f.name}"? Past orders keep their history.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await db.from('foods').delete().eq('id', f.id);
      _load();
    } catch (_) {
      if (mounted) snack(context, 'Could not delete.');
    }
  }

  Future<void> _toggle(Food f, bool value) async {
    await db.from('foods').update({'is_available': value}).eq('id', f.id);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _openForm(), icon: const Icon(Icons.add), label: const Text('Add Food')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? ErrorRetry(_error!, _load)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(padding: const EdgeInsets.fromLTRB(12, 8, 12, 90), children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () async {
                          await Navigator.push(context, MaterialPageRoute(builder: (_) => const CategoriesScreen()));
                          _load();
                        },
                        icon: const Icon(Icons.category_outlined),
                        label: const Text('Manage Categories'),
                      ),
                    ),
                    if (_foods.isEmpty) const Padding(padding: EdgeInsets.all(32), child: Center(child: Text('No food yet. Tap Add Food.'))),
                    ..._foods.map((f) {
                      final cat = _cats.where((c) => c.id == f.categoryId).map((c) => c.name).firstOrNull ?? 'No category';
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          onTap: () => _openForm(f),
                          leading: FoodImage(f.imageUrl, size: 52),
                          title: Text(f.name),
                          subtitle: Text('${peso(f.price)} • $cat'),
                          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                            Switch(value: f.isAvailable, onChanged: (v) => _toggle(f, v)),
                            IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => _delete(f)),
                          ]),
                        ),
                      );
                    }),
                  ]),
                ),
    );
  }
}

class FoodFormScreen extends StatefulWidget {
  final Food? food;
  final List<Category> categories;
  const FoodFormScreen({super.key, this.food, required this.categories});
  @override
  State<FoodFormScreen> createState() => _FoodFormScreenState();
}

class _FoodFormScreenState extends State<FoodFormScreen> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.food?.name);
  late final _desc = TextEditingController(text: widget.food?.description);
  late final _price = TextEditingController(text: widget.food?.price.toString());
  late int? _catId = widget.food?.categoryId;
  late bool _available = widget.food?.isAvailable ?? true;
  late bool _featured = widget.food?.isFeatured ?? false;
  late bool _popular = widget.food?.isPopular ?? false;
  Uint8List? _bytes;
  bool _busy = false;

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1024, imageQuality: 80);
    if (picked == null) return;
    final b = await picked.readAsBytes();
    setState(() => _bytes = b);
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      String? imageUrl = widget.food?.imageUrl;
      if (_bytes != null) {
        final path = '${DateTime.now().millisecondsSinceEpoch}.jpg';
        await db.storage.from('food-images').uploadBinary(path, _bytes!,
            fileOptions: const FileOptions(contentType: 'image/jpeg'));
        imageUrl = db.storage.from('food-images').getPublicUrl(path);
      }
      final row = {
        'name': _name.text.trim(),
        'description': _desc.text.trim(),
        'price': double.parse(_price.text.trim()),
        'category_id': _catId,
        'image_url': imageUrl,
        'is_available': _available,
        'is_featured': _featured,
        'is_popular': _popular,
      };
      if (widget.food == null) {
        await db.from('foods').insert(row);
      } else {
        await db.from('foods').update(row).eq('id', widget.food!.id);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) snack(context, 'Could not save food. Please try again.');
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.food == null ? 'Add Food' : 'Edit Food')),
      body: Form(
        key: _form,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          GestureDetector(
            onTap: _pickImage,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _bytes != null
                  ? Image.memory(_bytes!, height: 180, fit: BoxFit.cover)
                  : (widget.food?.imageUrl != null
                      ? FoodImage(widget.food!.imageUrl, size: double.infinity, height: 180)
                      : Container(
                          height: 180,
                          color: Colors.orange.shade50,
                          child: const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.add_a_photo, size: 40),
                            Text('Tap to upload image'),
                          ])),
                        )),
            ),
          ),
          if (_bytes != null || widget.food?.imageUrl != null)
            TextButton(onPressed: _pickImage, child: const Text('Change image')),
          const SizedBox(height: 8),
          TextFormField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Food Name'),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(controller: _desc, maxLines: 3, decoration: const InputDecoration(labelText: 'Description')),
          const SizedBox(height: 12),
          TextFormField(
            controller: _price,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Price (₱)'),
            validator: (v) => (double.tryParse(v ?? '') == null || double.parse(v!) < 0) ? 'Enter a valid price' : null,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            initialValue: _catId,
            decoration: const InputDecoration(labelText: 'Category'),
            items: widget.categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
            onChanged: (v) => setState(() => _catId = v),
          ),
          SwitchListTile(title: const Text('Available'), value: _available, onChanged: (v) => setState(() => _available = v)),
          SwitchListTile(title: const Text('Featured (Home page)'), value: _featured, onChanged: (v) => setState(() => _featured = v)),
          SwitchListTile(title: const Text('Popular (Home page)'), value: _popular, onChanged: (v) => setState(() => _popular = v)),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _busy ? null : _save,
            child: _busy
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save'),
          ),
        ]),
      ),
    );
  }
}

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});
  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  List<Category> _cats = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final c = await db.from('categories').select().order('id');
      _cats = (c as List).map((e) => Category.fromMap(e)).toList();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _edit([Category? cat]) async {
    final c = TextEditingController(text: cat?.name);
    final name = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(cat == null ? 'Add Category' : 'Edit Category'),
        content: TextField(controller: c, autofocus: true, decoration: const InputDecoration(labelText: 'Name')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, c.text.trim()), child: const Text('Save')),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    try {
      if (cat == null) {
        await db.from('categories').insert({'name': name});
      } else {
        await db.from('categories').update({'name': name}).eq('id', cat.id);
      }
      _load();
    } catch (_) {
      if (mounted) snack(context, 'Could not save (name may already exist).');
    }
  }

  Future<void> _delete(Category cat) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete category?'),
        content: Text('Foods in "${cat.name}" will become uncategorized.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true) return;
    await db.from('categories').delete().eq('id', cat.id);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      floatingActionButton: FloatingActionButton(onPressed: () => _edit(), child: const Icon(Icons.add)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(12),
              children: _cats
                  .map((c) => Card(
                        child: ListTile(
                          title: Text(c.name),
                          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                            IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => _edit(c)),
                            IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => _delete(c)),
                          ]),
                        ),
                      ))
                  .toList(),
            ),
    );
  }
}
