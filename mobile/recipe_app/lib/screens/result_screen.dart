import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import '../services/recipe_service.dart';
import '../models/recipe.dart';
import '../widgets/recipe_display.dart';
import 'edit_recipe_screen.dart';

class ResultScreen extends StatefulWidget {
  final String? imagePath;
  final Recipe? existingRecipe;

  const ResultScreen({super.key, required this.imagePath}) : existingRecipe = null;
  
  const ResultScreen.fromRecipe({super.key, required this.existingRecipe}) : imagePath = null;

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  bool _isLoading = true;
  Recipe? _recipe;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.existingRecipe != null) {
      // Display existing recipe from history
      _recipe = widget.existingRecipe;
      _isLoading = false;
    } else {
      // Generate new recipe from image
      _generateRecipe();
    }
  }

  Future<void> _generateRecipe() async {
    try {
      final recipeService = RecipeService();
      final recipe = await recipeService.generateRecipeFromImage(widget.imagePath!);
      
      if (mounted) {
        setState(() {
          _recipe = recipe;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to generate recipe: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange.shade50,
      appBar: AppBar(
        title: const Text('Your Recipe'),
        backgroundColor: Colors.orange.shade300,
        foregroundColor: Colors.white,
        actions: [
          if (!_isLoading && _recipe != null)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
                HapticFeedback.selectionClick();
                final updated = await Navigator.of(context).push<Recipe>(
                  MaterialPageRoute(
                    builder: (_) => EditRecipeScreen(recipe: _recipe!),
                  ),
                );
                if (updated != null && mounted) {
                  setState(() {
                    _recipe = updated;
                  });
                }
              },
            )
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image preview (only show if we have an image)
              if (widget.imagePath != null) ...[
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.brown.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(widget.imagePath!),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
              
              // Recipe content
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              color: Colors.orange,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Cooking up your recipe...',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.brown,
                              ),
                            ),
                          ],
                        ),
                      )
                    : _error != null
                        ? Center(
                            child: Text(
                              _error!,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          )
                        : Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 0),
                            child: RecipeDisplay(recipe: _recipe!),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
