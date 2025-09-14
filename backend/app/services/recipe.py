import os
import base64
import json
from openai import OpenAI
from ..schemas.recipe import RecipeResponse
from ..models.recipe import Recipe
from ..database import Session

def encode_image(image_path):
    with open(image_path, "rb") as image_file:
        return base64.b64encode(image_file.read()).decode("utf-8")

def encode_image_bytes(image_bytes):
    return base64.b64encode(image_bytes).decode("utf-8")

class RecipeService:
    def __init__(self):
        self.client = OpenAI()

    def save_recipe(self, recipe: Recipe):
        with Session() as db:
            db.add(recipe)
            db.commit()
            db.refresh(recipe)

    def get_all_recipes(self, user_id: int = -1) -> list[Recipe]:
        with Session() as db:
            return db.query(Recipe).filter(Recipe.user_id == user_id).all()

    def generate_recipe(self, ingredients: str) -> str:

        response = self.client.responses.parse(
            model=os.getenv("OPENAI_MODEL"),
            input="You're a wholesome recipe generator. Generate a recipe for the following ingredients: " + ingredients,
            text_format=RecipeResponse
        )

        return response.output_text
    
    def generate_recipe_from_base64(self, base64_image: str) -> str:
        """Base method that generates recipe from base64 encoded image"""
        response = self.client.responses.parse(
            model=os.getenv("OPENAI_MODEL"),
            input=[{
                "role": "user",
                "content": [
                    {"type": "input_text", "text": "You're a wholesome recipe generator. Generate a recipe for one meal for one person using the ingredients shown on the image the user just took. Try to adjust it for quantities for the ingredients in the image."},
                    {"type": "input_image", "image_url": f"data:image/jpeg;base64,{base64_image}", "detail": "high"}
                ]
            }],
            text_format=RecipeResponse
        )

        recipe = Recipe.from_response(response.output_parsed)
        
        self.save_recipe(recipe)
        
        # Return a serializable recipe object with id included
        return recipe.to_response().to_dict()

    def generate_recipe_from_image_path(self, image_path: str) -> str:
        """Wrapper that encodes image from file path"""
        encoded_image = encode_image(image_path)
        return self.generate_recipe_from_base64(encoded_image)

    def generate_recipe_from_image_bytes(self, image_bytes: bytes) -> str:
        """Wrapper that encodes image from bytes"""
        encoded_image = encode_image_bytes(image_bytes)
        return self.generate_recipe_from_base64(encoded_image)

    def update_recipe(self, recipe_id: int, updated: RecipeResponse) -> RecipeResponse:
        """Update an existing recipe with new fields and return updated response."""
        with Session() as db:
            recipe: Recipe | None = db.query(Recipe).filter(Recipe.id == recipe_id).first()
            if recipe is None:
                raise ValueError(f"Recipe with id {recipe_id} not found")

            # Update basic fields
            recipe.name = updated.name
            recipe.cook_time = updated.cook_time

            # Serialize ingredients and instructions to JSON strings
            ingredients_data = [
                {"name": i.name, "quantity": i.quantity, "unit": i.unit}
                for i in updated.ingredients
            ]
            instructions_data = [s for s in updated.instructions if isinstance(s, str)]

            recipe.ingredients = json.dumps(ingredients_data)
            recipe.instructions = json.dumps(instructions_data)

            db.add(recipe)
            db.commit()
            db.refresh(recipe)

            return recipe.to_response()