from sqlalchemy import Column, Integer, String, Text
from ..models.base import Base
from ..schemas.recipe import RecipeResponse

class Recipe(Base):
    __tablename__ = "recipes"

    id = Column(Integer, primary_key=True)
    name = Column(String)
    ingredients = Column(Text)
    instructions = Column(Text)
    cook_time = Column(Integer)
    user_id = Column(Integer)

    def __init__(self, name, ingredients, instructions, cook_time, user_id=-1):
        self.name = name
        self.ingredients = ingredients
        self.instructions = instructions
        self.cook_time = cook_time
        self.user_id = user_id

    @staticmethod
    def from_response(response: RecipeResponse):
        return Recipe(
            name=response.name,
            ingredients=str(response.ingredients),
            instructions=response.instructions,
            cook_time=response.cook_time,
            user_id=-1
        )


