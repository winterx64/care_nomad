# CARE – Nomad Local Development Setup

This document explains how to run the **CARE backend API** locally using **HashiCorp Nomad (dev mode)** with **Docker Compose** for infrastructure services.

This setup mirrors a real production-style workflow while keeping local development simple and reproducible.

## Architecture Overview

| Component          | Tool           | Responsibility        |
| ------------------ | -------------- | --------------------- |
| API (Django)       | Nomad          | Application runtime   |
| Database           | Docker Compose | PostgreSQL            |
| Cache              | Docker Compose | Redis                 |
| Object Storage     | Docker Compose | MinIO                 |
| Build              | Docker         | Image build           |
| DX / Orchestration | Makefile       | One-command workflows |

**Important principle**

> Docker Compose runs *infra only*.
> Nomad runs the *application only*.

## Prerequisites

Make sure the following are installed:

* [Docker (with Compose v2)](https://docs.docker.com/engine/install/)
* [Nomad](https://developer.hashicorp.com/nomad/install)
* Make

Verify:

```bash
docker --version
nomad version
make --version
```

## Local Development (Docker Compose – full stack)

This is the **default dev mode** used by most contributors.

```bash
make up
```

This starts:

* PostgreSQL
* Redis
* MinIO
* Django backend
* Celery worker

Access:

* API → [http://localhost:9000](http://localhost:9000)
* MinIO → [http://localhost:9001](http://localhost:9001)

Stop everything:

```bash
make down
```

## Nomad-based Development (API via Nomad)

This mode runs:

* **Database + Redis** → Docker Compose
* **Django API** → Nomad

This simulates production orchestration locally.

### One-command Nomad deployment

```bash
make nomad-deploy
```

What this does:

1. Starts Nomad in dev mode (if not already running)
2. Builds `care-backend:nomad` Docker image
3. Starts PostgreSQL & Redis via Docker Compose
4. Waits for infra readiness
5. Deploys the API using `care-api.nomad`

### Check status

```bash
make nomad-status
```

### View logs

```bash
make nomad-logs
```

### Stop Nomad + cleanup

```bash
make nomad-stop
```

This:

* Stops the Nomad job
* Stops the Nomad agent
* Shuts down Docker Compose services
* Cleans local artifacts

## Nomad Job Spec (care-api.nomad)

Key points:

* Runs Django using `scripts/start-dev.sh`
* Uses `host.docker.internal` to reach Docker Compose services
* Avoids hardcoded bridge IPs
* Uses explicit Postgres + Redis environment variables

### Exposed port

* API → `http://localhost:9000`

## Environment Variables (Nomad)

PostgreSQL:

```txt
POSTGRES_HOST=host.docker.internal
POSTGRES_PORT=5433
POSTGRES_DB=care
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres
```

Redis:

```txt
REDIS_HOST=host.docker.internal
REDIS_PORT=6380
REDIS_URL=redis://host.docker.internal:6380
```

Django:

```txt
DJANGO_SETTINGS_MODULE=config.settings.local
DEBUG=true
```

## Why `host.docker.internal`?

Nomad runs Docker containers **outside** the Docker Compose network.

Using:

```txt
extra_hosts = ["host.docker.internal:host-gateway"]
```

allows Nomad containers to reliably reach:

* PostgreSQL
* Redis

This works consistently across:

* Linux
* macOS
* CI environments

## Common Issues & Fixes

### Port already allocated (9000)

Cause:

* Docker Compose backend already running

Fix:

```bash
make down
```

or stop only backend/celery containers.

### PostgreSQL auth failure

Cause:

* Wrong credentials

Fix:
Check:

```bash
docker inspect care-db-1 | grep POSTGRES_
```

Update Nomad env vars accordingly.

### Redis URL error

Cause:

* Missing scheme (`redis://`)

Fix:
Ensure:

```txt
REDIS_URL=redis://host.docker.internal:6380
```

## Recommended Workflow

* **Daily dev** → `make up`
* **Nomad testing** → `make nomad-deploy`
* **Debug orchestration** → Nomad UI (`http://localhost:4646`)
* **Cleanup** → `make nomad-stop`

## Summary

This setup provides:

* Production-like orchestration
* Fast local iteration
* Clean separation of infra and app
* One-command developer experience
