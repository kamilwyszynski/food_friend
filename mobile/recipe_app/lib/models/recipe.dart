class Ingredient {
  final String name;
  final String quantity;
  final String unit;

  Ingredient({
    required this.name,
    required this.quantity,
    required this.unit,
  });

  factory Ingredient.fromJson(Map<String, dynamic> json) {
    return Ingredient(
      name: json['name'] ?? '',
      quantity: json['quantity'] ?? '',
      unit: json['unit'] ?? '',
    );
  }

  @override
  String toString() {
    return '$quantity $unit of $name';
  }
}

class Recipe {
  final int? id;
  final String name;
  final List<Ingredient> ingredients;
  final List<String> instructions;
  final int cookTime;

  Recipe({
    this.id,
    required this.name,
    required this.ingredients,
    required this.instructions,
    required this.cookTime,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    var ingredientsList = json['ingredients'] as List? ?? [];
    var instructionsList = json['instructions'] as List? ?? [];

    return Recipe(
      id: json['id'],
      name: json['name'] ?? 'Unnamed Recipe',
      ingredients: ingredientsList
          .map((ingredient) => Ingredient.fromJson(ingredient))
          .toList(),
      instructions: instructionsList.cast<String>(),
      cookTime: json['cook_time'] ?? 0,
    );
  }
}
