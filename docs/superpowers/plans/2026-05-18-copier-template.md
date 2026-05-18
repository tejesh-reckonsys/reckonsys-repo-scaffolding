# Copier Template Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a Copier template repo that generates a production-ready FastAPI service — a developer runs `copier copy` and can `make dev` within minutes.

**Architecture:** A flat template under `template/` rendered by `copier.yaml`. All conditional logic (postgres vs no-postgres) is handled via Jinja `{% if use_postgres %}` blocks inside files — no excluded paths, no parallel subtrees. Generated projects are tested by running `copier copy` locally and verifying lint + tests pass in the output directory.

**Tech Stack:** Copier, FastAPI, uv, Ruff, pytest, SQLAlchemy 2.x async, Alembic, asyncpg, Docker, GitHub Actions

---

## File Map

**Template repo root (not generated):**
- `copier.yaml` — questions + rendering config
- `Makefile` — smoke test runner for the template repo itself
- `README.md` — how to use this template
- `CHANGELOG.md` — version history

**Generated files (all under `template/`):**
- `template/.gitignore` — static, no jinja
- `template/README.md.jinja`
- `template/.env.example.jinja`
- `template/.python-version.jinja`
- `template/pyproject.toml.jinja`
- `template/Dockerfile.jinja`
- `template/Makefile.jinja`
- `template/.pre-commit-config.yaml.jinja`
- `template/docker/docker-compose.yml.jinja`
- `template/docker/docker-compose.services.yml.jinja`
- `template/docker/Caddyfile.jinja`
- `template/.github/workflows/ci.yml.jinja`
- `template/scripts/.gitkeep`
- `template/app/__init__.py` — static empty
- `template/app/main.py.jinja`
- `template/app/core/__init__.py` — static empty
- `template/app/core/config.py.jinja`
- `template/app/core/logging.py.jinja`
- `template/app/core/middleware.py.jinja`
- `template/app/db/__init__.py` — static empty
- `template/app/db/base.py.jinja`
- `template/app/db/deps.py.jinja`
- `template/app/db/models.py.jinja`
- `template/app/users/__init__.py` — static empty
- `template/app/users/schemas.py.jinja`
- `template/app/users/service.py.jinja`
- `template/app/users/models.py.jinja`
- `template/app/users/router.py.jinja`
- `template/alembic.ini.jinja`
- `template/alembic/env.py.jinja`
- `template/alembic/script.py.mako` — static (standard Alembic file)
- `template/alembic/versions/.gitkeep`
- `template/tests/__init__.py` — static empty
- `template/tests/conftest.py.jinja`
- `template/tests/test_health.py` — static (no jinja needed)
- `template/tests/test_model_registry.py.jinja`

---

## Task 1: Bootstrap — copier.yaml + repo skeleton

**Files:**
- Create: `copier.yaml`
- Create: `Makefile` (template repo smoke-test runner)
- Create: `README.md`
- Create: `CHANGELOG.md`

- [ ] **Step 1: Install copier**

```bash
uv tool install copier
copier --version
```
Expected: version printed (2.x or newer)

- [ ] **Step 2: Create copier.yaml**

```yaml
_subdirectory: template
_templates_suffix: .jinja

project_name:
    type: str
    help: "Project name (slug, e.g. my-service)"

project_description:
    type: str
    default: ""
    help: "One-line description of the service"

python_version:
    type: str
    default: "3.12"
    help: "Python version (e.g. 3.12, 3.13)"

use_postgres:
    type: bool
    default: false
    help: "Include PostgreSQL, SQLAlchemy async, and Alembic?"
```

- [ ] **Step 3: Create template repo Makefile**

```makefile
.PHONY: smoke test-no-pg test-pg clean

SMOKE_NO_PG := /tmp/smoke-no-pg
SMOKE_PG    := /tmp/smoke-pg

test-no-pg:
	rm -rf $(SMOKE_NO_PG)
	uvx copier copy . $(SMOKE_NO_PG) \
		--data project_name=smoke-test \
		--data "project_description=Smoke test" \
		--data python_version=3.12 \
		--data use_postgres=false \
		--defaults --overwrite
	cd $(SMOKE_NO_PG) && uv sync && uv run ruff check . && uv run pytest -v

test-pg:
	rm -rf $(SMOKE_PG)
	uvx copier copy . $(SMOKE_PG) \
		--data project_name=smoke-test \
		--data "project_description=Smoke test" \
		--data python_version=3.12 \
		--data use_postgres=true \
		--defaults --overwrite
	cd $(SMOKE_PG) && uv sync && uv run ruff check . && uv run pytest -v

smoke: test-no-pg test-pg

clean:
	rm -rf $(SMOKE_NO_PG) $(SMOKE_PG)
```

