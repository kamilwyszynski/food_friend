import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config.dart';
import '../models/recipe.dart';
import 'api_client.dart';

class RecipeService {
  final ApiClient _api = ApiClient();

  Future<Recipe> generateRecipeFromImage(String imagePath) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/recipe/generate/upload');
    final file = await http.MultipartFile.fromPath('file', imagePath);
    final response = await _api.postMultipart(
      uri,
      files: [file],
    );
    
    if (response.statusCode == 200) {
      final responseBody = await response.stream.bytesToString();
      final jsonMap = jsonDecode(responseBody);
      final recipeJson = jsonMap['recipe'] as Map<String, dynamic>;
      return Recipe.fromJson(recipeJson);
    } else {
      throw Exception('Failed to generate recipe: ${response.statusCode}');
    }
  }

  Future<List<Recipe>> getRecipeHistory() async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/recipe/history');
    final response = await _api.get(uri);
    
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final recipesList = json['recipes'] as List;
      
      return recipesList.map((recipeJson) => Recipe.fromJson(recipeJson)).toList();
    } else {
      throw Exception('Failed to fetch recipe history: ${response.statusCode}');
    }
  }

  Future<Recipe> updateRecipe(int id, Recipe recipe) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/recipe/$id');

    final payload = {
      'name': recipe.name,
      'ingredients': recipe.ingredients
          .map((i) => {'name': i.name, 'quantity': i.quantity, 'unit': i.unit})
          .toList(),
      'instructions': recipe.instructions,
      'cook_time': recipe.cookTime,
    };

    final response = await _api.put(
      uri,
      headers: { 'Content-Type': 'application/json' },
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200) {
      final jsonMap = jsonDecode(response.body) as Map<String, dynamic>;
      return Recipe.fromJson(jsonMap);
    } else {
      throw Exception('Failed to update recipe: ${response.statusCode}');
    }
  }

  Future<List<Recipe>> searchRecipes(String query) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/recipe/search?q=${Uri.encodeQueryComponent(query)}');
    final response = await _api.get(uri);
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final recipesList = json['recipes'] as List;
      return recipesList.map((recipeJson) => Recipe.fromJson(recipeJson)).toList();
    } else {
      throw Exception('Failed to search recipes: ${response.statusCode}');
    }
  }
}
