# F7 — Automation, Scale, Hardening and v1.0 Release (2 weeks)

**Goal:** Indonesia Law runs on its own, within budget, and can be operated and recovered by someone reading the runbook.

## Tasks

**Automation**
- [ ] Scheduler: incremental discovery, status re-check of instruments that may change, retry of failures, recompile.
- [ ] `auto_mode_config`: on/off, cron/time window, daily budget cap, type priorities, retry policy, notifications; `/kendali` auto-mode UI.
- [ ] Auto-pause on budget and error-rate thresholds.

**Scale and cost**
- [ ] Load and cost test on ~1,000 documents with 10+ workers: tokens/document by type, cost, throughput, error rate.
- [ ] Calibrate the dry-run estimator from these measurements.
- [ ] Projected full-corpus cost report for approval (`11` DoD).

**Hardening**
- [ ] Backups (`09` §5) and a documented restore test.
- [ ] Reverse proxy + HTTPS config example; verify no service is exposed without auth.
- [ ] Log retention jobs; `event_log` partitioning.
- [ ] `docs/runbook.md` (`09` §6).
- [ ] Final accessibility pass: axe on all pages + manual VoiceOver/NVDA pass; design checklist on all pages.

## Exit Criteria (= v1.0)

- Auto mode runs 72 hours without intervention; failures appear in the dashboard with reasons and none are silently dropped.
- Restore from backup into a fresh stack succeeds and the viewer shows the same data.
- Cost report approved.
- All items of the v1.0 Definition of Done in `11` §3 are met.
