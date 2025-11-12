from fastapi import APIRouter, Depends, BackgroundTasks, HTTPException
from typing import Optional
from ..auth import get_current_user
from ..agents.recipe_agent import RecipeAgent
from ..services.session import SessionService
from ..services.chat import ChatService
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
    chat_service = ChatService()
    agent = RecipeAgent()

    response_text, session_id, is_new_session = await chat_service.handle_message(
        message=payload.message,
        user_id=user_id,
        session_id=payload.session_id,
        agent=agent,
    )

    if is_new_session:
        background_tasks.add_task(session_service.generate_and_update_title, session_id, payload.message)

    return ChatResponse(response=response_text, session_id=session_id)


