# FastAPI · 컨테이너가 죽어도 데이터가 남는 구성

컨테이너는 일회용품으로 다루고, 남아야 하는 것은 전부 named volume 에 둔다.

| 무엇 | 어디에 | 볼륨 |
|---|---|---|
| 구조화된 데이터 | Postgres | `pgdata` |
| 업로드 파일 | `/data/uploads` | `uploads` |
| 애플리케이션 상태 | 없음 | — |

컨테이너 파일시스템에 쓴 것은 컨테이너와 함께 사라진다. 그래서 앱 자체는 아무 상태도 갖지 않는다.

## 실행

```bash
cp .env.example .env     # POSTGRES_PASSWORD 를 바꿀 것
docker compose up -d --build
```

- API: http://localhost:8000
- 문서: http://localhost:8000/docs

## 데이터를 지키는 네 가지 장치

**1. named volume** — `docker compose down` 으로 컨테이너를 지워도 볼륨은 남는다.

**2. `pool_pre_ping=True`** ([app/db.py](app/db.py)) — DB 컨테이너가 재시작하면 커넥션 풀에 남아있던 연결은 이미 끊어져 있다. 그걸 모르고 쓰면 첫 요청이 `server closed the connection unexpectedly` 로 실패한다. pre_ping 이 빌려주기 직전에 확인하고 조용히 다시 맺는다.

**3. 헬스체크 + `depends_on: service_healthy`** — `depends_on` 만으로는 DB 컨테이너가 떴는지만 알 뿐, 접속을 받을 준비가 됐는지는 모른다. `pg_isready` 헬스체크를 걸어야 API 가 진짜 준비된 뒤에 뜬다.

**4. 멱등한 기동 로직** — 재시작이 잦으므로 기동 코드는 몇 번 실행돼도 같은 결과여야 한다. `create_all` 은 이미 있는 테이블을 건드리지 않고, 업로드 디렉토리는 `exist_ok=True` 로 만든다.

## 주의

```bash
docker compose down      # 컨테이너만 삭제. 데이터 남음
docker compose down -v   # 볼륨까지 삭제. 데이터 사라짐  ← -v 조심
```

## 검증 결과

실제로 죽여보고 확인한 내용이다.

| 테스트 | 결과 |
|---|---|
| `docker compose kill` 후 재기동 | 데이터 3건 + 파일 1개 그대로 |
| `docker compose down` 으로 컨테이너 완전 삭제 후 재생성 | 그대로 (생성 시각까지 최초 값 유지) |
| API 는 살려둔 채 DB 만 재시작 | API 재시작 없이 조회·생성 모두 정상 |

세 번째가 `pool_pre_ping` 이 없으면 깨지는 지점이다. API 컨테이너 기동 시각이 DB 보다 앞서는 것으로 API 가 재시작되지 않았음을 확인했다.

## 운영으로 넘어갈 때

- `POSTGRES_PASSWORD` 를 Secrets Manager 같은 곳으로 옮긴다. `.env` 는 `.gitignore` 에 있다.
- 볼륨은 그 호스트에만 있다. 인스턴스가 교체되는 ASG 환경이라면 DB 는 RDS 로, 업로드 파일은 S3 로 빼야 한다.
- 스키마 변경은 `create_all` 대신 Alembic 같은 마이그레이션 도구로 관리한다.
