from langchain_core.tools import tool
from ...services.recipe import RecipeService


@tool
def search_recipes(query: str, user_id: str) -> list:
    """
    Search the user's saved recipes by name, ingredients, or instructions.

    Args:
        query: Free-text search string.
        user_id: Supabase user id/sub.

    Returns:
        List of matching recipes as dicts (id, name, ingredients, instructions, cook_time).
    """
    service = RecipeService()
    results = service.search_recipes(query, user_id)
    return [r.to_response().to_dict() for r in results]


