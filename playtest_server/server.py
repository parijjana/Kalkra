import os
import sqlite3
import json
from datetime import datetime
from typing import List, Dict, Any
from fastapi import FastAPI, Request, HTTPException
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse
from pydantic import BaseModel

app = FastAPI(title="Kalkra Playtest Server")

# Database initialization
DB_PATH = "results.db"

def init_db():
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS results (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            player_name TEXT,
            mode TEXT,
            difficulty TEXT,
            score INTEGER,
            total_rounds INTEGER,
            timestamp TEXT,
            metadata TEXT
        )
    ''')
    conn.commit()
    conn.close()

init_db()

class MatchResult(BaseModel):
    player_name: str
    mode: str
    difficulty: str
    score: int
    total_rounds: int
    timestamp: str
    metadata: Dict[str, Any]

@app.post("/api/results")
async def record_result(result: MatchResult):
    try:
        conn = sqlite3.connect(DB_PATH)
        cursor = conn.cursor()
        cursor.execute('''
            INSERT INTO results (player_name, mode, difficulty, score, total_rounds, timestamp, metadata)
            VALUES (?, ?, ?, ?, ?, ?, ?)
        ''', (
            result.player_name,
            result.mode,
            result.difficulty,
            result.score,
            result.total_rounds,
            result.timestamp,
            json.dumps(result.metadata)
        ))
        conn.commit()
        conn.close()
        return {"status": "success", "message": "Result recorded"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/stats")
async def get_stats():
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    cursor = conn.cursor()
    cursor.execute('SELECT * FROM results ORDER BY id DESC LIMIT 100')
    rows = cursor.fetchall()
    conn.close()
    return [dict(row) for row in rows]

# Static file serving
WEB_BUILD_DIR = os.path.join(os.path.dirname(__file__), "web")

if os.path.exists(WEB_BUILD_DIR):
    app.mount("/", StaticFiles(directory=WEB_BUILD_DIR, html=True), name="static")

@app.get("/{full_path:path}")
async def serve_frontend(full_path: str):
    # Fallback to index.html for SPA routing if needed
    index_path = os.path.join(WEB_BUILD_DIR, "index.html")
    if os.path.exists(index_path):
        return FileResponse(index_path)
    return {"error": "Frontend build not found. Run 'flutter build web -t lib/playtest_main.dart' and copy to 'web/' folder."}

if __name__ == "__main__":
    import uvicorn
    # Start on all interfaces for WiFi access
    uvicorn.run(app, host="0.0.0.0", port=8000)
