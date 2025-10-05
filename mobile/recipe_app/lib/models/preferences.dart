class Preferences {
  final String cookingSkill;
  final String dietaryRestriction;
  final String allergies;

  Preferences({
    required this.cookingSkill,
    required this.dietaryRestriction,
    required this.allergies,
  });

  factory Preferences.fromJson(Map<String, dynamic> json) {
    return Preferences(
      cookingSkill: json['cooking_skill'] as String? ?? '',
      dietaryRestriction: json['dietary_restriction'] as String? ?? '',
      allergies: json['allergies'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'cooking_skill': cookingSkill,
        'dietary_restriction': dietaryRestriction,
        'allergies': allergies,
      };
}