- [ ] **Step 4: Create README.md**

```markdown
# reckonsys-repo-scaffolding

Copier template for Reckonsys FastAPI backend services.

## Usage

```bash
copier copy git+https://github.com/reckonsys/reckonsys-repo-scaffolding.git my-new-service
cd my-new-service
make install
make dev
```

## Questions

| Question | Default | Description |
|---|---|---|
| `project_name` | — | Slug used for package, Docker image, DB name |
| `project_description` | `""` | One-line description |
| `python_version` | `3.12` | Python version for Docker + pyproject.toml |
| `use_postgres` | `false` | Enable SQLAlchemy async + Alembic + asyncpg |

## Updating a generated project

```bash
cd my-existing-service
copier update
```

## Testing the template

```bash
make smoke       # generates both variants and runs lint + tests
make test-no-pg  # postgres=false variant only
make test-pg     # postgres=true variant only
```
```

- [ ] **Step 5: Create CHANGELOG.md**

```markdown
# Changelog

## v1.0.0 — 2026-05-18

Initial release.

- FastAPI + uvicorn + uv
- Ruff lint + format
- pytest
- Optional PostgreSQL (SQLAlchemy 2.x async + Alembic + asyncpg)
- Docker + Docker Compose
- GitHub Actions CI (lint + test)
- pre-commit hooks
```

- [ ] **Step 6: Create template skeleton directories**

```bash
mkdir -p template/app/core template/app/db template/app/users
mkdir -p template/tests
mkdir -p template/docker
mkdir -p template/.github/workflows
mkdir -p template/scripts
mkdir -p template/alembic/versions
```

- [ ] **Step 7: Verify copier can read the config**

```bash
uvx uvx copier copy . /tmp/check-config --defaults --overwrite --data project_name=check
ls /tmp/check-config
```
Expected: directory created (empty is fine at this stage — no template files yet)

- [ ] **Step 8: Commit**

```bash
git add copier.yaml Makefile README.md CHANGELOG.md template/
git commit -m "feat: add copier.yaml and template skeleton"
```

---

## Task 2: Project config files

**Files:**
- Create: `template/.gitignore`
- Create: `template/.env.example.jinja`
- Create: `template/.python-version.jinja`
- Create: `template/pyproject.toml.jinja`
- Create: `template/README.md.jinja`

- [ ] **Step 1: Create template/.gitignore**

```gitignore
__pycache__/
*.py[cod]
*.egg-info/
.venv/
dist/
.env
.ruff_cache/
.pytest_cache/
.mypy_cache/
```

- [ ] **Step 2: Create template/.env.example.jinja**

```
# App
APP_ENV=development
DEBUG=true
SECRET_KEY=changeme

# Server
HOST=0.0.0.0
PORT=8000
{% if use_postgres %}
# Postgres
DATABASE_URL=postgresql+asyncpg://postgres:postgres@localhost:5432/{{ project_name }}
{% endif %}
```

- [ ] **Step 3: Create template/.python-version.jinja**

```
{{ python_version }}
```

- [ ] **Step 4: Create template/pyproject.toml.jinja**

```toml
[project]
name = "{{ project_name }}"
version = "0.1.0"
description = "{{ project_description }}"
requires-python = ">={{ python_version }}"
dependencies = [
    "fastapi>=0.115.0",
    "uvicorn[standard]>=0.32.0",
    "pydantic-settings>=2.6.0",
    {% if use_postgres %}
    "sqlalchemy[asyncio]>=2.0.0",
    "alembic>=1.14.0",
    "asyncpg>=0.30.0",
    {% endif %}
]

[dependency-groups]
dev = [
    "pytest>=8.3.0",
    "pytest-asyncio>=0.24.0",
    "httpx>=0.28.0",
    "ruff>=0.8.0",
    "pre-commit>=3.8.0",
]

[tool.ruff]
target-version = "py{{ python_version | replace('.', '') }}"
line-length = 88

[tool.ruff.lint]
select = ["E", "F", "I", "UP"]

[tool.pytest.ini_options]
asyncio_mode = "auto"
testpaths = ["tests"]

[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"
```

- [ ] **Step 5: Create template/README.md.jinja**

````markdown
# {{ project_name }}

{{ project_description }}

## Development

```bash
make install    # install dependencies
make dev        # start development server (http://localhost:8000)
make test       # run tests
make lint       # check linting
make format     # auto-format code
```

## Adding a Feature Module

1. Create `app/<feature>/` with `router.py`, `service.py`, `schemas.py`{% if use_postgres %}, `models.py`{% endif %}
2. Register the router in `app/main.py`
{% if use_postgres %}
3. Import the model in `app/db/models.py`
4. Generate and run migration: `make migration m="add <feature>"` then `make migrate`
{% endif %}

