from fastapi import APIRouter, Depends, HTTPException
from ..auth import get_current_user
from ..services.preferences import PreferencesService
from ..schemas.preferences import PreferencesUpsert, PreferencesResponse


router = APIRouter(prefix="/preferences", tags=["preferences"])


@router.get("/me", response_model=PreferencesResponse)
def get_my_preferences(user=Depends(get_current_user)):
    user_id = None
    if isinstance(user, dict):
        user_id = user.get("id") or user.get("sub")
    else:
        user_id = getattr(user, "id", None) or getattr(user, "sub", None)
    if not user_id:
        raise HTTPException(status_code=401, detail="Unauthorized")

    service = PreferencesService()
    prefs = service.get_by_user(user_id)
    if prefs is None:
        raise HTTPException(status_code=404, detail="Preferences not found")
    return PreferencesResponse(
        cooking_skill=prefs.cooking_skill or "",
        dietary_restriction=prefs.dietary_restriction or "",
        allergies=prefs.allergies or "",
    )


@router.put("/me", response_model=PreferencesResponse)
def upsert_my_preferences(payload: PreferencesUpsert, user=Depends(get_current_user)):
    user_id = None
    if isinstance(user, dict):
        user_id = user.get("id") or user.get("sub")
    else:
        user_id = getattr(user, "id", None) or getattr(user, "sub", None)
    if not user_id:
        raise HTTPException(status_code=401, detail="Unauthorized")

    service = PreferencesService()
    prefs = service.upsert_for_user(user_id, payload)
    return PreferencesResponse(
        cooking_skill=prefs.cooking_skill or "",
        dietary_restriction=prefs.dietary_restriction or "",
        allergies=prefs.allergies or "",
    )


