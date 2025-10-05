import 'package:flutter/material.dart';
import '../services/recipe_service.dart';
import '../models/recipe.dart';
import 'result_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool _isLoading = true;
  List<Recipe> _recipes = [];
  String? _error;
  String _query = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadRecipeHistory();
  }

  Future<void> _loadRecipeHistory() async {
    try {
      final recipeService = RecipeService();
      final recipes = await recipeService.getRecipeHistory();
      
      if (mounted) {
        setState(() {
          _recipes = recipes;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load recipes: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _performSearch(String q) async {
    setState(() {
      _query = q;
    });
    if (q.trim().isEmpty) {
      await _loadRecipeHistory();
      return;
    }
    try {
      final recipeService = RecipeService();
      final results = await recipeService.searchRecipes(q);
      if (mounted) {
        setState(() {
          _recipes = results;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to search: $e';
        });
      }
    }
  }

  void _onRecipeTap(Recipe recipe) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResultScreen.fromRecipe(existingRecipe: recipe),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange.shade50,
      appBar: AppBar(
        title: const Text('Your Recipes'),
        backgroundColor: Colors.orange.shade300,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search recipes...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (value) {
                  if (value.trim().isEmpty && _query.isNotEmpty) {
                    _performSearch('');
                  }
                },
                onSubmitted: _performSearch,
                textInputAction: TextInputAction.search,
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: Colors.orange),
                          SizedBox(height: 16),
                          Text(
                            'Loading your recipes...',
                            style: TextStyle(fontSize: 16, color: Colors.brown),
                          ),
                        ],
                      ),
                    )
                  : _error != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  size: 64,
                                  color: Colors.orange,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _error!,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 16,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      _isLoading = true;
                                      _error = null;
                                    });
                                    _loadRecipeHistory();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange.shade300,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : _recipes.isEmpty
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.book_outlined,
                                      size: 64,
                                      color: Colors.orange,
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      'No recipes yet!',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.brown,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Take a photo of some ingredients to create your first recipe.',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.brown,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : RefreshIndicator(
                              color: Colors.orange,
                              onRefresh: _loadRecipeHistory,
                              child: ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: _recipes.length,
                                itemBuilder: (context, index) {
                                  final recipe = _recipes[index];
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.all(16),
                                      leading: Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color: Colors.orange.shade300,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.restaurant,
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                      ),
                                      title: Text(
                                        recipe.name,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.brown,
                                        ),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 4),
                                          Text(
                                            '${recipe.ingredients.length} ingredients',
                                            style: TextStyle(
                                              color: Colors.brown.shade600,
                                              fontSize: 14,
                                            ),
                                          ),
                                          if (recipe.cookTime > 0) ...[
                                            const SizedBox(height: 2),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.timer,
                                                  size: 14,
                                                  color: Colors.orange.shade400,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '${recipe.cookTime} min',
                                                  style: TextStyle(
                                                    color: Colors.brown.shade600,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ],
                                      ),
                                      trailing: const Icon(
                                        Icons.arrow_forward_ios,
                                        color: Colors.orange,
                                        size: 16,
                                      ),
                                      onTap: () => _onRecipeTap(recipe),
                                    ),
                                  );
                                },
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }
}
