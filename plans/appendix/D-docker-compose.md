# Appendix D — Docker Compose and Environment

Reference YAML from the original plan, renamed for Indonesia Law. Apply the service table in `02-architecture.md` §7 (e.g., `worker-browser` is required from Phase 4).

```yaml
# docker-compose.yml
name: indonesia-law

x-backend: &backend
  build: ./backend
  env_file: .env
  depends_on:
    postgres: { condition: service_healthy }
    redis:    { condition: service_healthy }
    minio:    { condition: service_started }
  restart: unless-stopped

services:
  postgres:
    image: pgvector/pgvector:pg16
    environment:
      POSTGRES_DB: indonesia_law
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
    volumes: [pgdata:/var/lib/postgresql/data]
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER} -d indonesia_law"]
      interval: 5s
      retries: 10

  redis:
    image: redis:7-alpine
    command: ["redis-server", "--appendonly", "yes"]
    volumes: [redisdata:/data]
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 5s
      retries: 10

  minio:
    image: minio/minio
    command: server /data --console-address ":9001"
    environment:
      MINIO_ROOT_USER: ${MINIO_ROOT_USER}
      MINIO_ROOT_PASSWORD: ${MINIO_ROOT_PASSWORD}
    volumes: [miniodata:/data]
    ports: ["9001:9001"]   # console (restrict / do not expose publicly)

  api:
    <<: *backend
    command: uvicorn app.main:app --host 0.0.0.0 --port 8000
    ports: ["8000:8000"]

  orchestrator:
    <<: *backend
    command: python -m app.graphs.run_orchestrator

  scheduler:
    <<: *backend
    command: python -m app.scheduler.main

  # ---- Swarm workers (scale with: docker compose up -d --scale worker-split=8) ----
  worker-scout:
    <<: *backend
    command: celery -A app.workers.celery_app worker -Q q.scout -c 1 -n scout@%h
  worker-fetch:
    <<: *backend
    command: celery -A app.workers.celery_app worker -Q q.fetch -c 1 -n fetch@%h
  worker-extract:
    <<: *backend
    command: celery -A app.workers.celery_app worker -Q q.extract -c 2 -n extract@%h
  worker-split:
    <<: *backend
    command: celery -A app.workers.celery_app worker -Q q.split -c 2 -n split@%h
  worker-relation:
    <<: *backend
    command: celery -A app.workers.celery_app worker -Q q.relation -c 2 -n relation@%h
  worker-version:
    <<: *backend
    command: celery -A app.workers.celery_app worker -Q q.version,q.compile -c 2 -n version@%h
  worker-qc:
    <<: *backend
    command: celery -A app.workers.celery_app worker -Q q.qc.node,q.qc.relation,q.qc.version,q.qc.display,q.qc.chief -c 2 -n qc@%h

  # Only if an adapter needs JS rendering
  playwright-worker:
    build: ./backend
    command: celery -A app.workers.celery_app worker -Q q.fetch.js -c 1
    env_file: .env
    profiles: ["browser"]

  frontend:
    build: ./frontend
    ports: ["3000:80"]
    depends_on: [api]

  # ---- Optional observability ----
  prometheus:
    image: prom/prometheus
    volumes: [./ops/prometheus.yml:/etc/prometheus/prometheus.yml:ro]
    profiles: ["observability"]
  grafana:
    image: grafana/grafana
    ports: ["3001:3000"]
    profiles: ["observability"]
  langfuse:                # optional extra LLM tracing
    image: langfuse/langfuse:2
    profiles: ["observability"]

volumes: { pgdata: {}, redisdata: {}, miniodata: {} }
```

`.env.example` (key settings):

```
AZURE_OPENAI_ENDPOINT=
AZURE_OPENAI_API_KEY=
AZURE_OPENAI_API_VERSION=
AZURE_OPENAI_DEPLOYMENT=          # the "gpt 6 luna" deployment name
LLM_BUDGET_USD_PER_DAY=
LLM_TPM_LIMIT=
SCRAPE_MIN_DELAY_SEC=5
SCRAPE_JITTER_PCT=30
SCRAPE_PER_DOMAIN_CONCURRENCY=1
POSTGRES_USER= / POSTGRES_PASSWORD=
MINIO_ROOT_USER= / MINIO_ROOT_PASSWORD=
APP_STATIC_TOKEN=
```
