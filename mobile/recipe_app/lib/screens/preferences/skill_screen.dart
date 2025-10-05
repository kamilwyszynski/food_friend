import 'package:flutter/material.dart';

class SkillScreen extends StatefulWidget {
  final String initial;
  final void Function(String value) onNext;
  final VoidCallback? onSkip;

  const SkillScreen({
    super.key,
    required this.initial,
    required this.onNext,
    this.onSkip,
  });

  @override
  State<SkillScreen> createState() => _SkillScreenState();
}

class _SkillScreenState extends State<SkillScreen> {
  String _selected = '';

  @override
  void initState() {
    super.initState();
    _selected = widget.initial;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange.shade50,
      appBar: AppBar(
        title: const Text('Cooking skill'),
        backgroundColor: Colors.orange.shade300,
        foregroundColor: Colors.white,
        actions: [
          if (widget.onSkip != null)
            TextButton(
              onPressed: widget.onSkip,
              child: const Text('Skip', style: TextStyle(color: Colors.white)),
            )
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'What is your cooking skill level?',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.brown),
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _chip('beginner'),
                  _chip('skilled'),
                  _chip('professional'),
                ],
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _selected.isEmpty ? null : () => widget.onNext(_selected),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Next'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(String value) {
    final isSelected = _selected == value;
    return ChoiceChip(
      label: Text(value[0].toUpperCase() + value.substring(1)),
      selected: isSelected,
      onSelected: (_) => setState(() => _selected = value),
      selectedColor: Colors.orange.shade300,
      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.brown),
    );
  }
}




