from sqlalchemy import Column, Integer, String, Text
from ..models.base import Base


class Preferences(Base):
    __tablename__ = "preferences"

    id = Column(Integer, primary_key=True)
    # Supabase user id/sub (string); one row per user
    user_id = Column(String, unique=True, index=True)

    # Cooking skill: beginner | skilled | professional (stored as string)
    cooking_skill = Column(String)

    # Dietary restriction: single free-text value
    dietary_restriction = Column(String)

    # Allergies: free text, ideally comma-separated
    allergies = Column(Text)


