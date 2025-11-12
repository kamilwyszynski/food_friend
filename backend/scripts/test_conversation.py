import os
import json
import time
from urllib import request, error


API_BASE_URL = os.getenv("API_BASE_URL", "http://localhost:8000/api/v1")
TOKEN = "eyJhbGciOiJIUzI1NiIsImtpZCI6IjVzRGJLdFphaG9FNlJWSlYiLCJ0eXAiOiJKV1QifQ.eyJpc3MiOiJodHRwczovL2xwdmx4bGNwemh2bnF6dWx1dWdkLnN1cGFiYXNlLmNvL2F1dGgvdjEiLCJzdWIiOiIzNWExZmJmMC04ZjRjLTRmMDctODZmMy0wYzBhNDFhODhmOGEiLCJhdWQiOiJhdXRoZW50aWNhdGVkIiwiZXhwIjoxNzYwOTU0OTgyLCJpYXQiOjE3NjA5NTEzODIsImVtYWlsIjoia2FtaWx3eXN6eW5za2kwQGdtYWlsLmNvbSIsInBob25lIjoiIiwiYXBwX21ldGFkYXRhIjp7InByb3ZpZGVyIjoiZW1haWwiLCJwcm92aWRlcnMiOlsiZW1haWwiXX0sInVzZXJfbWV0YWRhdGEiOnsiZW1haWwiOiJrYW1pbHd5c3p5bnNraTBAZ21haWwuY29tIiwiZW1haWxfdmVyaWZpZWQiOnRydWUsInBob25lX3ZlcmlmaWVkIjpmYWxzZSwic3ViIjoiMzVhMWZiZjAtOGY0Yy00ZjA3LTg2ZjMtMGMwYTQxYTg4ZjhhIn0sInJvbGUiOiJhdXRoZW50aWNhdGVkIiwiYWFsIjoiYWFsMSIsImFtciI6W3sibWV0aG9kIjoicGFzc3dvcmQiLCJ0aW1lc3RhbXAiOjE3NjA5NTEzODJ9XSwic2Vzc2lvbl9pZCI6ImUxZDZkZTNhLWJkNDMtNDY5Yi04NmE1LTA3NmNjZDJkMmZiOSIsImlzX2Fub255bW91cyI6ZmFsc2V9.Vxgp9RN_4fWyxqzRMO7aGX56J-HrzMCTUbhYKaLnyxM"


def post_chat(message: str, session_id: str | None) -> dict:
    endpoints = ["chat", "chat/"]
    payload = {"message": message, "session_id": session_id}
    data = json.dumps(payload).encode("utf-8")
    headers = {"Content-Type": "application/json"}
    if TOKEN:
        headers["Authorization"] = f"Bearer {TOKEN}"

    last_err = None
    for ep in endpoints:
        url = f"{API_BASE_URL}/{ep}"
        print(f"POST {url} (token_len={len(TOKEN)})")
        req = request.Request(url, data=data, headers=headers, method="POST")
        try:
            with request.urlopen(req, timeout=60) as resp:
                body = resp.read().decode("utf-8")
                return json.loads(body)
        except error.HTTPError as e:
            body = e.read().decode("utf-8", errors="ignore")
            last_err = RuntimeError(f"HTTP {e.code} at {url}: {body}")
        except error.URLError as e:
            last_err = RuntimeError(f"Request failed at {url}: {e}")
    assert last_err is not None
    raise last_err


def _extract_tools(response_text: str) -> list[str]:
    """Heuristically extract tool names from agent trace text."""
    import re
    names = set()
    for m in re.finditer(r"name\s*[:=]\s*['\"]([A-Za-z0-9_]+)['\"]", response_text):
        candidate = m.group(1)
        if candidate not in {"SystemMessage", "HumanMessage", "AIMessage", "ToolMessage"}:
            names.add(candidate)
    # Also catch 'tool_calls': [{'function': {'name': '...'}}]
    for m in re.finditer(r"tool_calls.*?name['\"]\s*[:=]\s*['\"]([A-Za-z0-9_]+)['\"]", response_text, re.DOTALL):
        names.add(m.group(1))
    return sorted(names)


def _shorten(text: str, max_chars: int = 600) -> str:
    if len(text) <= max_chars:
        return text
    return text[: max_chars - 3] + "..."


def _pretty(text: str, width: int = 100) -> str:
    """Pretty-format plaintext/markdown-like content.

    - Wrap normal paragraphs to the given width
    - Preserve blank lines
    - Wrap bullet lines ("- ..." or "* ...") with hanging indent
    - Wrap numbered lists with hanging indent (e.g., "1) ...", "1. ...")
    """
    import textwrap

    def is_bullet(s: str) -> bool:
        s2 = s.lstrip()
        return s2.startswith("- ") or s2.startswith("* ")

    def is_numbered(s: str) -> bool:
        s2 = s.lstrip()
        if len(s2) < 3:
            return False
        # match patterns like "1. ", "2) "
        return (s2[0].isdigit() and s2[1] in ".)" and (len(s2) == 2 or s2[2] == " "))

    lines = text.splitlines()
    out: list[str] = []
    for line in lines:
        if not line.strip():
            out.append("")
            continue
        s = line.rstrip()
        if is_bullet(s):
            content = s.lstrip()[2:]
            wrapped = textwrap.fill(
                content,
                width=width,
                initial_indent="- ",
                subsequent_indent="  ",
                replace_whitespace=False,
            )
            out.append(wrapped)
        elif is_numbered(s):
            s2 = s.lstrip()
            num_token = s2[:2]  # e.g., "1.", "2)"
            rest = s2[3:] if len(s2) > 2 else ""
            wrapped = textwrap.fill(
                rest.strip(),
                width=width,
                initial_indent=f"{num_token} ",
                subsequent_indent="   ",
                replace_whitespace=False,
            )
            out.append(wrapped)
        else:
            out.append(
                textwrap.fill(
                    s.strip(),
                    width=width,
                    replace_whitespace=False,
                )
            )
    return "\n".join(out)


