# TeamCORE

TeamCORE is a workforce operations platform for travel agencies—supporting employees, independent contractors, contractor organizations, and related relationships in one unified system. Product goals, domains, and terminology are documented in **[`docs/product/overview.md`](docs/product/overview.md)**. Structural planning uses **[`docs/product/domain-map.md`](docs/product/domain-map.md)** and the **[open decisions register](docs/product/open-decisions.md)** (OD-001–OD-012).

This repository hosts the TeamCORE web application built with **Ruby on Rails**.

## Stack

| Area | Choice |
| --- | --- |
| Framework | Rails **8.1** |
| Ruby | **3.4.9** (see [`.ruby-version`](.ruby-version)) |
| Database | **MariaDB** 11.x (MySQL-compatible; `mysql2` adapter) |
| Background jobs | **Sidekiq** with **Redis** |
| Frontend | **Importmap**, **Hotwire** (Turbo + Stimulus), **Tailwind CSS** via `tailwindcss-rails` |
| Caching / Action Cable defaults | **Solid Cache** / **Solid Cable** (database-backed); jobs use Redis, not Solid Queue |

## Prerequisites

The recommended path is **Docker Desktop** (or another engine with Compose v2) so MariaDB, Redis, and Ruby line up regardless of host OS or CPU architecture.

Optional: Install Ruby **3.4.9** and client libraries locally if you prefer running Rails on the host while still using Compose for MariaDB and Redis only.

## Local development with Docker

From the repo root:

```bash
docker compose build
docker compose run --rm web bin/rails db:prepare   # creates dev + test DBs and runs migrations (idempotent)
docker compose up
```

`db:prepare` touches both **development** and **test** databases. Compose seeds MariaDB with [`db/docker/mariadb/zzz-teamcore.sql`](db/docker/mariadb/zzz-teamcore.sql) so user `app` can use `app_development` and `app_test`. That script runs **only when the `mariadb_data` volume is first created**. If you created the volume **before** this file existed, fix it once:

```bash
docker compose exec mariadb mariadb -uroot -proot -e "CREATE DATABASE IF NOT EXISTS app_test; GRANT ALL PRIVILEGES ON app_test.* TO 'app'@'%'; FLUSH PRIVILEGES;"
```

(Or recreate the volume: `docker compose down -v` — **this deletes local DB data**.)

- **Web app**: [http://localhost:3000](http://localhost:3000)  
- **MariaDB**: `localhost:3306` (credentials match [`docker-compose.yml`](docker-compose.yml): user `app` / password `app`, DB `app_development`)  
- **Redis**: `localhost:6379`  

Compose runs three app-related processes:

- **`web`** — Rails + Puma  
- **`worker`** — `bundle exec sidekiq` (uses `REDIS_URL` pointing at the `redis` service)  

Development uses the **`:sidekiq`** Active Job adapter when `REDIS_URL` is set (as in Compose); without Redis locally, `:async` is used instead.

Stop the stack with `Ctrl+C`, or `docker compose down`. Use `docker compose down -v` if you want to drop the persisted MariaDB volume.

### AMD64 parity on Apple Silicon

To mirror typical Linux AMD64 CI runners (runs under emulation and is slower):

```bash
DOCKER_DEFAULT_PLATFORM=linux/amd64 docker compose build
DOCKER_DEFAULT_PLATFORM=linux/amd64 docker compose up
```

### Container images

[`Dockerfile`](Dockerfile) defines two build targets:

- **`development`** — full dev image used by Compose (Bookworm-based, bind-mount friendly).  
- **Default final stage** — production-oriented image (Ruby slim, jemalloc, Thruster) for deployment tooling such as Kamal.

## Running the test suite

**Inside Compose** (uses the same MariaDB/Redis services defined in Compose):

```bash
docker compose run --rm \
  -e RAILS_ENV=test \
  -e DB_HOST=mariadb \
  -e DB_USERNAME=app \
  -e DB_PASSWORD=app \
  -e TEST_DB_DATABASE=app_test \
  -e REDIS_URL=redis://redis:6379/0 \
  web bin/rails db:test:prepare test
```

**On the host** (with MariaDB and Redis reachable locally), align env vars with `config/database.yml` (`DB_*`, optional `DATABASE_URL`). In **test**, Active Job uses the **`:test`** adapter, so Redis is optional for plain unit tests.

## Linting & security CI checks

Rails ships binstubs aligned with `.github/workflows/ci.yml`:

```bash
bin/rubocop
bin/brakeman --no-pager
bin/bundler-audit
bin/importmap audit
```

Or run the orchestrated checklist:

```bash
bin/ci
```

## Production notes

- Set **`REDIS_URL`** wherever Sidekiq runs; Active Job uses **`:sidekiq`** in production.  
- Configure primary (and Solid Cache/Cable) databases per `config/database.yml`; use credentials or secret managers for passwords, not the repo.

## Contributing

Pull requests trigger **`.github/workflows/ci.yml`**: Ruby security scans, RuboCop, tests against **MariaDB** and **Redis**, and **`docker build`** for both Dockerfile targets on `ubuntu-latest`.
