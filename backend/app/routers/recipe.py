from fastapi import APIRouter, File, UploadFile, HTTPException, Depends
from ..services.recipe import RecipeService
from ..schemas.recipe import RecipeResponse
from ..auth import get_current_user

router = APIRouter(prefix="/recipe", tags=["recipe"])

@router.post("/generate/base64")
def generate_recipe_from_base64(image_base64: str, user=Depends(get_current_user)):
    service = RecipeService()
    user_id = None
    if isinstance(user, dict):
        user_id = user.get("id") or user.get("sub")
    else:
        user_id = getattr(user, "id", None) or getattr(user, "sub", None)
    return {"recipe": service.generate_recipe_from_base64(image_base64, user_id)}

@router.post("/generate/upload")
async def generate_recipe_from_upload(file: UploadFile = File(...), user=Depends(get_current_user)):
    service = RecipeService()
    image_bytes = await file.read()
    # Return full saved recipe object instead of JSON string
    user_id = None
    if isinstance(user, dict):
        user_id = user.get("id") or user.get("sub")
    else:
        user_id = getattr(user, "id", None) or getattr(user, "sub", None)
    return {"recipe": service.generate_recipe_from_image_bytes(image_bytes, user_id)}

@router.get("/history")
def get_recipe_history(user=Depends(get_current_user)):
    service = RecipeService()
    user_id = None
    if isinstance(user, dict):
        user_id = user.get("id") or user.get("sub")
    else:
        user_id = getattr(user, "id", None) or getattr(user, "sub", None)
    recipes = service.get_all_recipes(user_id)
    return {"recipes": [recipe.to_response().to_dict() for recipe in recipes]}

@router.put("/{recipe_id}")
def update_recipe(recipe_id: int, updated_recipe: RecipeResponse, user=Depends(get_current_user)):
    service = RecipeService()
    try:
        # Enforce ownership
        user_sub = user.get("sub") if isinstance(user, dict) else None
        from ..models.recipe import Recipe
        from ..database import Session
        with Session() as db:
            rec = db.query(Recipe).filter(Recipe.id == recipe_id).first()
            if rec is None:
                raise HTTPException(status_code=404, detail="Recipe not found")
            if rec.user_id and user_sub and rec.user_id != user_sub:
                raise HTTPException(status_code=403, detail="Forbidden")

        updated = service.update_recipe(recipe_id, updated_recipe)
        return updated.to_dict()
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))