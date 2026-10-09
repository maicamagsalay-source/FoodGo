import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../auth_screens.dart';
import '../providers.dart';
import '../widgets.dart';
import 'about_screen.dart';
import 'orders_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final primary = Theme.of(context).colorScheme.primary;
    return ListView(padding: const EdgeInsets.all(16), children: [
      const SizedBox(height: 12),
      Center(
        child: CircleAvatar(
          radius: 48,
          backgroundColor: primary.withValues(alpha: 0.15),
          child: Text(auth.name.isEmpty ? '?' : auth.name[0].toUpperCase(),
              style: TextStyle(fontSize: 36, color: primary, fontWeight: FontWeight.bold)),
        ),
      ),
      const SizedBox(height: 12),
      Center(
          child:
              Text(auth.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
      Center(child: Text(auth.email)),
      Center(child: Text(auth.phone)),
      const SizedBox(height: 20),
      Card(
        child: Column(children: [
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: const Text('Edit Profile'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const EditProfileScreen())),
          ),
          ListTile(
            leading: const Icon(Icons.receipt_long_outlined),
            title: const Text('My Orders'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => Scaffold(
                        appBar: AppBar(title: const Text('My Orders')),
                        body: const OrdersScreen()))),
          ),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('Change Password'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const ChangePasswordScreen())),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About Lamón'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () =>
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutScreen())),
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () async {
              await auth.logout();
              if (context.mounted) {
                context.read<CartProvider>().clear();
                goToLanding(context);
              }
            },
          ),
        ]),
      ),
    ]);
  }
}

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final _name = TextEditingController(text: context.read<AuthProvider>().name);
  late final _phone = TextEditingController(text: context.read<AuthProvider>().phone);
  bool _busy = false;

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) return;
    setState(() => _busy = true);
    try {
      await db.from('profiles').update({
        'full_name': _name.text.trim(),
        'phone': _phone.text.trim(),
      }).eq('id', db.auth.currentUser!.id);
      await context.read<AuthProvider>().loadProfile();
      if (mounted) {
        snack(context, 'Profile updated');
        Navigator.pop(context);
      }
    } catch (_) {
      if (mounted) snack(context, 'Could not save. Please try again.');
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          TextField(controller: _name, decoration: const InputDecoration(labelText: 'Full Name')),
          const SizedBox(height: 12),
          TextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone Number')),
          const SizedBox(height: 20),
          SizedBox(
              width: double.infinity,
              child: FilledButton(onPressed: _busy ? null : _save, child: const Text('Save'))),
        ]),
      ),
    );
  }
}

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});
  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _pw = TextEditingController();
  final _pw2 = TextEditingController();
  bool _busy = false;

  Future<void> _save() async {
    if (_pw.text.length < 6) return snack(context, 'Password must be at least 6 characters');
    if (_pw.text != _pw2.text) return snack(context, 'Passwords do not match');
    setState(() => _busy = true);
    try {
      await db.auth.updateUser(UserAttributes(password: _pw.text));
      if (mounted) {
        snack(context, 'Password changed');
        Navigator.pop(context);
      }
    } on AuthException catch (e) {
      if (mounted) snack(context, e.message);
    } catch (_) {
      if (mounted) snack(context, 'Could not change password.');
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Change Password')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          TextField(
              controller: _pw,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'New password')),
          const SizedBox(height: 12),
          TextField(
              controller: _pw2,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Confirm new password')),
          const SizedBox(height: 20),
          SizedBox(
              width: double.infinity,
              child: FilledButton(
                  onPressed: _busy ? null : _save, child: const Text('Change Password'))),
        ]),
      ),
    );
  }
}
