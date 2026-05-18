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