## Environment Variables

Copy `.env.example` to `.env` and update values before running.

| Variable | Default | Description |
|---|---|---|
| `APP_ENV` | `development` | Environment name |
| `DEBUG` | `true` | Enables /docs, verbose logging, loose CORS |
| `SECRET_KEY` | `changeme` | **Change in production** |
| `HOST` | `0.0.0.0` | Bind host |
| `PORT` | `8000` | Bind port |
{% if use_postgres %}
| `DATABASE_URL` | `postgresql+asyncpg://...` | Async SQLAlchemy DB URL |
{% endif %}
````

- [ ] **Step 6: Generate and verify**

```bash
rm -rf /tmp/smoke-cfg
uvx copier copy . /tmp/smoke-cfg \
  --data project_name=my-service \
  --data "project_description=Test service" \
  --data python_version=3.12 \
  --data use_postgres=false \
  --defaults --overwrite
cat /tmp/smoke-cfg/pyproject.toml
```
Expected: `name = "my-service"`, no sqlalchemy/asyncpg lines

- [ ] **Step 7: Commit**

```bash
git add template/
git commit -m "feat: add project config templates (pyproject, env, gitignore, readme)"
```

---

## Task 3: FastAPI core — main.py, config, logging, middleware

**Files:**
- Create: `template/app/__init__.py`
- Create: `template/app/core/__init__.py`
- Create: `template/app/main.py.jinja`
- Create: `template/app/core/config.py.jinja`
- Create: `template/app/core/logging.py.jinja`
- Create: `template/app/core/middleware.py.jinja`

- [ ] **Step 1: Create static __init__.py files**

Create `template/app/__init__.py` and `template/app/core/__init__.py` as empty files.

```bash
touch template/app/__init__.py template/app/core/__init__.py
```

- [ ] **Step 2: Create template/app/core/config.py.jinja**

```python
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    APP_ENV: str = "development"
    DEBUG: bool = True
    SECRET_KEY: str = "changeme"
    HOST: str = "0.0.0.0"
    PORT: int = 8000
    {% if use_postgres %}
    DATABASE_URL: str = "postgresql+asyncpg://postgres:postgres@localhost:5432/{{ project_name }}"
    {% endif %}


settings = Settings()
```

- [ ] **Step 3: Create template/app/core/logging.py.jinja**

```python
import logging
import sys

from app.core.config import settings


def setup_logging() -> None:
    level = logging.DEBUG if settings.DEBUG else logging.INFO
    fmt = (
        "%(levelname)s %(name)s %(message)s"
        if settings.DEBUG
        else "%(asctime)s %(levelname)s %(name)s %(message)s"
    )
    logging.basicConfig(stream=sys.stdout, level=level, format=fmt)
```

- [ ] **Step 4: Create template/app/core/middleware.py.jinja**

```python
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.core.config import settings


def setup_middleware(app: FastAPI) -> None:
    origins = ["*"] if settings.DEBUG else []
    app.add_middleware(
        CORSMiddleware,
        allow_origins=origins,
        allow_credentials=not settings.DEBUG,
        allow_methods=["*"],
        allow_headers=["*"],
    )
```

- [ ] **Step 5: Create template/app/main.py.jinja**

```python
from contextlib import asynccontextmanager
from typing import AsyncGenerator

from fastapi import FastAPI

from app.core.config import settings
from app.core.logging import setup_logging
from app.core.middleware import setup_middleware
from app.users.router import router as users_router
{% if use_postgres %}
import app.db.models  # noqa: F401
{% endif %}


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncGenerator[None, None]:
    setup_logging()
    yield


app = FastAPI(
    title="{{ project_name }}",
    description="{{ project_description }}",
    lifespan=lifespan,
    docs_url="/docs" if settings.DEBUG else None,
    redoc_url="/redoc" if settings.DEBUG else None,
    openapi_url="/openapi.json" if settings.DEBUG else None,
)

setup_middleware(app)
app.include_router(users_router, prefix="/users", tags=["users"])


@app.get("/health")
async def health() -> dict[str, str]:
    return {"status": "ok"}
```

- [ ] **Step 6: Write the health test first (TDD)**

Create `template/tests/__init__.py` (empty) and `template/tests/test_health.py`:

```python
import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_health(client: AsyncClient) -> None:
    response = await client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "ok"}
```

- [ ] **Step 7: Create template/tests/conftest.py.jinja**

```python
import pytest
from httpx import ASGITransport, AsyncClient

from app.main import app


@pytest.fixture
async def client() -> AsyncClient:
    async with AsyncClient(
        transport=ASGITransport(app=app), base_url="http://test"
    ) as c:
        yield c
```

