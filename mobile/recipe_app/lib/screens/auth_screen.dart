import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart';
import 'check_email_screen.dart';
import '../services/preferences_service.dart';
import 'preferences/preferences_flow.dart';
import 'home_shell.dart';
import '../widgets/pressable.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';
  bool _isLoading = false;
  bool _isSignUp = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange.shade50,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _isSignUp ? 'Create account' : 'Sign in',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.brown,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Form(
                    key: _formKey,
                    child: AutofillGroup(
                      child: Column(
                        children: [
                          TextFormField(
                            decoration: const InputDecoration(labelText: 'Email'),
                            keyboardType: TextInputType.emailAddress,
                            autofillHints: const [AutofillHints.username, AutofillHints.email],
                            enableSuggestions: true,
                            autocorrect: false,
                            textInputAction: TextInputAction.next,
                            validator: (v) => (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
                            onChanged: (v) => _email = v,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            decoration: const InputDecoration(labelText: 'Password'),
                            obscureText: true,
                            autofillHints: const [AutofillHints.password],
                            textInputAction: TextInputAction.done,
                            validator: (v) => (v == null || v.length < 6) ? 'Min 6 characters' : null,
                            onChanged: (v) => _password = v,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Pressable(
                    enabled: !_isLoading,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _onSubmit();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: _isLoading ? Colors.orange.shade200 : Colors.orange,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(
                              _isSignUp ? 'Create account' : 'Sign in',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            HapticFeedback.selectionClick();
                            setState(() => _isSignUp = !_isSignUp);
                          },
                    child: Text(_isSignUp
                        ? 'Have an account? Sign in'
                        : 'No account? Create one'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final auth = Supabase.instance.client.auth;
    try {
      if (_isSignUp) {
        await auth.signUp(email: _email, password: _password);
        if (!mounted) return;
        FocusScope.of(context).unfocus();
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => CheckEmailScreen(email: _email),
          ),
        );
      } else {
        await auth.signInWithPassword(email: _email, password: _password);
        if (!mounted) return;
        try {
          final prefs = await PreferencesService().getMyPreferences();
          if (!mounted) return;
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => prefs != null ? const HomeShell() : const PreferencesFlow()),
            (route) => false,
          );
        } catch (_) {
          if (!mounted) return;
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const PreferencesFlow()),
            (route) => false,
          );
        }
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}




