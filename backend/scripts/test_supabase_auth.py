"""
One-off test script to verify Supabase auth/JWKS using .env.

Usage (from repo root or backend dir):
  - With uv (recommended):
      cd backend && uv run python scripts/test_supabase_auth.py
  - Or using venv python:
      cd backend && python scripts/test_supabase_auth.py

Reads SUPABASE_URL or SUPABASE_PROJECT_REF and SUPABASE_ANON_KEY from .env.
Prints the JWKS URL, attempts a fetch (with headers), shows status and keys count.
If SUPABASE_TEST_TOKEN is set, attempts to verify it and prints claims.
"""

from __future__ import annotations

import os
import json
import urllib.request
from dotenv import load_dotenv


def compute_supabase_url() -> str:
    url = os.getenv("SUPABASE_URL", "").strip()
    if url:
        return url.rstrip("/")
    ref = os.getenv("SUPABASE_PROJECT_REF", "").strip()
    if not ref:
        raise RuntimeError("Set SUPABASE_URL or SUPABASE_PROJECT_REF in your environment/.env")
    return f"https://{ref}.supabase.co"


def fetch_jwks(supabase_url: str, anon_key: str | None) -> dict:
    jwks_url = f"{supabase_url}/auth/v1/keys"
    req = urllib.request.Request(jwks_url)
    if anon_key:
        req.add_header("apikey", anon_key)
        req.add_header("Authorization", f"Bearer {anon_key}")
    with urllib.request.urlopen(req) as resp:  # nosec - trusted host (Supabase)
        raw = resp.read().decode("utf-8")
        data = json.loads(raw)
        keys = data.get("keys") if isinstance(data, dict) else data
        return {"url": jwks_url, "keys": keys, "raw": data}


def main() -> None:
    load_dotenv()

    supabase_url = compute_supabase_url()
    anon_key = os.getenv("SUPABASE_ANON_KEY")
    print(f"SUPABASE_URL: {supabase_url}")
    print(f"SUPABASE_PROJECT_REF: {os.getenv('SUPABASE_PROJECT_REF', '')}")
    print(f"Anon key present: {'yes' if anon_key else 'no'}")

    # Try JWKS
    try:
        result = fetch_jwks(supabase_url, anon_key)
        num_keys = len(result["keys"]) if isinstance(result.get("keys"), list) else 0
        print(f"JWKS URL: {result['url']}")
        print(f"JWKS fetched OK. keys: {num_keys}")
    except Exception as e:  # pragma: no cover - ad-hoc diagnostics
        print("JWKS fetch FAILED:", repr(e))
        return

    # Optional: verify a provided token
    test_token = os.getenv("SUPABASE_TEST_TOKEN", "").strip()
    if test_token:
        print("SUPABASE_TEST_TOKEN provided — attempting verification…")
        # Reuse project code to verify
        try:
            # Import lazily to avoid local import issues if paths change
            from backend.app.auth_old import verify_supabase_jwt  # type: ignore

            claims = verify_supabase_jwt(test_token)
            safe_claims = {k: claims.get(k) for k in ("sub", "aud", "exp", "email")} | {"all_claims_keys": list(claims.keys())}
            print("Token verified. Claims (subset):", json.dumps(safe_claims, indent=2))
        except Exception as e:  # pragma: no cover - diagnostics
            print("Token verification FAILED:", repr(e))


if __name__ == "__main__":
    main()


