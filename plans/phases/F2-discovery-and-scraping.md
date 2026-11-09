# F2 — Polite Discovery, Scraping and Manual Runs (1–2 weeks)

**Goal:** Indonesia Law can discover instruments from a real source at scale without being blocked, and an operator can start a scoped run from the UI.

## Tasks

**Scraping**
- [ ] Redis per-domain rate limiter (min interval, ±30% jitter, concurrency 1), robots.txt + `Crawl-delay`, honest `IndonesiaLawBot` User-Agent, crawl windows.
- [ ] Backoff on 429/503, auto-pause blocked domains, `domain.throttled` / `domain.paused` events.
- [ ] Raw response cache (ETag / If-Modified-Since); `http_request_log` for every request.
- [ ] Adapter interface + primary source adapters: BPK JDIH, JDIHN, Setneg/Setkab, Peraturan.go.id, and MKRI; seed import from 1945–present master registry grid.
- [ ] Search Hunter: integration with search engine API (or SearXNG) to formulate queries targeting unindexed historic/archival PDFs on `.go.id` and national libraries.
- [ ] Heritage Scout: task queue triggered by citations to unindexed historic predecessors.
- [ ] Scout: listing parsing, LLM metadata extraction (`scout_metadata@v1`) only for unstructured pages; dedup by canonical key; conflicts → manifestations; canonical rule (D5).
- [ ] Playwright `worker-browser` for `q.fetch.js` if the source needs it.

**Runs**
- [ ] `run` model, `POST /api/runs`, `/estimate`, `/start|pause|resume|stop`, `/retry-failed`.
- [ ] Dry-run estimator (documents, pages, tokens, cost) — first version from F1 measurements.
- [ ] Queue priorities (instrument hierarchy, manual > auto).

**Frontend**
- [ ] `/kendali` manual-run wizard: scope → estimate → budget & workers → confirm → start; pause/stop with effect shown before confirming.
- [ ] `/peraturan` list: virtualized table with filters (jenis, tahun, status, stage).

## Exit Criteria

- 1,000 metadata records crawled from the primary source without a block.
- A SQL query over `http_request_log` shows every request respected the configured minimum delay and concurrency (attach the query and result).
- Duplicate records from two sources become one `work` with two manifestations.
- A run started from the wizard can be paused and resumed; state is visible in the UI and DB.
