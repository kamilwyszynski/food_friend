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
    id: int = None  # Optional for backwards compatibility
    
    def to_dict(self):
        """Convert RecipeResponse to dictionary for API response"""
        result = {
            "name": self.name,
            "ingredients": [
                {
                    "name": ingredient.name,
                    "quantity": ingredient.quantity,
                    "unit": ingredient.unit
                }
                for ingredient in self.ingredients
            ],
            "instructions": self.instructions,
            "cook_time": self.cook_time
        }
        
        if self.id is not None:
            result["id"] = self.id
            
        return result

class RecipeSchema(BaseModel):
    id: int
    name: str
    ingredients: list[Ingredient]
    instructions: list[str]
    cook_time: int
    user_id: str | None = None