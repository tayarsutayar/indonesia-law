# Security Policy — Indonesia Law

## 1. Overview
Indonesia Law handles public legal statutes, automated parsing pipelines, and multi-agent AI workflows. Because the platform interacts with cloud LLM providers (Azure OpenAI), local storage clusters (PostgreSQL, Redis, MinIO), and external government/legal websites, maintaining strict credential hygiene and environment isolation is vital.

---

## 2. Vibe Coding & Agent Security Guidelines

When using AI coding assistants (Cursor, Windsurf, Claude Code, GitHub Copilot, Antigravity, etc.) to develop this repository:

1. **Protect Environment Secrets**:
   - Keep all credentials in `.env`.
   - Never commit `.env` or files matching `*.key`, `*.pem`, `*.secret`, `*.token`.
   - Keep `.env.example` populated with placeholder strings only.
2. **Prevent AI Context Leakage**:
   - `.cursorignore` and `.agentignore` are configured to prevent AI tools from ingesting `.env` and database dumps into context windows.
   - Do not paste API keys (`AZURE_OPENAI_API_KEY`, etc.) directly into LLM chat prompts.
3. **Verify Before Committing**:
   - Run `bash scripts/verify-secrets.sh` before staging and committing changes.
   - Inspect git staging status using `git status` and `git diff --staged` to confirm no sensitive files are tracked.

---

## 3. Incident Response & Secret Rotation

If a secret or API key is accidentally committed or leaked:

1. **Immediately Revoke and Rotate**:
   - **Azure OpenAI**: Generate a new key in Azure Portal and invalidate the compromised key.
   - **Database / MinIO**: Update passwords in `.env` and restart containers.
   - **App Static Token**: Generate a new 32-byte hex token (`openssl rand -hex 32`) and update dependent clients.
2. **Purge from Git History**:
   - Do NOT just delete the file in a new commit. Use `git filter-repo` or BFG Repo-Cleaner to completely expunge the secret from commit history.
3. **Notify the Team**:
   - Report the incident so that any active tokens can be audited for unexpected usage spikes.

---

## 4. Reporting a Security Vulnerability

If you discover a security vulnerability within Indonesia Law, please report it privately:
* **Email**: `security@indonesia-law.id` (or the repository administrator)
* **Response SLA**: Initial acknowledgment within 48 hours.

Please include:
* Description of the vulnerability.
* Steps to reproduce or proof-of-concept (POC).
* Potential impact.

