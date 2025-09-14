import os
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

engine = create_engine(os.getenv("DATABASE_URL"))
Session = sessionmaker(bind=engine)

def get_db():
    db = Session()
    try:
        yield db
    finally:
        db.close()