def _find_recipe_ids(text: str) -> list[int]:
    """Extract recipe ids from fenced blocks like:
    ```recipe
    { "id": 123 }
    ```
    Returns a list of ints (may be empty)."""
    import re
    ids: list[int] = []
    for m in re.finditer(r"```recipe\s+({[\s\S]*?})\s*```", text):
        block = m.group(1)
        try:
            data = json.loads(block)
            rid = data.get("id")
            if isinstance(rid, int):
                ids.append(rid)
            elif isinstance(rid, str):
                v = int(rid)
                ids.append(v)
        except Exception:
            continue
    return ids


def _get_recipe_by_id(recipe_id: int) -> dict:
    """Fetch a recipe JSON from the backend (requires auth)."""
    url = f"{API_BASE_URL}/recipe/{recipe_id}"
    headers = {}
    if TOKEN:
        headers["Authorization"] = f"Bearer {TOKEN}"
    req = request.Request(url, headers=headers, method="GET")
    with request.urlopen(req, timeout=30) as resp:
        body = resp.read().decode("utf-8")
        return json.loads(body)


def _format_recipe_card(r: dict, width: int = 100) -> str:
    """Return a readable single-string card for a recipe dict."""
    import textwrap
    name = r.get("name", "Recipe")
    cook = r.get("cook_time", 0)
    ings = r.get("ingredients", [])
    lines = []
    lines.append(f"{name} — {cook} min")
    if isinstance(ings, list) and ings:
        lines.append("Ingredients:")
        max_show = 6
        for i, ing in enumerate(ings[:max_show], start=1):
            iname = ing.get("name", "")
            qty = ing.get("quantity", "")
            unit = ing.get("unit", "")
            bullet = f"- {iname}" if not qty else f"- {qty} {unit} {iname}".strip()
            lines.append(bullet)
        if len(ings) > max_show:
            lines.append(f"… (+{len(ings) - max_show} more)")
    return _pretty("\n".join(lines), width=width)


def run_conversation():
    if not TOKEN:
        print("Warning: No SUPABASE_BEARER_TOKEN/SUPABASE_TOKEN set; request will likely be unauthorized.")

    print(f"API_BASE_URL = {API_BASE_URL}")
    print("Type '/exit' to quit. Press Enter on empty line to quit as well.\n")

    session_id = None
    turn = 1
    while True:
        try:
            user_msg = input("You: ").strip()
        except EOFError:
            break
        if user_msg == "" or user_msg.lower() == "/exit":
            break

        print(f"\nSending (turn {turn})...")
        resp = post_chat(user_msg, session_id)
        session_id = resp.get("session_id", session_id)
        assistant_raw = resp.get("response", "<no response>")

        def _extract_assistant_text(val) -> str:
            # Case 1: already dict with messages
            if isinstance(val, dict) and "messages" in val:
                msgs = val.get("messages") or []
                for m in reversed(msgs):
                    role = m.get("role") if isinstance(m, dict) else None
                    if role == "assistant":
                        content = m.get("content")
                        if isinstance(content, str):
                            return content
                return str(val)
            # Case 2: JSON string we can parse
            if isinstance(val, str):
                try:
                    j = json.loads(val)
                    if isinstance(j, dict) and "messages" in j:
                        msgs = j.get("messages") or []
                        for m in reversed(msgs):
                            if isinstance(m, dict) and m.get("role") == "assistant":
                                c = m.get("content")
                                if isinstance(c, str):
                                    return c
                except Exception:
                    pass
                # Case 3: Python repr from LangGraph; regex to find AIMessage(content='...') or role/content pairs
                import re
                m = re.findall(r"AIMessage\(content='([\s\S]*?)'", val)
                if m:
                    return m[-1]
                m2 = re.findall(r"role['\"]\s*[:=]\s*['\"]assistant['\"].*?content['\"]\s*[:=]\s*['\"]([\s\S]*?)['\"]", val)
                if m2:
                    return m2[-1]
                return val
            # Fallback
            return str(val)

        assistant_text = _extract_assistant_text(assistant_raw)
        tools = _extract_tools(assistant_raw if isinstance(assistant_raw, str) else json.dumps(assistant_raw))
        assistant_short = assistant_text

        print("Assistant:\n" + _pretty(assistant_short))
        # Inline recipe tags → fetch and render cards
        tag_ids = _find_recipe_ids(assistant_text)
        for rid in tag_ids:
            try:
                rjson = _get_recipe_by_id(rid)
                card = _format_recipe_card(rjson)
                print(f"\n[Recipe #{rid}]\n{card}")
            except Exception as e:
                print(f"\n[Recipe #{rid}] failed to load: {e}")
        print(f"Tools: {', '.join(tools) if tools else '-'}")
        print(f"Session: {session_id}\n")
        time.sleep(0.1)
        turn += 1

    print("Bye.")


if __name__ == "__main__":
    run_conversation()


