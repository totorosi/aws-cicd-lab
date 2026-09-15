"""DB 연결.

컨테이너가 죽었다 살아나는 상황에서 중요한 두 가지를 여기서 처리한다.

1. pool_pre_ping
   DB 컨테이너가 재시작하면 커넥션 풀에 남아있던 연결은 이미 끊어진 상태다.
   그걸 모르고 쓰면 첫 요청이 "server closed the connection unexpectedly" 로 실패한다.
   pre_ping 은 빌려주기 직전에 연결을 확인하고, 죽었으면 조용히 새로 맺는다.

2. 기동 시 재시도
   compose 의 depends_on 이 DB 가 준비될 때까지 기다려주지만,
   DB 만 단독 재시작하는 경우엔 API 가 먼저 떠 있을 수 있다.
   그래서 기동 시점에도 몇 번 재시도한다.
"""

import logging
import os
import time

from sqlalchemy import create_engine, text
from sqlalchemy.exc import OperationalError
from sqlalchemy.orm import DeclarativeBase, sessionmaker

log = logging.getLogger("uvicorn.error")

DATABASE_URL = os.environ.get(
    "DATABASE_URL",
    "postgresql+psycopg://app:app@db:5432/app",
)

engine = create_engine(
    DATABASE_URL,
    pool_pre_ping=True,
    pool_recycle=300,
    future=True,
)

SessionLocal = sessionmaker(bind=engine, autoflush=False, expire_on_commit=False)


class Base(DeclarativeBase):
    pass


def wait_for_db(attempts: int = 30, delay: float = 2.0) -> None:
    """DB 가 응답할 때까지 기다린다. 끝내 실패하면 예외를 그대로 올린다."""
    last: Exception | None = None
    for i in range(1, attempts + 1):
        try:
            with engine.connect() as conn:
                conn.execute(text("SELECT 1"))
            log.info("DB 연결 확인 (%d번째 시도)", i)
            return
        except OperationalError as exc:
            last = exc
            log.warning("DB 대기 중 (%d/%d)", i, attempts)
            time.sleep(delay)
    raise RuntimeError(f"DB 에 연결하지 못했습니다: {last}")


def get_session():
    session = SessionLocal()
    try:
        yield session
    finally:
        session.close()
