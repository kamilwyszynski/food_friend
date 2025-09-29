import os
from fastapi import Depends, Header, HTTPException, status
from supabase import create_client, Client

SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_SERVICE_ROLE_KEY = os.getenv("SUPABASE_SERVICE_ROLE_KEY")

if not SUPABASE_URL or not SUPABASE_SERVICE_ROLE_KEY:
    raise RuntimeError("Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY environment variables")

supabase: Client = create_client(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)

async def get_current_user(authorization: str = Header(None)):
    """
    Extracts the Bearer token and verifies it using Supabase Auth API.
    """

    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing or invalid Authorization header",
        )

    token = authorization.split(" ")[1]

    try:
        resp = supabase.auth.get_user(token)

        # Support both dict and object result forms
        user = resp.get("user") if isinstance(resp, dict) else getattr(resp, "user", None)
        if not user:
            raise HTTPException(status_code=401, detail="Invalid or expired token")

        return user  # dict-like object with user info

    except Exception as e:
        raise HTTPException(status_code=401, detail=f"Token verification failed: {e}")