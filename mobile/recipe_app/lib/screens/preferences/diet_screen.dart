import 'package:flutter/material.dart';

class DietScreen extends StatefulWidget {
  final String initial;
  final void Function(String value) onNext;
  final VoidCallback onBack;

  const DietScreen({
    super.key,
    required this.initial,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<DietScreen> createState() => _DietScreenState();
}

class _DietScreenState extends State<DietScreen> {
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack,
        ),
        title: const Text('Dietary restriction'),
        backgroundColor: Colors.orange.shade300,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Choose your dietary preference',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.brown),
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _chip('omnivore'),
                  _chip('vegetarian'),
                  _chip('vegan'),
                  _chip('pescatarian'),
                  _chip('other'),
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




