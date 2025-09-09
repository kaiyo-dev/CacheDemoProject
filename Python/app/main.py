from fastapi import FastAPI, Depends
from fastapi.responses import ORJSONResponse
from pydantic import BaseModel
from loguru import logger
import os
import aiosqlite
import redis.asyncio as redis

app = FastAPI(title="Cache Demo API", default_response_class=ORJSONResponse)

REDIS_URL = os.getenv("REDIS_URL", "redis://localhost:6379/0")
DB_PATH = os.getenv("DB_PATH", ":memory:")

class Item(BaseModel):
    id: int
    name: str

async def get_db():
    async with aiosqlite.connect(DB_PATH) as db:
        await db.execute("CREATE TABLE IF NOT EXISTS items (id INTEGER PRIMARY KEY, name TEXT)")
        await db.commit()
        yield db

async def get_cache():
    client = redis.from_url(REDIS_URL, encoding="utf-8", decode_responses=True)
    try:
        yield client
    finally:
        await client.close()

@app.on_event("startup")
async def startup_event():
    logger.info("Application starting up")

@app.get("/health")
async def health():
    return {"status": "ok"}

@app.post("/items", response_model=Item)
async def create_item(item: Item, db=Depends(get_db), cache=Depends(get_cache)):
    await db.execute("INSERT OR REPLACE INTO items (id, name) VALUES (?, ?)", (item.id, item.name))
    await db.commit()
    await cache.set(f"item:{item.id}", item.name)
    logger.info(f"Item stored with id={item.id}")
    return item

@app.get("/items/{item_id}", response_model=Item)
async def read_item(item_id: int, db=Depends(get_db), cache=Depends(get_cache)):
    cached = await cache.get(f"item:{item_id}")
    if cached is not None:
        return Item(id=item_id, name=cached)
    async with db.execute("SELECT id, name FROM items WHERE id = ?", (item_id,)) as cursor:
        row = await cursor.fetchone()
    if row:
        await cache.set(f"item:{item_id}", row[1])
        return Item(id=row[0], name=row[1])
    return Item(id=item_id, name="")
