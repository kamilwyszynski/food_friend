import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/preferences_service.dart';
import '../models/preferences.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  Preferences? _prefs;
  String? _error;
  bool _isSigningOut = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final service = PreferencesService();
      final p = await service.getMyPreferences();
      if (!mounted) return;
      setState(() {
        _prefs = p;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load preferences: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange.shade50,
      appBar: AppBar(
        title: const Text('Your Profile'),
        backgroundColor: Colors.orange.shade300,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.orange))
            : _error != null
                ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
                : _prefs == null
                    ? const Center(child: Text('No preferences set yet'))
                    : Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _row(Icons.school, 'Cooking skill', _prefs!.cookingSkill),
                            const SizedBox(height: 12),
                            _row(Icons.restaurant, 'Dietary restriction', _prefs!.dietaryRestriction),
                            const SizedBox(height: 12),
                            _row(Icons.healing, 'Allergies', _prefs!.allergies.isEmpty ? 'None' : _prefs!.allergies),
                            const Spacer(),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _isSigningOut ? null : _onSignOut,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.red,
                                  side: BorderSide(color: Colors.red.shade200, width: 1.5),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                icon: _isSigningOut
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red),
                                      )
                                    : const Icon(Icons.logout),
                                label: Text(_isSigningOut ? 'Signing out...' : 'Log out'),
                              ),
                            ),
                          ],
                        ),
                      ),
      ),
    );
  }

  Widget _row(IconData icon, String title, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.brown.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.orange.shade400),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.brown)),
                const SizedBox(height: 4),
                Text(value, style: TextStyle(color: Colors.brown.shade700)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Future<void> _onSignOut() async {
    setState(() => _isSigningOut = true);
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to sign out: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSigningOut = false);
    }
  }
}




