from fastapi import APIRouter, File, UploadFile
from ..services.recipe import RecipeService

router = APIRouter(prefix="/recipe", tags=["recipe"])

@router.post("/generate/base64")
def generate_recipe_from_base64(image_base64: str):
    service = RecipeService()
    return {"recipe": service.generate_recipe_from_base64(image_base64)}

@router.post("/generate/upload")
async def generate_recipe_from_upload(file: UploadFile = File(...)):
    service = RecipeService()
    image_bytes = await file.read()
    return {"recipe": service.generate_recipe_from_image_bytes(image_bytes)}

@router.get("/history")
def get_recipe_history():
    service = RecipeService()
    recipes = service.get_all_recipes()
    return {"recipes": [recipe.to_response().to_dict() for recipe in recipes]}