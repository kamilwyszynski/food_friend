from ..database import Session as DBSession
from ..models.session import Session
from datetime import datetime
import uuid
import os
from openai import OpenAI


class SessionService:
    def __init__(self):
        self.client = OpenAI()

    def create_session(self, session_id: str, thread_id: str, user_id: str) -> Session:
        with DBSession() as db:
            sess = Session(id=session_id, thread_id=thread_id, user_id=user_id, title=None)
            db.add(sess)
            db.commit()
            db.refresh(sess)
            return sess

    def get_session(self, session_id: str) -> Session | None:
        with DBSession() as db:
            return db.query(Session).filter(Session.id == session_id).first()

    def list_user_sessions(self, user_id: str) -> list[Session]:
        with DBSession() as db:
            return db.query(Session).filter(Session.user_id == user_id).order_by(Session.updated_at.desc()).all()

    async def generate_and_update_title(self, session_id: str, first_message: str) -> None:
        # New DB session for background task
        with DBSession() as db:
            title = "New Chat"
            try:
                # Very small prompt to generate concise title
                prompt = (
                    "Generate a very short, 4-6 word title summarizing this chat message: "
                    + first_message[:512]
                )
                response = self.client.chat.completions.create(
                    model=os.getenv("OPENAI_MODEL"),
                    messages=[{"role": "user", "content": prompt}],
                    temperature=0.3,
                    max_tokens=16,
                )
                cand = response.choices[0].message.content.strip()
                if cand:
                    title = cand
            except Exception:
                # Leave default title
                pass

            sess = db.query(Session).filter(Session.id == session_id).first()
            if sess is not None:
                sess.title = title
                sess.updated_at = datetime.utcnow()
                db.add(sess)
                db.commit()