- [ ] **Step 8: Generate and run the health test**

```bash
rm -rf /tmp/smoke-core
uvx copier copy . /tmp/smoke-core \
  --data project_name=smoke-test \
  --data "project_description=Smoke test" \
  --data python_version=3.12 \
  --data use_postgres=false \
  --defaults --overwrite
cd /tmp/smoke-core
cp .env.example .env
uv sync
uv run pytest tests/test_health.py -v
```
Expected: `PASSED tests/test_health.py::test_health`

- [ ] **Step 9: Commit**

```bash
git add template/
git commit -m "feat: add FastAPI core (main, config, logging, middleware) + health test"
```

---

## Task 4: DB layer — base, deps, models registry

**Files:**
- Create: `template/app/db/__init__.py`
- Create: `template/app/db/base.py.jinja`
- Create: `template/app/db/deps.py.jinja`
- Create: `template/app/db/models.py.jinja`

- [ ] **Step 1: Create template/app/db/__init__.py**

```bash
touch template/app/db/__init__.py
```

- [ ] **Step 2: Create template/app/db/base.py.jinja**

```python
{% if use_postgres %}
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine
from sqlalchemy.orm import DeclarativeBase

from app.core.config import settings

engine = create_async_engine(settings.DATABASE_URL, echo=settings.DEBUG)
AsyncSessionLocal = async_sessionmaker(engine, expire_on_commit=False)


class Base(DeclarativeBase):
    pass
{% endif %}
```

- [ ] **Step 3: Create template/app/db/deps.py.jinja**

```python
{% if use_postgres %}
from collections.abc import AsyncGenerator

from sqlalchemy.ext.asyncio import AsyncSession

from app.db.base import AsyncSessionLocal


async def get_db() -> AsyncGenerator[AsyncSession, None]:
    async with AsyncSessionLocal() as session:
        yield session
{% endif %}
```

- [ ] **Step 4: Create template/app/db/models.py.jinja**

```python
{% if use_postgres %}
# Import all feature models here so SQLAlchemy's metadata is fully populated.
# Both alembic/env.py and app startup depend on this file.
# tests/test_model_registry.py enforces every app/*/models.py is listed here.
from app.users.models import User  # noqa: F401
{% endif %}
```

- [ ] **Step 5: Verify generated db/ renders correctly for both variants**

```bash
# no-postgres variant: db files should exist but be empty
rm -rf /tmp/smoke-db-no
uvx copier copy . /tmp/smoke-db-no \
  --data project_name=smoke-test \
  --data "project_description=Smoke test" \
  --data python_version=3.12 \
  --data use_postgres=false \
  --defaults --overwrite
cat /tmp/smoke-db-no/app/db/base.py
```
Expected: empty file

```bash
# postgres variant: db files should have full content
rm -rf /tmp/smoke-db-pg
uvx copier copy . /tmp/smoke-db-pg \
  --data project_name=smoke-test \
  --data "project_description=Smoke test" \
  --data python_version=3.12 \
  --data use_postgres=true \
  --defaults --overwrite
cat /tmp/smoke-db-pg/app/db/base.py
```
Expected: `create_async_engine`, `AsyncSessionLocal`, `Base` present

- [ ] **Step 6: Commit**

```bash
git add template/app/db/
git commit -m "feat: add db layer (base, deps, models registry)"
```

---

## Task 5: Users feature module

**Files:**
- Create: `template/app/users/__init__.py`
- Create: `template/app/users/schemas.py.jinja`
- Create: `template/app/users/models.py.jinja`
- Create: `template/app/users/service.py.jinja`
- Create: `template/app/users/router.py.jinja`

- [ ] **Step 1: Create template/app/users/__init__.py**

```bash
touch template/app/users/__init__.py
```

- [ ] **Step 2: Create template/app/users/schemas.py.jinja**

```python
from pydantic import BaseModel


class UserBase(BaseModel):
    name: str
    email: str


class UserCreate(UserBase):
    pass


class UserRead(UserBase):
    id: int

    model_config = {"from_attributes": True}
```

- [ ] **Step 3: Create template/app/users/models.py.jinja**

```python
{% if use_postgres %}
from sqlalchemy import String
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base


class User(Base):
    __tablename__ = "users"

    id: Mapped[int] = mapped_column(primary_key=True)
    name: Mapped[str] = mapped_column(String(255))
    email: Mapped[str] = mapped_column(String(255), unique=True)
{% endif %}
```

- [ ] **Step 4: Create template/app/users/service.py.jinja**

