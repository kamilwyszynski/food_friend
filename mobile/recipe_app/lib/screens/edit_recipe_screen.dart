import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/recipe.dart';
import '../services/recipe_service.dart';

class EditRecipeScreen extends StatefulWidget {
  final Recipe recipe;

  const EditRecipeScreen({super.key, required this.recipe});

  @override
  State<EditRecipeScreen> createState() => _EditRecipeScreenState();
}

class _EditRecipeScreenState extends State<EditRecipeScreen> {
  final _formKey = GlobalKey<FormState>();

  late String _name;
  late String _cookTimeText;
  late List<_EditableIngredient> _ingredients;
  late List<String> _steps;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _name = widget.recipe.name;
    _cookTimeText = widget.recipe.cookTime.toString();
    _ingredients = widget.recipe.ingredients
        .map((i) => _EditableIngredient(name: i.name, quantity: i.quantity, unit: i.unit))
        .toList();
    _steps = List<String>.from(widget.recipe.instructions);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Recipe'),
        backgroundColor: Colors.orange.shade300,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.save),
            onPressed: _saving ? null : _onSave,
          )
        ],
      ),
      backgroundColor: Colors.orange.shade50,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  initialValue: _name,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                  onChanged: (v) => _name = v,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: _cookTimeText,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Cook time (minutes)'),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return null; // optional
                    return int.tryParse(v) == null ? 'Enter a valid number' : null;
                  },
                  onChanged: (v) => _cookTimeText = v,
                ),
                const SizedBox(height: 24),
                _buildSection(
                  title: 'Ingredients',
                  child: Column(
                    children: [
                      for (int i = 0; i < _ingredients.length; i++) _buildIngredientRow(i),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _ingredients.add(_EditableIngredient(name: '', quantity: '', unit: ''));
                            });
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Add ingredient'),
                        ),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _buildSection(
                  title: 'Steps',
                  child: Column(
                    children: [
                      for (int i = 0; i < _steps.length; i++) _buildStepRow(i),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _steps.add('');
                            });
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Add step'),
                        ),
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.brown.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.brown,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildIngredientRow(int index) {
    final ing = _ingredients[index];
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: TextFormField(
              initialValue: ing.quantity,
              decoration: const InputDecoration(labelText: 'Quantity'),
              onChanged: (v) => ing.quantity = v,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: TextFormField(
              initialValue: ing.unit,
              decoration: const InputDecoration(labelText: 'Unit'),
              onChanged: (v) => ing.unit = v,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 4,
            child: TextFormField(
              initialValue: ing.name,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              onChanged: (v) => ing.name = v,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            color: Colors.red.shade400,
            onPressed: () {
              setState(() {
                _ingredients.removeAt(index);
              });
            },
          )
        ],
      ),
    );
  }

  Widget _buildStepRow(int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: TextFormField(
              initialValue: _steps[index],
              decoration: InputDecoration(labelText: 'Step ${index + 1}'),
              onChanged: (v) => _steps[index] = v,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            color: Colors.red.shade400,
            onPressed: () {
              setState(() {
                _steps.removeAt(index);
              });
            },
          )
        ],
      ),
    );
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;
    final cook = int.tryParse(_cookTimeText.trim());

    final updated = Recipe(
      id: widget.recipe.id,
      name: _name.trim(),
      cookTime: cook ?? 0,
      ingredients: _ingredients
          .map((e) => Ingredient(name: e.name.trim(), quantity: e.quantity.trim(), unit: e.unit.trim()))
          .toList(),
      instructions: _steps.map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
    );

    if (updated.id == null) {
      // Should not happen for persisted recipes; treat as no-op
      if (mounted) Navigator.of(context).pop(updated);
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final service = RecipeService();
      final saved = await service.updateRecipe(updated.id!, updated);
      if (mounted) Navigator.of(context).pop(saved);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save: $e')),
      );
      setState(() {
        _saving = false;
      });
    }
  }
}

class _EditableIngredient {
  String name;
  String quantity;
  String unit;

  _EditableIngredient({required this.name, required this.quantity, required this.unit});
}


