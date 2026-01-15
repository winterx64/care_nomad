# CARE – Nomad Local Development Setup

This document explains how to run the **CARE backend API** locally using **HashiCorp Nomad (dev mode)** with **Docker containers managed by Nomad**.

This setup mirrors **production-style orchestration** while remaining **fully local, reproducible, and CI-friendly**.

---

## Architecture Overview

| Component     | Tool            | Responsibility         |
| ------------- | --------------- | ---------------------- |
| API (Django)  | Nomad           | Application runtime    |
| Database      | Nomad           | PostgreSQL container   |
| Cache         | Nomad           | Redis container        |
| Build         | Docker          | Image build & runtime  |
| Orchestration | Nomad           | Scheduling & lifecycle |
| DX            | Makefile + Bash | One-command workflows  |

**Core principle**

> Nomad orchestrates **everything**.
> Docker Compose is **not used** in this workflow.

---

## Prerequisites

Ensure the following are installed:

* Docker (Desktop or Engine)
* Nomad
* Make

Verify:

```bash
docker --version
nomad version
make --version
```

---

## Local Development (Nomad – full stack)

This is the **primary development mode**.

All services are managed by Nomad:

* PostgreSQL
* Redis
* Django API

### One-command startup

```bash
make nomad-up
```

What this does:

1. Starts Nomad in dev mode (if not already running)
2. Deploys PostgreSQL via `postgres.nomad`
3. Deploys Redis via `redis.nomad`
4. Deploys Django API via `care-backend.nomad`

---

## Accessing the API

The API is exposed on:

```
http://127.0.0.1:9000
```

If you see an HTTPS redirect, ensure:

* Django is running with **development settings**
* You are not using cached browser redirects

---

## Django Settings (Important)

When running under Nomad **locally**, the API uses:

```txt
DJANGO_SETTINGS_MODULE=config.settings.development
```

**Why?**

* Production settings **force HTTPS by design**
* Nomad dev has **no TLS termination**
* Development settings correctly allow HTTP

> Production settings are reserved for real deployments behind a reverse proxy.

---

## Nomad Job Specs

Located in:

```
nomad/
├── care-backend.nomad
├── postgres.nomad
└── redis.nomad
```

### care-backend.nomad (API)

Key points:

* Runs Gunicorn directly (PID 1)
* Explicit port binding (`9000`)
* Uses development Django settings
* Connects to Postgres & Redis via localhost-mapped ports
* No Consul dependency

### Exposed port

* API → `http://127.0.0.1:9000`

---

## Environment Variables (Nomad)

### Django

```txt
DJANGO_SETTINGS_MODULE=config.settings.development
DEBUG=false
ALLOWED_HOSTS=*
```

### PostgreSQL

```txt
DATABASE_URL=postgresql://postgres:postgres@127.0.0.1:<allocated-port>/care
```

### Redis

```txt
REDIS_URL=redis://127.0.0.1:<allocated-port>/0
```

(Ports are assigned by Nomad unless explicitly pinned.)

---

## Useful Commands

### Check job status

```bash
make status
```

### View Nomad UI

```
http://127.0.0.1:4646
```

### Stop everything

```bash
make nomad-down
```

This:

* Stops all Nomad jobs
* Stops the Nomad dev agent
* Cleans up local artifacts

---

## Common Issues & Fixes

### API running but browser redirects to HTTPS

**Cause**

* Django production settings

**Fix**

* Ensure `DJANGO_SETTINGS_MODULE=config.settings.development`
* Clear browser cache or use curl

---

### Port 9000 already in use

**Cause**

* Another service bound to 9000

**Fix**

```bash
make nomad-down
```

Or free the port manually.

---

### No logs from API

**Cause**

* No traffic yet

**Fix**

```bash
curl http://127.0.0.1:9000
nomad alloc logs <alloc-id>
```

---

## Recommended Workflow

* **Daily development** → `make nomad-up`
* **Inspect orchestration** → Nomad UI
* **Debug infra** → `nomad job status`
* **Cleanup** → `make nomad-down`

---

## Summary

This setup provides:

* Production-style orchestration with Nomad
* Clean separation of concerns
* Reproducible local + CI workflow
* No Docker Compose coupling
* One-command developer experience