```python
{% if use_postgres %}
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.users.models import User
from app.users.schemas import UserCreate, UserRead


async def get_users(db: AsyncSession) -> list[UserRead]:
    result = await db.execute(select(User))
    return [UserRead.model_validate(u) for u in result.scalars().all()]


async def create_user(db: AsyncSession, data: UserCreate) -> UserRead:
    user = User(name=data.name, email=data.email)
    db.add(user)
    await db.commit()
    await db.refresh(user)
    return UserRead.model_validate(user)
{% else %}
from app.users.schemas import UserRead


def get_users() -> list[UserRead]:
    return []
{% endif %}
```

- [ ] **Step 5: Create template/app/users/router.py.jinja**

```python
from fastapi import APIRouter
{% if use_postgres %}
from fastapi import Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.deps import get_db
from app.users import service
from app.users.schemas import UserCreate, UserRead

router = APIRouter()


@router.get("/", response_model=list[UserRead])
async def list_users(db: AsyncSession = Depends(get_db)) -> list[UserRead]:
    return await service.get_users(db)


@router.post("/", response_model=UserRead, status_code=201)
async def create_user(
    data: UserCreate, db: AsyncSession = Depends(get_db)
) -> UserRead:
    return await service.create_user(db, data)
{% else %}
from app.users import service
from app.users.schemas import UserRead

router = APIRouter()


@router.get("/", response_model=list[UserRead])
def list_users() -> list[UserRead]:
    return service.get_users()
{% endif %}
```

- [ ] **Step 6: Generate and run full test suite (no-postgres)**

```bash
rm -rf /tmp/smoke-users
uvx copier copy . /tmp/smoke-users \
  --data project_name=smoke-test \
  --data "project_description=Smoke test" \
  --data python_version=3.12 \
  --data use_postgres=false \
  --defaults --overwrite
cd /tmp/smoke-users
cp .env.example .env
uv sync
uv run ruff check .
uv run pytest -v
```
Expected: all tests PASS, ruff exits 0

- [ ] **Step 7: Commit**

```bash
git add template/app/users/
git commit -m "feat: add users example feature module (router, service, models, schemas)"
```

---

## Task 6: Model registry fitness test

**Files:**
- Create: `template/tests/test_model_registry.py.jinja`

- [ ] **Step 1: Create template/tests/test_model_registry.py.jinja**

```python
{% if use_postgres %}
import ast
from pathlib import Path


def _get_feature_model_files() -> list[Path]:
    app_dir = Path(__file__).parent.parent / "app"
    return [
        p
        for p in app_dir.glob("*/models.py")
        if p.parent.name not in ("db", "core") and p.read_text().strip()
    ]


def _get_registered_modules() -> set[str]:
    registry = Path(__file__).parent.parent / "app" / "db" / "models.py"
    tree = ast.parse(registry.read_text())
    modules = set()
    for node in ast.walk(tree):
        if isinstance(node, ast.ImportFrom) and node.module:
            modules.add(node.module)
    return modules


def test_all_feature_models_registered_in_db_models() -> None:
    model_files = _get_feature_model_files()
    registered = _get_registered_modules()

    missing = []
    for model_file in model_files:
        parts = model_file.parts
        app_idx = next(i for i, p in enumerate(parts) if p == "app")
        module = ".".join(parts[app_idx:]).removesuffix(".py")
        if module not in registered:
            missing.append(module)

    assert not missing, (
        f"These model modules are not imported in app/db/models.py: {missing}\n"
        "Add them to app/db/models.py to register them with SQLAlchemy metadata."
    )
{% endif %}
```

- [ ] **Step 2: Generate postgres variant and run the registry test**

```bash
rm -rf /tmp/smoke-registry
uvx copier copy . /tmp/smoke-registry \
  --data project_name=smoke-test \
  --data "project_description=Smoke test" \
  --data python_version=3.12 \
  --data use_postgres=true \
  --defaults --overwrite
cd /tmp/smoke-registry
cp .env.example .env
uv sync
uv run pytest tests/test_model_registry.py -v
```
Expected: `PASSED tests/test_model_registry.py::test_all_feature_models_registered_in_db_models`

- [ ] **Step 3: Verify the test catches a missing registration**

```bash
# Temporarily remove the users import from models.py
cd /tmp/smoke-registry
echo "" > app/db/models.py
uv run pytest tests/test_model_registry.py -v
```
Expected: FAILED with message containing `app.users.models`

Restore the file:
```bash
echo "from app.users.models import User  # noqa: F401" > app/db/models.py
```

- [ ] **Step 4: Commit**

```bash
git add template/tests/test_model_registry.py.jinja
git commit -m "feat: add model registry fitness test"
```

---

## Task 7: Alembic setup

