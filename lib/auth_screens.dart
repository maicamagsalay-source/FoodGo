import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers.dart';
import 'widgets.dart';
import 'customer/customer_shell.dart';
import 'admin/admin_shell.dart';

/// Sends the user to Login, the Customer app, or the Admin dashboard.
void goToLanding(BuildContext context) {
  final auth = context.read<AuthProvider>();
  final Widget page = !auth.loggedIn
      ? const LoginScreen()
      : auth.isAdmin
          ? const AdminShell()
          : const CustomerShell();
  Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => page), (_) => false);
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _pw = TextEditingController();
  bool _loading = false, _hide = true;

  Future<void> _login() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    final err = await context.read<AuthProvider>().login(_email.text.trim(), _pw.text);
    if (!mounted) return;
    setState(() => _loading = false);
    if (err != null) {
      snack(context, err);
      return;
    }
    goToLanding(context);
  }

  Future<void> _forgot() async {
    final c = TextEditingController(text: _email.text);
    final email = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reset password'),
        content: TextField(
            controller: c,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Your email')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, c.text.trim()), child: const Text('Send link')),
        ],
      ),
    );
    if (email == null || email.isEmpty) return;
    try {
      await db.auth.resetPasswordForEmail(email);
      if (mounted) snack(context, 'Check your email for the reset link.');
    } catch (e) {
      if (mounted) snack(context, 'Could not send reset email.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Form(
                    key: _form,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.delivery_dining, size: 72, color: primary),
                        const Text('Lamón', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
                        const Text('Welcome back! Log in to order.'),
                        const SizedBox(height: 28),
                        TextFormField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
                          validator: (v) => (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _pw,
                          obscureText: _hide,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(_hide ? Icons.visibility_off : Icons.visibility),
                              onPressed: () => setState(() => _hide = !_hide),
                            ),
                          ),
                          validator: (v) => (v == null || v.isEmpty) ? 'Enter your password' : null,
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(onPressed: _forgot, child: const Text('Forgot Password?')),
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _loading ? null : _login,
                            child: _loading
                                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Text('Login'),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
                            onPressed: () => Navigator.push(
                                context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                            child: const Text('Create Account'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _pw = TextEditingController();
  final _pw2 = TextEditingController();
  bool _loading = false;

  Future<void> _register() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    final auth = context.read<AuthProvider>();
    final err = await auth.register(_name.text.trim(), _email.text.trim(), _phone.text.trim(), _pw.text);
    if (!mounted) return;
    setState(() => _loading = false);
    if (err != null) {
      snack(context, err);
      return;
    }
    if (auth.loggedIn) {
      goToLanding(context);
    } else {
      // Happens when "Confirm email" is turned on in Supabase
      snack(context, 'Account created! Please confirm your email, then log in.');
      Navigator.pop(context);
    }
  }

  Widget _field(TextEditingController c, String label, IconData icon,
      {bool obscure = false, TextInputType? type, String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: c,
        obscureText: obscure,
        keyboardType: type,
        decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
        validator: validator ?? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Form(
                  key: _form,
                  child: Column(children: [
                    _field(_name, 'Full Name', Icons.person_outline),
                    _field(_email, 'Email', Icons.email_outlined,
                        type: TextInputType.emailAddress,
                        validator: (v) => (v == null || !v.contains('@')) ? 'Enter a valid email' : null),
                    _field(_phone, 'Phone Number', Icons.phone_outlined, type: TextInputType.phone),
                    _field(_pw, 'Password', Icons.lock_outline,
                        obscure: true,
                        validator: (v) => (v == null || v.length < 6) ? 'At least 6 characters' : null),
                    _field(_pw2, 'Confirm Password', Icons.lock_outline,
                        obscure: true,
                        validator: (v) => v != _pw.text ? 'Passwords do not match' : null),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _loading ? null : _register,
                        child: _loading
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Text('Create Account'),
                      ),
                    ),
                  ]),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
