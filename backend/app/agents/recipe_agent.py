import os
from .base import BaseAgent
from .tools.recipe import (
    search_recipes,
    list_user_recipes,
    generate_recipe,
    generate_recipe_from_image,
    update_recipe,
    clone_recipe,
    save_recipe,
    capture_recipe,
)
from langgraph.prebuilt import create_react_agent
from langchain_openai import ChatOpenAI
import asyncio
from functools import partial


def init_chat_model():
    # Reuse OPENAI_MODEL for MVP
    model_name = os.getenv("OPENAI_MODEL") or "gpt-4o"
    return ChatOpenAI(model=model_name)


class RecipeAgent(BaseAgent):
    def __init__(self):
        tools = [
            search_recipes,
            list_user_recipes,
            generate_recipe,
            generate_recipe_from_image,
            update_recipe,
            clone_recipe,
            save_recipe,
            capture_recipe,
        ]
        super().__init__(tools=tools)

    def _build_graph(self):
        model = init_chat_model()
        return create_react_agent(
            model=model,
            tools=self.tools,
            checkpointer=self.checkpointer,
        )

    async def run(self, message: str, thread_id: str, user_name: str | None = None, override_tools: list | None = None):
        # Build the entire system prompt inside the agent (single source of truth)
        system_prompt = (
            "You are Sous Chef, a helpful cooking assistant"
            + " and your goal is to help "
            + (user_name if user_name else "the user")
            + " with their cooking needs. "
            + "You want to be as helpful as possible while being playful at times in a concise manner. "
            + "The user might want to find their perfect recipe for today, be creative with their cooking, plan a friend dinner, or even just get some inspiration for their next meal. "
            + "Always use tools when the user asks to search, retrieve, or modify recipes."
            + " When you present a recipe, also include a fenced block so the app can render it:"
            + " ```recipe\n{ \"id\": <id> }\n```"
        )
        # If override_tools are provided, run with those tools (e.g., user-bound wrappers)
        if override_tools is not None:
            model = init_chat_model()
            graph = create_react_agent(
                model=model,
                tools=override_tools,
                checkpointer=self.checkpointer,
            )
            config = {"configurable": {"thread_id": thread_id}}
            messages = []
            messages.append({"role": "system", "content": system_prompt})
            messages.append({"role": "user", "content": message})
            loop = asyncio.get_running_loop()
            fn = partial(graph.invoke, {"messages": messages}, config)
            result = await loop.run_in_executor(None, fn)
            return result

        return await super().run(message, thread_id=thread_id, system_prompt=system_prompt)