**Files:**
- Create: `template/alembic.ini.jinja`
- Create: `template/alembic/env.py.jinja`
- Create: `template/alembic/script.py.mako`
- Create: `template/alembic/versions/.gitkeep`

- [ ] **Step 1: Create template/alembic.ini.jinja**

```ini
{% if use_postgres %}
[alembic]
script_location = alembic
prepend_sys_path = .
sqlalchemy.url =

[loggers]
keys = root,sqlalchemy,alembic

[handlers]
keys = console

[formatters]
keys = generic

[logger_root]
level = WARN
handlers = console
qualname =

[logger_sqlalchemy]
level = WARN
handlers =
qualname = sqlalchemy.engine

[logger_alembic]
level = INFO
handlers =
qualname = alembic

[handler_console]
class = StreamHandler
args = (sys.stderr,)
level = NOTSET
formatter = generic

[formatter_generic]
format = %(levelname)-5.5s [%(name)s] %(message)s
datefmt = %H:%M:%S
{% endif %}
```

- [ ] **Step 2: Create template/alembic/env.py.jinja**

```python
{% if use_postgres %}
import asyncio
from logging.config import fileConfig

from alembic import context
from sqlalchemy import pool
from sqlalchemy.ext.asyncio import async_engine_from_config

from app.core.config import settings
import app.db.models  # noqa: F401
from app.db.base import Base

config = context.config
config.set_main_option("sqlalchemy.url", settings.DATABASE_URL)

if config.config_file_name is not None:
    fileConfig(config.config_file_name)

target_metadata = Base.metadata


def run_migrations_offline() -> None:
    url = config.get_main_option("sqlalchemy.url")
    context.configure(url=url, target_metadata=target_metadata, literal_binds=True)
    with context.begin_transaction():
        context.run_migrations()


def do_run_migrations(connection) -> None:
    context.configure(connection=connection, target_metadata=target_metadata)
    with context.begin_transaction():
        context.run_migrations()


async def run_async_migrations() -> None:
    connectable = async_engine_from_config(
        config.get_section(config.config_ini_section, {}),
        prefix="sqlalchemy.",
        poolclass=pool.NullPool,
    )
    async with connectable.connect() as connection:
        await connection.run_sync(do_run_migrations)
    await connectable.dispose()


def run_migrations_online() -> None:
    asyncio.run(run_async_migrations())


if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()
{% endif %}
```

- [ ] **Step 3: Create template/alembic/script.py.mako**

```mako
"""${message}

Revision ID: ${up_revision}
Revises: ${down_revision | comma,n}
Create Date: ${create_date}

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
${imports if imports else ""}

revision: str = ${repr(up_revision)}
down_revision: Union[str, None] = ${repr(down_revision)}
branch_labels: Union[str, Sequence[str], None] = ${repr(branch_labels)}
depends_on: Union[str, Sequence[str], None] = ${repr(depends_on)}


def upgrade() -> None:
    ${upgrades if upgrades else "pass"}


def downgrade() -> None:
    ${downgrades if downgrades else "pass"}
```

- [ ] **Step 4: Create template/alembic/versions/.gitkeep**

```bash
touch template/alembic/versions/.gitkeep
```

- [ ] **Step 5: Verify alembic renders correctly for postgres variant**

```bash
rm -rf /tmp/smoke-alembic
uvx copier copy . /tmp/smoke-alembic \
  --data project_name=smoke-test \
  --data "project_description=Smoke test" \
  --data python_version=3.12 \
  --data use_postgres=true \
  --defaults --overwrite
cat /tmp/smoke-alembic/alembic.ini
```
Expected: `[alembic]` section present, `script_location = alembic`

```bash
cat /tmp/smoke-alembic/alembic/env.py
```
Expected: `from app.db.base import Base` present

- [ ] **Step 6: Verify alembic is absent for no-postgres variant**

```bash
rm -rf /tmp/smoke-no-alembic
uvx copier copy . /tmp/smoke-no-alembic \
  --data project_name=smoke-test \
  --data "project_description=Smoke test" \
  --data python_version=3.12 \
  --data use_postgres=false \
  --defaults --overwrite
cat /tmp/smoke-no-alembic/alembic.ini
```
Expected: empty file

- [ ] **Step 7: Commit**

```bash
git add template/alembic.ini.jinja template/alembic/
git commit -m "feat: add alembic setup (conditional on use_postgres)"
```

---

## Task 8: Docker

**Files:**
- Create: `template/Dockerfile.jinja`
- Create: `template/docker/docker-compose.yml.jinja`
- Create: `template/docker/docker-compose.services.yml.jinja`

- [ ] **Step 1: Create template/Dockerfile.jinja**

