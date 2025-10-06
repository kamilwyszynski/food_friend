import os
from dotenv import load_dotenv

load_dotenv()

# This script should be run once to create the LangGraph checkpoint tables
from app.database import pool
from langgraph.checkpoint.postgres import PostgresSaver

if __name__ == "__main__":
    # Using psycopg_pool-based checkpointer; acquire a connection to setup
    with pool.connection() as conn:
        # CREATE INDEX CONCURRENTLY requires autocommit
        conn.autocommit = True
        saver = PostgresSaver(conn)
        saver.setup()
    print("LangGraph checkpoint tables created (if not present)")


