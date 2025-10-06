from abc import ABC, abstractmethod
from ..database import checkpointer
import asyncio
from functools import partial


class BaseAgent(ABC):
    def __init__(self, tools: list):
        self.checkpointer = checkpointer
        self.tools = tools
        self.graph = self._build_graph()

    @abstractmethod
    def _build_graph(self):
        pass

    async def run(self, message: str, thread_id: str, system_prompt: str | None = None):
        config = {"configurable": {"thread_id": thread_id}}
        messages = []
        if system_prompt:
            messages.append({"role": "system", "content": system_prompt})
        messages.append({"role": "user", "content": message})

        # Use sync invoke inside a thread to be compatible with sync PostgresSaver
        loop = asyncio.get_running_loop()
        fn = partial(self.graph.invoke, {"messages": messages}, config)
        result = await loop.run_in_executor(None, fn)
        return result

