from langchain_core.tools import tool
from ...services.recipe import RecipeService
from ...schemas.recipe import RecipeResponse, Ingredient
import json


@tool
def search_recipes(query: str, user_id: str) -> list:
    """
    Search the user's saved recipes by name, ingredients, or instructions.
    """
    service = RecipeService()
    results = service.search_recipes(query, user_id)
    return [r.to_response().to_dict() for r in results]


@tool
def list_user_recipes(user_id: str) -> list:
    """
    List all recipes for the given user.
    """
    service = RecipeService()
    results = service.get_all_recipes(user_id)
    return [r.to_response().to_dict() for r in results]


@tool
def generate_recipe(ingredients: str) -> str:
    """
    Generate a recipe from a free-text list of ingredients.
    Returns textual recipe representation.
    """
    service = RecipeService()
    return service.generate_recipe(ingredients)


@tool
def generate_recipe_from_image(base64_image: str, user_id: str | None = None) -> dict:
    """
    Generate and save a recipe from a base64-encoded image. Optionally attribute to user.
    """
    service = RecipeService()
    return service.generate_recipe_from_base64(base64_image, user_id)


@tool
def update_recipe(recipe_id: int, updated_json: str) -> dict:
    """
    Update an existing recipe by id with JSON payload matching RecipeResponse.
    Returns updated recipe dict.
    """
    data = json.loads(updated_json)
    ingredients = [Ingredient(**i) for i in data.get("ingredients", [])]
    updated = RecipeResponse(
        id=data.get("id"),
        name=data.get("name"),
        ingredients=ingredients,
        instructions=data.get("instructions", []),
        cook_time=data.get("cook_time", 0),
    )
    service = RecipeService()
    result = service.update_recipe(recipe_id, updated)
    return result.to_dict()


@tool
def clone_recipe(recipe_id: int, user_id: str) -> dict:
    """
    Clone an existing recipe into the user's collection.
    """
    service = RecipeService()
    return service.clone_recipe(recipe_id, user_id).to_dict()


@tool
def save_recipe(recipe_json: str, user_id: str) -> dict:
    """
    Save a recipe for the current user from a JSON string matching RecipeResponse fields.
    """
    service = RecipeService()
    data = json.loads(recipe_json)
    return service.create_recipe(data, user_id).to_dict()


@tool
def capture_recipe(recipe_json: str) -> dict:
    """
    Persist a preview-only recipe (no owner) and return a minimal summary: {id,name,cook_time}.
    """
    service = RecipeService()
    data = json.loads(recipe_json)
    return service.create_preview_recipe(data)


