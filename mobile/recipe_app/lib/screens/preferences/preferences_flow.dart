import 'package:flutter/material.dart';
import '../../models/preferences.dart';
import '../../services/preferences_service.dart';
import '../capture_screen.dart';
import '../home_shell.dart';
import 'skill_screen.dart';
import 'diet_screen.dart';
import 'allergies_screen.dart';

class PreferencesFlow extends StatefulWidget {
  const PreferencesFlow({super.key});

  @override
  State<PreferencesFlow> createState() => _PreferencesFlowState();
}

class _PreferencesFlowState extends State<PreferencesFlow> {
  String _skill = '';
  String _diet = '';
  String _allergies = '';
  bool _saving = false;

  void _skip() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeShell()),
      (route) => false,
    );
  }

  Future<void> _submit() async {
    setState(() => _saving = true);
    try {
      final service = PreferencesService();
      await service.upsertMyPreferences(Preferences(
        cookingSkill: _skill,
        dietaryRestriction: _diet,
        allergies: _allergies,
      ));
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeShell()),
        (route) => false,
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_saving) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.orange)),
      );
    }
    return SkillScreen(
      initial: _skill,
      onNext: (value) {
        setState(() => _skill = value);
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => DietScreen(
              initial: _diet,
              onBack: () => Navigator.of(context).pop(),
              onNext: (diet) {
                setState(() => _diet = diet);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AllergiesScreen(
                      initial: _allergies,
                      onBack: () => Navigator.of(context).pop(),
                      onSubmit: (a) {
                        setState(() => _allergies = a);
                        _submit();
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
      onSkip: _skip,
    );
  }
}


