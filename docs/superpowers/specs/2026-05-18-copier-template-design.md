# Copier Template Design — reckonsys-repo-scaffolding

**Date:** 2026-05-18
**Status:** Approved

---

## Goal

A Copier template that generates a production-ready FastAPI backend service. A developer runs `copier copy` and can `make dev` within minutes — FastAPI running, Docker working, optional Postgres running, migrations working, linting configured, tests runnable, CI passing.

---

## Template Repo Structure

```
reckonsys-repo-scaffolding/
├── copier.yaml
├── README.md
├── CHANGELOG.md
└── template/
    ├── app/
    │   ├── main.py.jinja
    │   ├── core/
    │   │   ├── config.py.jinja
    │   │   ├── logging.py.jinja
    │   │   └── middleware.py.jinja
    │   ├── db/
    │   │   ├── base.py.jinja
    │   │   ├── deps.py.jinja
    │   │   └── models.py.jinja
    │   └── users/
    │       ├── router.py.jinja
    │       ├── service.py.jinja
    │       ├── models.py.jinja
    │       └── schemas.py.jinja
    ├── tests/
    │   ├── conftest.py.jinja
    │   └── test_model_registry.py.jinja
    ├── scripts/
    ├── docker/
    │   ├── docker-compose.yml.jinja
    │   └── docker-compose.services.yml.jinja
    ├── .github/
    │   └── workflows/
    │       └── ci.yml.jinja
    ├── Makefile.jinja
    ├── Dockerfile.jinja
    ├── pyproject.toml.jinja
    ├── .python-version.jinja
    ├── .pre-commit-config.yaml.jinja
    ├── .env.example.jinja
    ├── .gitignore
    └── README.md.jinja
```

---

## Copier Questions

Defined in `copier.yaml`:

| Question | Type | Default | Purpose |
|---|---|---|---|
| `project_name` | str | — | Slug for folder, package, Docker image names |
| `project_description` | str | — | Used in pyproject.toml and README |
| `python_version` | str | `3.12` | Base Docker image and `requires-python` |
| `use_postgres` | bool | `false` | Enables SQLAlchemy, Alembic, asyncpg, DB compose service |

`copier.yaml` sets `templates_suffix: .jinja` and `_subdirectory: template`.

---

## Conditional Behaviour

Uses **Option A — single tree with Jinja conditionals**. No files are excluded; DB-related content is wrapped in `{% if use_postgres %}` blocks.

`use_postgres=true` enables:
- `asyncpg`, `sqlalchemy`, `alembic` deps in `pyproject.toml`
- Postgres service in `docker/docker-compose.services.yml` and `docker/docker-compose.yml`
- Populated `db/base.py`, `db/deps.py`, `db/models.py`
- Alembic config and migrations
- `make migrate` and `make migration` targets
- Postgres service container in GitHub Actions `test` job

`use_postgres=false` produces a clean API-only service with empty stubs in `db/`.

---

## Generated App Structure

```
app/
├── main.py              # FastAPI app factory, mounts routers
├── core/
│   ├── config.py        # pydantic-settings, reads from .env
│   ├── logging.py       # structured logging setup
│   └── middleware.py    # CORS, request ID
├── db/
│   ├── base.py          # SQLAlchemy async engine + session factory
│   ├── deps.py          # get_db() FastAPI dependency
│   └── models.py        # central model registry — all feature models imported here
└── users/               # working example feature module
    ├── router.py
    ├── service.py
    ├── models.py
    └── schemas.py
```

`users/` is a minimal but real implementation demonstrating the feature-first pattern. Developers copy it to scaffold new features. `users/models.py` renders a SQLAlchemy model only when `use_postgres=true`; otherwise it is an empty stub.

---

## Model Registry Convention

`db/models.py` is the single point where all SQLAlchemy models are imported. It is used by:
- `db/base.py` — ensures all models are loaded at app startup
- `alembic/env.py` — ensures Alembic can see all tables for migration generation

`tests/test_model_registry.py` enforces this:
1. Scans `app/*/models.py` to discover all feature model files
2. Checks each is imported in `db/models.py`
3. Fails with a clear message if any are missing

This test runs in CI, catching registration omissions before they reach production.

---

## Environment Variables

`.env.example` ships with:

```bash
# App
APP_ENV=development        # development | production
DEBUG=true
SECRET_KEY=changeme

# Server
HOST=0.0.0.0
PORT=8000

# Postgres (when use_postgres=true)
DATABASE_URL=postgresql+asyncpg://postgres:postgres@localhost:5432/{{ project_name }}
```

`DEBUG=false` enforces production guards in `app/main.py`:
- `/docs`, `/redoc`, `/openapi.json` disabled
- Stricter CORS (no wildcard)
- Structured JSON logging

---

## Docker Layout

```
Dockerfile                          # multi-stage, at repo root
docker/
├── docker-compose.yml              # full stack: app + external services
└── docker-compose.services.yml    # external services only (postgres etc.)
```

`docker-compose.services.yml` is the target for `make services` — lets developers run dependencies locally without running the app inside Docker.

---

## Makefile Targets

| Target | Description |
|---|---|
| `make install` | `uv sync` |
| `make dev` | Runs `make services` first (if postgres), then uvicorn with `--reload` |
| `make test` | `pytest` |
| `make lint` | `ruff check` + `ruff format --check` |
| `make format` | `ruff format` (auto-fix) |
| `make build` | Docker build |
| `make up` | `docker compose up` (full stack) |
| `make services` | `docker-compose.services.yml up -d` |
| `make down` | `docker compose down` |
| `make migrate` | `alembic upgrade head` (postgres only) |
| `make migration` | `alembic revision --autogenerate` (postgres only) |
| `make shell` | Python shell with app context |

---

## GitHub Actions CI

File: `.github/workflows/ci.yml`
Triggers: push, pull_request

Two parallel jobs:

**`lint`**
- `ruff check .`
- `ruff format --check .`

**`test`**
- `pytest`
- When `use_postgres=true`: includes `postgres:16` service container with health check

---

## Runtime Stack

- FastAPI
- uvicorn
- Python 3.12+ (configurable)
- uv (package management)
- Ruff (lint + format)
- pytest
- pre-commit
- SQLAlchemy 2.x async + asyncpg + Alembic (when postgres enabled)

---

## Out of Scope (v1)

- Kubernetes / Helm
- Redis, Celery, event buses
- Auth frameworks
- mypy
- Internal SDKs
- Multi-DB support
- GitLab CI
