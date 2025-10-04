from pydantic import BaseModel


class PreferencesResponse(BaseModel):
    cooking_skill: str
    dietary_restriction: str
    allergies: str


class PreferencesUpsert(BaseModel):
    cooking_skill: str
    dietary_restriction: str
    allergies: str




