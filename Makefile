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
