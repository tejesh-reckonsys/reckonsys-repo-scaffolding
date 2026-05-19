# Changelog

## v1.1.7 — 2026-05-19

- **Fix**: Postgres volume mount updated to `/var/lib/postgresql` (from `/var/lib/postgresql/data`) — required by `postgres:18` which manages its own subdirectory structure

## v1.1.6 — 2026-05-19

- **Fix**: `env_file` in `docker-compose.yml` corrected to `../.env` (was resolving to `docker/.env` relative to compose file location)
- **Fix**: `db` and `redis` port mappings in `docker-compose.yml` now use env vars (`${POSTGRES_PORT}`, `${REDIS_PORT}`) consistent with the services file

## v1.1.5 — 2026-05-19

- **Fix**: Add `name: {project_name}` to both Docker Compose files so volumes are named `{project_name}_postgres_data` instead of `docker_postgres_data`
- **Fix**: Generated README dev setup renders correctly for all four postgres/worker combinations — `make services` and `make migrate` always appear in the right order before `make dev`

## v1.1.4 — 2026-05-19

- **Fix**: Bump Postgres image to `postgres:18`
- **Fix**: Add `container_name: {project_name}-{service}` to all Docker Compose services to prevent conflicts when running multiple projects locally

## v1.1.3 — 2026-05-19

- **Fix**: Bump `ruff>=0.9.0` and pre-commit hook rev to `v0.9.0` — adds `py314` target-version support
- **Fix**: Generated README now includes `uv run pre-commit install` in setup steps

## v1.1.2 — 2026-05-19

- **Feat**: `bare` option — skips example modules (users, worker tasks), generates skeleton only
- **Feat**: Configurable ports via copier questions (`postgres_port`, `redis_port`, `caddy_port`) with env-var override at runtime
- **Feat**: arq worker example shows context pattern and enqueue-from-FastAPI hint; arq pool wired into FastAPI lifespan (`app.state.arq`)
- **Fix**: Generated README now shows `make services` and `make migrate` steps before `make dev`

## v1.1.1 — 2026-05-19

- **Fix**: Add `.copier-answers.yml` template file so `copier update` works on generated projects
- **Fix**: Docker Compose app build context set to `..` (project root); Caddyfile volume path corrected
- **Fix**: `dispatch()` uses `RequestResponseEndpoint` type instead of `object`
- **Fix**: `conftest.py` client fixture return type is `AsyncGenerator[AsyncClient, None]` to suppress IDE warnings
- **Fix**: Bump `pydantic-settings>=2.10.0` and OTel packages for Python 3.14 compatibility
- **Fix**: Add `[tool.uv] exclude-newer = "7 days"` for reproducible dependency resolution
- **Feat**: Add McCabe complexity lint rule (`C90`, `max-complexity = 10`)
- **Feat**: Non-postgres `get_users()` returns seed data instead of empty list

## v1.1.0 — 2026-05-19

- **structlog**: Replaces `logging.basicConfig` — JSON in production, colored console in dev, stdlib bridge routes uvicorn/SQLAlchemy logs through the same pipeline
- **Request ID**: `RequestIDMiddleware` generates a UUID per request, binds it to structlog context (all log lines in a request carry `request_id`), echoes it as `X-Request-ID` response header
- **OpenTelemetry**: Always-on dependency, noop when `OTEL_EXPORTER_OTLP_ENDPOINT` is unset — set the endpoint to activate OTLP traces with FastAPI auto-instrumentation. For LLM projects, add `opentelemetry-instrumentation-openai` and call `OpenAIInstrumentor().instrument()` in `telemetry.py`
- **arq worker** (`use_worker=true`): Redis-backed async task queue, `worker/main.py` with `WorkerSettings` and an example task, Redis added to docker-compose services and CI, `make worker` target, `make dev` starts Redis automatically

## v1.0.0 — 2026-05-18

Initial release.

- FastAPI + uvicorn + uv
- Ruff lint + format
- pytest
- Optional PostgreSQL (SQLAlchemy 2.x async + Alembic + asyncpg)
- Docker + Docker Compose + Caddy
- GitHub Actions CI (lint + test)
- pre-commit hooks