```dockerfile
FROM python:{{ python_version }}-slim AS base

WORKDIR /app
RUN pip install uv

FROM base AS builder

COPY pyproject.toml .
RUN uv sync --no-dev --frozen

FROM base AS runtime

COPY --from=builder /app/.venv /app/.venv
ENV PATH="/app/.venv/bin:$PATH"

COPY app/ app/
COPY scripts/ scripts/

EXPOSE 8000

CMD ["sh", "-c", "uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-8000}"]
```

- [ ] **Step 2: Create template/docker/Caddyfile.jinja**

```
:80 {
    encode gzip
    reverse_proxy app:8000
}
```

- [ ] **Step 3: Create template/docker/docker-compose.yml.jinja**

```yaml
services:
  caddy:
    image: caddy:2-alpine
    ports:
      - "80:80"
    volumes:
      - ./Caddyfile:/etc/caddy/Caddyfile:ro
    depends_on:
      - app

  app:
    build:
      context: ..
      dockerfile: Dockerfile
    env_file: ../.env
    expose:
      - "8000"
    {% if use_postgres %}
    depends_on:
      db:
        condition: service_healthy

  db:
    image: postgres:16
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: {{ project_name }}
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 5s
      timeout: 5s
      retries: 5

volumes:
  postgres_data:
    {% endif %}
```

- [ ] **Step 5: Create template/docker/docker-compose.services.yml.jinja**

```yaml
{% if use_postgres %}
services:
  db:
    image: postgres:16
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: {{ project_name }}
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 5s
      timeout: 5s
      retries: 5

volumes:
  postgres_data:
{% endif %}
```

- [ ] **Step 6: Verify Docker files render**

```bash
rm -rf /tmp/smoke-docker
uvx copier copy . /tmp/smoke-docker \
  --data project_name=smoke-test \
  --data "project_description=Smoke test" \
  --data python_version=3.12 \
  --data use_postgres=true \
  --defaults --overwrite
cat /tmp/smoke-docker/Dockerfile
cat /tmp/smoke-docker/docker/docker-compose.yml
cat /tmp/smoke-docker/docker/docker-compose.services.yml
```
Expected: `caddy:2-alpine` in docker-compose.yml, `postgres:16` in services file, `COPY scripts/` in Dockerfile

- [ ] **Step 7: Commit**

```bash
git add template/Dockerfile.jinja template/docker/
git commit -m "feat: add Dockerfile, Caddy, and Docker Compose templates"
```

---

## Task 9: Makefile

**Files:**
- Create: `template/Makefile.jinja`

- [ ] **Step 1: Create template/Makefile.jinja**

```makefile
{% if use_postgres %}
.PHONY: install dev test lint format build up services down migrate migration shell
{% else %}
.PHONY: install dev test lint format build up services down shell
{% endif %}

install:
	uv sync

{% if use_postgres %}
dev: services
{% else %}
dev:
{% endif %}
	uv run uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload

test:
	uv run pytest

lint:
	uv run ruff check .
	uv run ruff format --check .

format:
	uv run ruff format .

build:
	docker build -t {{ project_name }} .

up:
	docker compose -f docker/docker-compose.yml up

services:
	docker compose -f docker/docker-compose.services.yml up -d

down:
	docker compose -f docker/docker-compose.yml down

{% if use_postgres %}
migrate:
	uv run alembic upgrade head

migration:
	uv run alembic revision --autogenerate -m "$(m)"

{% endif %}
shell:
	uv run python -c "import app; print('Shell ready')"
```

- [ ] **Step 2: Verify Makefile renders for both variants**

```bash
rm -rf /tmp/smoke-make-no
uvx copier copy . /tmp/smoke-make-no \
  --data project_name=smoke-test \
  --data "project_description=Smoke test" \
  --data python_version=3.12 \
  --data use_postgres=false \
  --defaults --overwrite
grep migrate /tmp/smoke-make-no/Makefile
```
Expected: no `migrate` or `migration` targets

```bash
rm -rf /tmp/smoke-make-pg
uvx copier copy . /tmp/smoke-make-pg \
  --data project_name=smoke-test \
  --data "project_description=Smoke test" \
  --data python_version=3.12 \
  --data use_postgres=true \
  --defaults --overwrite
grep migrate /tmp/smoke-make-pg/Makefile
```
Expected: `migrate:` and `migration:` targets present

- [ ] **Step 3: Commit**

```bash
git add template/Makefile.jinja
git commit -m "feat: add Makefile template"
```

---

## Task 10: GitHub Actions CI

**Files:**
- Create: `template/.github/workflows/ci.yml.jinja`

- [ ] **Step 1: Create template/.github/workflows/ci.yml.jinja**

