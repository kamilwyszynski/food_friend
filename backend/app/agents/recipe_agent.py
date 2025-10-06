import os
from .base import BaseAgent
from .tools.search_recipes import search_recipes
from langgraph.prebuilt import create_react_agent
from langchain_openai import ChatOpenAI


def init_chat_model():
    # Reuse OPENAI_MODEL for MVP
    model_name = os.getenv("OPENAI_MODEL") or "gpt-4o"
    return ChatOpenAI(model=model_name)


class RecipeAgent(BaseAgent):
    def __init__(self):
        tools = [search_recipes]
        super().__init__(tools=tools)

    def _build_graph(self):
        model = init_chat_model()
        system_prompt = (
            "You are Sous Chef, a helpful cooking assistant."
            " Always use tools when the user asks to search, retrieve, or modify recipes."
            " If a tool requires user_id, include it from the system context instructions."
        )
        return create_react_agent(
            model=model,
            tools=self.tools,
            checkpointer=self.checkpointer,
            prompt=system_prompt,
        )


