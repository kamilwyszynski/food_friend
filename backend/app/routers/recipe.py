from fastapi import APIRouter, File, UploadFile, HTTPException
from ..services.recipe import RecipeService
from ..schemas.recipe import RecipeResponse

router = APIRouter(prefix="/recipe", tags=["recipe"])

@router.post("/generate/base64")
def generate_recipe_from_base64(image_base64: str):
    service = RecipeService()
    return {"recipe": service.generate_recipe_from_base64(image_base64)}

@router.post("/generate/upload")
async def generate_recipe_from_upload(file: UploadFile = File(...)):
    service = RecipeService()
    image_bytes = await file.read()
    # Return full saved recipe object instead of JSON string
    return {"recipe": service.generate_recipe_from_image_bytes(image_bytes)}

@router.get("/history")
def get_recipe_history():
    service = RecipeService()
    recipes = service.get_all_recipes()
    return {"recipes": [recipe.to_response().to_dict() for recipe in recipes]}

@router.put("/{recipe_id}")
def update_recipe(recipe_id: int, updated_recipe: RecipeResponse):
    service = RecipeService()
    try:
        updated = service.update_recipe(recipe_id, updated_recipe)
        return updated.to_dict()
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))