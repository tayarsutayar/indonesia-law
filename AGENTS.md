# Instructions for Agent

## Project Context

* This project plans the Indonesia Law application for searching, reading, extracting, reviewing, and tracking the provenance of regulations. Use the documents in `plans/` as the product context when tasks are relevant.
* Provide explanations and feedback in Indonesian.

## Frontend and Design

* Before planning, creating, modifying, or reviewing frontend/UI/design work, read all `SKILL.md` files in `@.agents/skills/` and follow the applicable skills. Do not begin implementation before reading them.
* Also read any references or examples linked by the skills if relevant to the work. Currently, the available design skill is `@.agents/skills/apple-design/SKILL.md`.
* For product UI context, also follow `plans/07-web-apps.md`, especially the accessibility requirements, text/status integrity, and review flows.

## Security and Secrets

* Never read, output, log, or hardcode secrets, API keys, tokens, or private credentials.
* Never commit or stage `.env` or any secret files; refer exclusively to `.env.example` with placeholder values.
* Follow detailed security directives in `@.agents/rules/security.md` and [SECURITY.md](SECURITY.md).
* Run `bash scripts/verify-secrets.sh` before committing or finalizing file modifications.

## Project Rules

* Follow additional applicable instructions in `@.agents/rules/`.
* Keep changes as minimal as possible and consistent with existing structures and patterns.
