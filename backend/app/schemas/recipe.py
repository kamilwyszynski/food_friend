from pydantic import BaseModel

class Ingredient(BaseModel):
    name: str
    quantity: str
    unit: str
    
    def __str__(self) -> str:
        return f"{self.quantity} {self.unit} of {self.name}"

class RecipeResponse(BaseModel):
    name: str
    ingredients: list[Ingredient]
    instructions: list[str]
    cook_time: int