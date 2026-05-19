# Changelog

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
