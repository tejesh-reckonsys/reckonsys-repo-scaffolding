# reckonsys-repo-scaffolding

Copier template for Reckonsys FastAPI backend services. Run one command and get a working service with FastAPI, Docker, Ruff, pytest, optional Postgres, and GitHub Actions CI — all wired up.

## Why this template

Starting a new backend service without a template means spending the first day (or two) wiring up the same things every time: project layout, settings management, logging, CORS, Docker, CI, linting config, test fixtures. It works, but it's toil — and it tends to be done slightly differently each time, making it harder to move between services.

This template encodes the decisions we've already made:

**Feature-first layout.** Code is grouped by feature (`app/users/`, `app/billing/`) rather than by type (`routers/`, `models/`). Related code stays together, and adding a new feature means adding one directory — not editing four.

**Production defaults from day one.** `DEBUG=false` disables the API docs, tightens CORS, and switches to JSON logging. This isn't something you add later — it's already there. The production checklist in the generated README makes it explicit.

**Structured logging with request correlation out of the box.** Every log line carries a `request_id` that ties it back to the HTTP request that triggered it. In development you get colored, human-readable output. In production you get JSON that any log aggregator (Loki, CloudWatch, Datadog) can parse. Uvicorn and SQLAlchemy logs flow through the same pipeline automatically.

**OpenTelemetry tracing, zero config required.** OTel is wired up but dormant by default. Set `OTEL_EXPORTER_OTLP_ENDPOINT` to activate traces — no code changes needed. For LLM projects, add `opentelemetry-instrumentation-openai` per project and it plugs straight into the existing provider.

**A real example, not just scaffolding.** The `users/` module is a working feature with schemas, a service layer, a router, and (when Postgres is enabled) a SQLAlchemy model. It demonstrates the exact patterns you should follow for new features — and it comes with tests.

**The model registry is enforced.** A common source of silent Alembic failures is a model that isn't imported at startup, so SQLAlchemy doesn't know about it. `tests/test_model_registry.py` scans for all feature models and fails CI if any are missing from `app/db/models.py`.

**External services via Docker Compose, not mocks.** `make services` starts Postgres, Redis, or anything else you add in the background. `docker-compose.services.yml` is the single place to declare all external dependencies — add a new service once and it's automatically available for both `make dev` and CI. No test-specific mocking of infrastructure.

**`copier update` keeps projects current.** When the template improves, existing services can pull in the changes with `copier update`. Copier shows a diff and lets you resolve conflicts — the same workflow as a library upgrade, not a manual migration.

The template asks five questions. Everything else is decided.

---

## Prerequisites

- [uv](https://docs.astral.sh/uv/) — Python package manager
- [Docker](https://docs.docker.com/get-docker/) — for running services locally and building images
- Copier — install once via `uv tool install copier`

## Quickstart

```bash
uvx copier copy gh:tejesh-reckonsys/reckonsys-repo-scaffolding.git my-new-service
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
| `postgres_port` | `5432` | Host port to expose Postgres on (only asked when `use_postgres=true`) |
| `use_worker` | `false` | Enables arq async worker with Redis |
| `redis_port` | `6379` | Host port to expose Redis on (only asked when `use_worker=true`) |
| `caddy_port` | `80` | Host port to expose Caddy (HTTP) on |
| `bare` | `false` | Skip example modules (users, worker tasks); generate skeleton only |

## What you get

```
my-new-service/
├── app/
│   ├── main.py              # FastAPI app factory
│   ├── core/
│   │   ├── config.py        # Settings via pydantic-settings + .env
│   │   ├── logging.py       # structlog — JSON in prod, colored in dev
│   │   ├── middleware.py    # CORS + request ID
│   │   └── telemetry.py     # OpenTelemetry (noop when endpoint unset)
│   ├── db/                  # SQLAlchemy engine, session dep, model registry
│   └── users/               # Example feature module — copy this pattern
│       ├── router.py
│       ├── service.py
│       ├── models.py
│       └── schemas.py
├── worker/
│   └── main.py              # arq WorkerSettings + example task (use_worker only)
├── tests/
│   ├── conftest.py          # AsyncClient fixture
│   ├── test_health.py
│   └── test_model_registry.py   # Enforces db/models.py completeness (postgres only)
├── docker/
│   ├── Caddyfile            # Caddy reverse proxy (HTTP + gzip)
│   ├── docker-compose.yml   # Full stack: Caddy + app + optional services
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
| `make dev` | Start dev server (starts external services first if enabled) |
| `make test` | Run pytest |
| `make lint` | Ruff check + format check |
| `make format` | Auto-format with Ruff |
| `make build` | Docker build |
| `make up` | Full stack via Docker Compose (Caddy + app + services) |
| `make services` | Start external services only (Postgres etc.) |
| `make down` | Stop Docker Compose stack |
| `make migrate` | `alembic upgrade head` (postgres only) |
| `make migration m="..."` | Generate migration (postgres only) |
| `make worker` | Start arq worker (use_worker only) |

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
