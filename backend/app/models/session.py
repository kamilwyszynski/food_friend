from sqlalchemy import Column, String, DateTime
from datetime import datetime
from ..models.base import Base


class Session(Base):
    __tablename__ = "sessions"

    # Our session id (UUID as string)
    id = Column(String, primary_key=True)

    # LangGraph thread id used for checkpointing
    thread_id = Column(String, unique=True, index=True)

    # Supabase user sub/id (string)
    user_id = Column(String, index=True)

    # Optional AI-generated title
    title = Column(String, nullable=True)

    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)


