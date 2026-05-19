# reckonsys-repo-scaffolding

Copier template for Reckonsys FastAPI backend services. Run one command and get a working service with FastAPI, Docker, Ruff, pytest, optional Postgres, and GitHub Actions CI — all wired up.

## Prerequisites

- [uv](https://docs.astral.sh/uv/) — Python package manager
- [Docker](https://docs.docker.com/get-docker/) — for running services locally and building images
- Copier — install once via `uv tool install copier`

## Quickstart

```bash
uvx copier copy git+https://github.com/reckonsys/reckonsys-repo-scaffolding.git my-new-service
cd my-new-service
make install
make dev        # app running at http://localhost:8000
```

Open `http://localhost:8000/docs` to explore the API.

## Questions

| Question | Default | Description |
|---|---|---|
| `project_name` | — | Slug used for the package name, Docker image, and DB name |
| `project_description` | `""` | One-line description (used in pyproject.toml and README) |
| `python_version` | `3.12` | Python version for the Docker base image and `requires-python` |
| `use_postgres` | `false` | Enables SQLAlchemy 2.x async, Alembic migrations, and asyncpg |

## What you get

```
my-new-service/
├── app/
│   ├── main.py              # FastAPI app factory
│   ├── core/
│   │   ├── config.py        # Settings via pydantic-settings + .env
│   │   ├── logging.py       # Structured logging (DEBUG-aware)
│   │   └── middleware.py    # CORS setup
│   ├── db/                  # SQLAlchemy engine, session dep, model registry
│   └── users/               # Example feature module — copy this pattern
│       ├── router.py
│       ├── service.py
│       ├── models.py
│       └── schemas.py
├── tests/
│   ├── conftest.py          # AsyncClient fixture
│   ├── test_health.py
│   └── test_model_registry.py   # Enforces db/models.py completeness (postgres only)
├── docker/
│   ├── Caddyfile            # Caddy reverse proxy (HTTP + gzip)
│   ├── docker-compose.yml   # Full stack: Caddy + app + optional Postgres
│   └── docker-compose.services.yml   # External services only (for local dev)
├── Dockerfile               # Multi-stage build
├── Makefile                 # All common tasks
├── .github/workflows/ci.yml # lint + test jobs
└── .pre-commit-config.yaml  # Ruff hooks
```

## Make targets

| Target | Description |
|---|---|
| `make install` | Install dependencies with uv |
| `make dev` | Start dev server (starts Postgres first if enabled) |
| `make test` | Run pytest |
| `make lint` | Ruff check + format check |
| `make format` | Auto-format with Ruff |
| `make build` | Docker build |
| `make up` | Full stack via Docker Compose (Caddy + app + services) |
| `make services` | Start external services only (Postgres etc.) |
| `make down` | Stop Docker Compose stack |
| `make migrate` | `alembic upgrade head` (postgres only) |
| `make migration m="..."` | Generate migration (postgres only) |

## Updating a generated project

```bash
cd my-existing-service
copier update
```

Copier re-renders only the files that changed in the template, prompting you to resolve conflicts.

## Testing the template itself

```bash
make smoke       # generates both variants and runs lint + tests in each
make test-no-pg  # postgres=false variant only
make test-pg     # postgres=true variant only
```
