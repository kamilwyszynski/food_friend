from sqlalchemy import Column, Integer, String, Text
from ..models.base import Base
from ..schemas.recipe import RecipeResponse, Ingredient
import json

class Recipe(Base):
    __tablename__ = "recipes"

    id = Column(Integer, primary_key=True)
    name = Column(String)
    ingredients = Column(Text)
    instructions = Column(Text)
    cook_time = Column(Integer)
    # Store Supabase user sub (string)
    user_id = Column(String)

    def __init__(self, name, ingredients, instructions, cook_time, user_id=""):
        self.name = name
        self.ingredients = ingredients
        self.instructions = instructions
        self.cook_time = cook_time
        self.user_id = user_id

    @staticmethod
    def from_response(response: RecipeResponse):
        # Store as JSON strings (canonical format)
        ingredients_data = [
            {
                "name": ingredient.name,
                "quantity": ingredient.quantity,
                "unit": ingredient.unit,
            }
            for ingredient in response.ingredients
        ]

        return Recipe(
            name=response.name,
            ingredients=json.dumps(ingredients_data),
            instructions=json.dumps([
                step for step in response.instructions
                if isinstance(step, str) and step.strip()
            ]),
            cook_time=response.cook_time,
            user_id="",
        )

    def to_response(self) -> RecipeResponse:
        """Convert Recipe model to RecipeResponse using JSON-only storage."""
        ingredients_data = json.loads(self.ingredients) if self.ingredients else []
        ingredients = [Ingredient(**ingredient) for ingredient in ingredients_data]

        instructions = json.loads(self.instructions) if self.instructions else []

        return RecipeResponse(
            name=self.name or "Unnamed Recipe",
            ingredients=ingredients,
            instructions=instructions,
            cook_time=self.cook_time or 0,
            id=self.id,
        )


