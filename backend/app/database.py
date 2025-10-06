import os
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from langgraph.checkpoint.postgres import PostgresSaver
from psycopg_pool import ConnectionPool

raw_url = os.getenv("DATABASE_URL")

# SQLAlchemy engine URL (ensure psycopg dialect)
if raw_url and raw_url.startswith("postgresql://") and "+psycopg" not in raw_url:
    alchemy_url = raw_url.replace("postgresql://", "postgresql+psycopg://", 1)
else:
    alchemy_url = raw_url

engine = create_engine(alchemy_url)
Session = sessionmaker(bind=engine)

def get_db():
    db = Session()
    try:
        yield db
    finally:
        db.close()

# Shared LangGraph Postgres checkpointer singleton (psycopg v3 pool)
pg_conninfo = raw_url.replace("postgresql+psycopg://", "postgresql://") if raw_url else raw_url
pool = ConnectionPool(conninfo=pg_conninfo)
checkpointer = PostgresSaver(pool)