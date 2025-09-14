import os
from dotenv import load_dotenv
from fastapi import FastAPI
from app.routers import recipe

load_dotenv()
print(f"DATABASE_URL: {os.getenv('DATABASE_URL')}")  # Should print your DB URL

from app.services.recipe import RecipeService
from app.models.base import Base
from app.database import engine

Base.metadata.create_all(bind=engine)

app = FastAPI()
app.include_router(recipe.router, prefix="/api/v1")

if __name__ == "__main__":
    recipe_service = RecipeService()

    print(os.getcwd())

    print(10*'=', 'With image', 10*'=')
    print(recipe_service.generate_recipe_from_image_path("../test_photos/test1.png"))