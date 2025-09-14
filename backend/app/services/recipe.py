import os
import base64
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
            
        return response.output_text

    def generate_recipe_from_image_path(self, image_path: str) -> str:
        """Wrapper that encodes image from file path"""
        encoded_image = encode_image(image_path)
        return self.generate_recipe_from_base64(encoded_image)

    def generate_recipe_from_image_bytes(self, image_bytes: bytes) -> str:
        """Wrapper that encodes image from bytes"""
        encoded_image = encode_image_bytes(image_bytes)
        return self.generate_recipe_from_base64(encoded_image)