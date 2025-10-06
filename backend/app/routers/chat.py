from fastapi import APIRouter, Depends, BackgroundTasks, HTTPException
from typing import Optional
from ..auth import get_current_user
from ..agents.recipe_agent import RecipeAgent
from ..services.session import SessionService
from ..schemas.chat import ChatRequest, ChatResponse
import uuid


router = APIRouter(prefix="/chat", tags=["chat"])


@router.post("/", response_model=ChatResponse)
async def chat_endpoint(payload: ChatRequest, background_tasks: BackgroundTasks, user=Depends(get_current_user)):
    # Resolve user id (Supabase)
    user_id = None
    if isinstance(user, dict):
        user_id = user.get("id") or user.get("sub")
    else:
        user_id = getattr(user, "id", None) or getattr(user, "sub", None)
    if not user_id:
        raise HTTPException(status_code=401, detail="Unauthorized")

    session_service = SessionService()

    is_new_session = False
    if not payload.session_id:
        session_id = str(uuid.uuid4())
        thread_id = f"{user_id}_{session_id}"
        session_service.create_session(session_id=session_id, thread_id=thread_id, user_id=user_id)
        is_new_session = True
    else:
        sess = session_service.get_session(payload.session_id)
        if sess is None:
            raise HTTPException(status_code=404, detail="Session not found")
        session_id = payload.session_id
        thread_id = sess.thread_id

    agent = RecipeAgent()
    system_prompt = (
        f"User ID: {user_id}. You are Sous Chef."
        " Use the available tools to search, fetch, or edit recipes as needed."
        " When a tool requires user_id, pass the value provided in the system message."
    )
    result = await agent.run(payload.message, thread_id=thread_id, system_prompt=system_prompt)

    # Best-effort: extract final assistant text from LangGraph result
    response_text = None
    try:
        if isinstance(result, dict) and "messages" in result:
            # Expect last message is assistant
            msgs = result.get("messages", [])
            for m in reversed(msgs):
                if m.get("role") == "assistant":
                    response_text = m.get("content")
                    break
        if response_text is None:
            # Fallback to str(result)
            response_text = str(result)
    except Exception:
        response_text = str(result)

    if is_new_session:
        background_tasks.add_task(session_service.generate_and_update_title, session_id, payload.message)

    return ChatResponse(response=response_text, session_id=session_id)


