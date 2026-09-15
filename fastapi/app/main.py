"""컨테이너가 죽었다 살아나도 데이터가 남는 FastAPI 예제.

상태를 두는 곳은 두 군데뿐이고, 둘 다 볼륨이다.

  - 구조화된 데이터 → Postgres (named volume: pgdata)
  - 업로드 파일      → UPLOAD_DIR (named volume: uploads)

컨테이너 파일시스템에 쓴 것은 컨테이너를 지우는 순간 사라진다.
그래서 애플리케이션 자체는 아무 상태도 갖지 않는다.
"""

import logging
import os
from contextlib import asynccontextmanager
from datetime import datetime, timezone
from pathlib import Path

from fastapi import Depends, FastAPI, File, HTTPException, UploadFile
from pydantic import BaseModel
from sqlalchemy import DateTime, Integer, String, func, select
from sqlalchemy.orm import Mapped, Session, mapped_column

from .db import Base, engine, get_session, wait_for_db

log = logging.getLogger("uvicorn.error")

UPLOAD_DIR = Path(os.environ.get("UPLOAD_DIR", "/data/uploads"))


class Item(Base):
    __tablename__ = "items"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    name: Mapped[str] = mapped_column(String(200), nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )


class ItemIn(BaseModel):
    name: str


class ItemOut(BaseModel):
    id: int
    name: str
    created_at: datetime


@asynccontextmanager
async def lifespan(app: FastAPI):
    # 기동할 때마다 실행된다. 재시작이 잦으므로 반드시 멱등이어야 한다.
    wait_for_db()
    Base.metadata.create_all(engine)  # 이미 있으면 아무것도 하지 않는다
    UPLOAD_DIR.mkdir(parents=True, exist_ok=True)
    log.info("기동 완료 · 업로드 경로 %s", UPLOAD_DIR)
    yield
    # 종료 시 커넥션 풀을 정리해 DB 쪽에 유령 세션이 남지 않게 한다.
    engine.dispose()
    log.info("종료 처리 완료")


app = FastAPI(title="Persistent FastAPI", lifespan=lifespan)


@app.get("/health")
def health():
    """컨테이너 헬스체크용. DB 까지 확인해야 진짜 '서비스 가능' 상태다."""
    try:
        with engine.connect() as conn:
            conn.exec_driver_sql("SELECT 1")
    except Exception as exc:
        raise HTTPException(status_code=503, detail=f"db unavailable: {exc}") from exc
    return {"status": "ok", "time": datetime.now(timezone.utc)}


@app.post("/items", response_model=ItemOut, status_code=201)
def create_item(payload: ItemIn, session: Session = Depends(get_session)):
    item = Item(name=payload.name)
    session.add(item)
    session.commit()
    session.refresh(item)
    return item


@app.get("/items", response_model=list[ItemOut])
def list_items(session: Session = Depends(get_session)):
    return list(session.scalars(select(Item).order_by(Item.id)))


@app.post("/files", status_code=201)
async def upload(file: UploadFile = File(...)):
    # 파일명은 그대로 믿지 않는다. 경로 구분자가 섞이면 디렉토리를 벗어날 수 있다.
    safe_name = Path(file.filename or "unnamed").name
    if not safe_name or safe_name in {".", ".."}:
        raise HTTPException(status_code=400, detail="invalid filename")

    target = UPLOAD_DIR / safe_name
    target.write_bytes(await file.read())
    return {"saved": safe_name, "bytes": target.stat().st_size}


@app.get("/files")
def list_files():
    if not UPLOAD_DIR.exists():
        return []
    return sorted(p.name for p in UPLOAD_DIR.iterdir() if p.is_file())
