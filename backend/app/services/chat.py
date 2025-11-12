import uuid
from typing import Optional, Tuple

from fastapi import HTTPException

from ..services.session import SessionService
from ..agents.base import BaseAgent


class ChatService:
    """
    Orchestrates a single chat turn:
    - Ensures a session exists (via SessionService)
    - Builds contextual system prompt
    - Invokes the provided agent
    - Extracts a plain-text assistant response

    Returns: (response_text, session_id, is_new_session)
    """

    def __init__(self):
        self.session_service = SessionService()

    async def handle_message(
        self,
        *,
        message: str,
        user_id: str,
        user_name: Optional[str] = None,
        session_id: Optional[str],
        agent: BaseAgent,
    ) -> Tuple[str, str, bool]:
        # Resolve or create session
        is_new_session = False
        if not session_id:
            session_id = str(uuid.uuid4())
            thread_id = f"{user_id}_{session_id}"
            self.session_service.create_session(session_id=session_id, thread_id=thread_id, user_id=user_id)
            is_new_session = True
        else:
            sess = self.session_service.get_session(session_id)
            if sess is None:
                raise HTTPException(status_code=404, detail="Session not found")
            thread_id = sess.thread_id

        # Build user-bound tool wrappers by providing override_tools dynamically
        # Instead of passing user_id in the prompt, we wrap tools at call-time in a stateless way
        from ..agents.tools.recipe import (
            search_recipes as _search_recipes,
            list_user_recipes as _list_user_recipes,
            clone_recipe as _clone_recipe,
            generate_recipe as _generate_recipe,
            update_recipe as _update_recipe,
            generate_recipe_from_image as _generate_recipe_from_image,
            save_recipe as _save_recipe,
            capture_recipe as _capture_recipe,
        )

        # Create wrappers that close over user_id for tools that require it
        from langchain_core.tools import tool

        @tool
        def search_recipes(query: str) -> list:
            """Search the current user's recipes by free-text query."""
            return _search_recipes.func(query=query, user_id=user_id)

        @tool
        def list_user_recipes() -> list:
            """List all recipes belonging to the current user."""
            return _list_user_recipes.func(user_id=user_id)

        @tool
        def clone_recipe(recipe_id: int) -> dict:
            """Clone a recipe by id into the current user's collection."""
            return _clone_recipe.func(recipe_id=recipe_id, user_id=user_id)

        @tool
        def generate_recipe_from_image(base64_image: str) -> dict:
            """Generate a recipe from a base64-encoded image for the current user."""
            return _generate_recipe_from_image.func(base64_image=base64_image, user_id=user_id)

        @tool
        def save_recipe(recipe_json: str) -> dict:
            """Save a recipe JSON for the current user."""
            return _save_recipe.func(recipe_json=recipe_json, user_id=user_id)

        @tool
        def capture_recipe(recipe_json: str) -> dict:
            """Capture a preview-only recipe and return {id,name,cook_time}."""
            return _capture_recipe.func(recipe_json=recipe_json)

        # Tools that don't need user id are passed as-is
        override_tools = [
            search_recipes,
            list_user_recipes,
            _generate_recipe,
            generate_recipe_from_image,
            _update_recipe,
            clone_recipe,
            save_recipe,
            capture_recipe,
        ]

        result = await agent.run(
            message,
            thread_id=thread_id,
            user_name=user_name,
            override_tools=override_tools,
        )

        # Extract a plain-text assistant response from LangGraph result
        response_text = None
        try:
            # Case A: dict state with messages list (could be dicts or LC message objects)
            if isinstance(result, dict) and "messages" in result:
                msgs = result.get("messages", [])
                for m in reversed(msgs):
                    # dict style
                    if isinstance(m, dict):
                        role = m.get("role")
                        if role == "assistant":
                            response_text = m.get("content")
                            if isinstance(response_text, str):
                                break
                    else:
                        # object style (e.g., AIMessage/HumanMessage)
                        role = getattr(m, "role", None)
                        mtype = getattr(m, "type", None)
                        if role == "assistant" or mtype == "ai":
                            content = getattr(m, "content", None)
                            if isinstance(content, str):
                                response_text = content
                                break
            # Fallback: raw object repr
            if not response_text:
                # Try to stringify content field if present
                content = getattr(result, "content", None)
                if isinstance(content, str):
                    response_text = content
            if not response_text:
                response_text = str(result)
        except Exception:
            response_text = str(result)

        return response_text, session_id, is_new_session