```yaml
name: CI

on:
  push:
  pull_request:

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: astral-sh/setup-uv@v4
        with:
          python-version: "{{ python_version }}"
      - run: uv sync
      - run: uv run ruff check .
      - run: uv run ruff format --check .

  test:
    runs-on: ubuntu-latest
    {% if use_postgres %}
    services:
      postgres:
        image: postgres:16
        env:
          POSTGRES_USER: postgres
          POSTGRES_PASSWORD: postgres
          POSTGRES_DB: {{ project_name }}
        ports:
          - 5432:5432
        options: >-
          --health-cmd pg_isready
          --health-interval 5s
          --health-timeout 5s
          --health-retries 5
    {% endif %}
    steps:
      - uses: actions/checkout@v4
      - uses: astral-sh/setup-uv@v4
        with:
          python-version: "{{ python_version }}"
      - run: uv sync
      {% if use_postgres %}
      - name: Run migrations
        run: uv run alembic upgrade head
        env:
          DATABASE_URL: postgresql+asyncpg://postgres:postgres@localhost:5432/{{ project_name }}
      {% endif %}
      - name: Run tests
        run: uv run pytest
        {% if use_postgres %}
        env:
          DATABASE_URL: postgresql+asyncpg://postgres:postgres@localhost:5432/{{ project_name }}
        {% endif %}
```

- [ ] **Step 2: Verify CI renders for both variants**

```bash
rm -rf /tmp/smoke-ci
uvx copier copy . /tmp/smoke-ci \
  --data project_name=smoke-test \
  --data "project_description=Smoke test" \
  --data python_version=3.12 \
  --data use_postgres=false \
  --defaults --overwrite
cat /tmp/smoke-ci/.github/workflows/ci.yml
```
Expected: no `postgres:` service block, no `alembic` step

- [ ] **Step 3: Commit**

```bash
git add template/.github/
git commit -m "feat: add GitHub Actions CI workflow"
```

---

## Task 11: Pre-commit config

**Files:**
- Create: `template/.pre-commit-config.yaml.jinja`

- [ ] **Step 1: Create template/.pre-commit-config.yaml.jinja**

```yaml
repos:
  - repo: https://github.com/astral-sh/ruff-pre-commit
    rev: v0.8.0
    hooks:
      - id: ruff
        args: [--fix]
      - id: ruff-format
```

- [ ] **Step 2: Verify it generates**

```bash
rm -rf /tmp/smoke-precommit
uvx copier copy . /tmp/smoke-precommit \
  --data project_name=smoke-test \
  --data "project_description=Smoke test" \
  --data python_version=3.12 \
  --data use_postgres=false \
  --defaults --overwrite
cat /tmp/smoke-precommit/.pre-commit-config.yaml
```
Expected: `ruff-pre-commit` hook present

- [ ] **Step 3: Create scripts/.gitkeep**

```bash
touch template/scripts/.gitkeep
```

- [ ] **Step 4: Commit**

```bash
git add template/.pre-commit-config.yaml.jinja template/scripts/.gitkeep
git commit -m "feat: add pre-commit config and scripts dir"
```

---

## Task 12: End-to-end smoke test

**Goal:** Generate both variants, verify lint passes, tests pass, and the app starts.

- [ ] **Step 1: Run full no-postgres smoke test**

```bash
make test-no-pg
```
Expected: `uv run ruff check .` exits 0, all pytest tests PASS

- [ ] **Step 2: Run full postgres smoke test (requires local Postgres or skip DB tests)**

```bash
make test-pg
```
Expected: `uv run ruff check .` exits 0, `test_model_registry` and `test_health` PASS

If no local Postgres: skip DB-touching tests and confirm the registry test passes:
```bash
cd /tmp/smoke-pg
uv run pytest tests/test_model_registry.py tests/test_health.py -v
```

- [ ] **Step 3: Verify app starts for no-postgres variant**

```bash
cd /tmp/smoke-no-pg
cp .env.example .env
uv run uvicorn app.main:app --port 8001 &
sleep 2
curl -s http://localhost:8001/health
kill %1
```
Expected: `{"status":"ok"}`

- [ ] **Step 4: Verify /docs is disabled when DEBUG=false**

```bash
cd /tmp/smoke-no-pg
DEBUG=false uv run uvicorn app.main:app --port 8002 &
sleep 2
curl -s -o /dev/null -w "%{http_code}" http://localhost:8002/docs
kill %1
```
Expected: `404`

- [ ] **Step 5: Tag v1.0.0**

```bash
git tag v1.0.0
```

- [ ] **Step 6: Final commit if any fixes were needed**

```bash
git add -A
git commit -m "fix: smoke test corrections" || echo "nothing to commit"
```
