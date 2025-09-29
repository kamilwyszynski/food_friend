from ..database import Session
from ..models.preferences import Preferences
from ..schemas.preferences import PreferencesUpsert


class PreferencesService:
    def get_by_user(self, user_id: str) -> Preferences | None:
        with Session() as db:
            return db.query(Preferences).filter(Preferences.user_id == user_id).first()

    def upsert_for_user(self, user_id: str, data: PreferencesUpsert) -> Preferences:
        with Session() as db:
            prefs = db.query(Preferences).filter(Preferences.user_id == user_id).first()
            if prefs is None:
                prefs = Preferences(
                    user_id=user_id,
                    cooking_skill=data.cooking_skill,
                    dietary_restriction=data.dietary_restriction,
                    allergies=data.allergies,
                )
                db.add(prefs)
            else:
                prefs.cooking_skill = data.cooking_skill
                prefs.dietary_restriction = data.dietary_restriction
                prefs.allergies = data.allergies

            db.commit()
            db.refresh(prefs)
            return prefs



