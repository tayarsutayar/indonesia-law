# Appendix B — Full SQL Schema

Base schema from the original plan. Apply the corrections in `03-data-model.md` §2 on top of it.

### 1.1 Corpus
```sql
-- Instrument identity
CREATE TABLE work (
  id UUID PRIMARY KEY,
  jenis TEXT NOT NULL,             -- UUD, TAP_MPR, TAP_MPRS, UU, UU_DARURAT, UU_FEDERAL, PERPPU, PENPRES, PP, PERPRES, KEPPRES, PERMEN, PMK, KMK, STAATSBLAD, ORDONNANTIE, MAKLUMAT, QANUN, PERDASUS, PERDASI, PERDA, PUTUSAN, ...
  era TEXT NOT NULL,               -- pra_kemerdekaan | revolusi_fisik | ris | uuds_1950 | orde_lama | orde_baru | reformasi
  nomor TEXT, tahun INT,
  instansi TEXT,
  judul TEXT,
  norm_character TEXT DEFAULT 'regeling', -- regeling | beschikking | mixed (for pre-2004 Keppres filtering)
  canonical_key TEXT UNIQUE,       -- jenis|nomor|tahun|instansi OR staatsblad|tahun|nomor
  status_aturan TEXT,              -- berlaku | dicabut | diubah | dicabut_sebagian | ...
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE work_date (           -- dates kept separate, never assumed
  work_id UUID REFERENCES work, kind TEXT, -- ditetapkan | diundangkan | mulai_berlaku | berlaku_surut
  date DATE, evidence_node_id UUID, PRIMARY KEY (work_id, kind)
);

-- Physical copy per source (supports Dual-Manifestation for colonial codes)
CREATE TABLE manifestation (
  id UUID PRIMARY KEY, work_id UUID REFERENCES work,
  source_name TEXT, source_url TEXT NOT NULL,
  source_domain TEXT NOT NULL, is_gov_domain BOOL DEFAULT false,
  manifestation_kind TEXT DEFAULT 'official_original', -- official_original | doctrinal_translation | court_working_text
  language TEXT DEFAULT 'id',                          -- id | nl | ar | jv
  translation_author TEXT,                             -- e.g. "Prof. R. Subekti, S.H. & R. Tjitrosudibio", "MR. K.R.M.T. Tirtodiningrat"
  source_status_text TEXT, source_metadata JSONB,
  minio_key TEXT, sha256 TEXT, content_type TEXT, size_bytes BIGINT,
  is_canonical BOOL DEFAULT false, fetched_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Master publication registry covering all historical eras
CREATE TABLE master_registry_entry (
  id UUID PRIMARY KEY,
  era TEXT NOT NULL,               -- pra_kemerdekaan | revolusi_fisik | ris | uuds_1950 | orde_lama | orde_baru | reformasi
  year INT,
  instrument_type TEXT NOT NULL,
  nomor TEXT,
  title_hint TEXT,
  status TEXT NOT NULL,            -- missing | discovered | verified_not_issued
  discovered_work_id UUID REFERENCES work,
  source_discovered_url TEXT,
  source_discovered_domain TEXT,
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Dynamic temporal hierarchy mapping constitutional regimes across history
CREATE TABLE legal_hierarchy_era (
  id UUID PRIMARY KEY,
  era_code TEXT NOT NULL,          -- pra_1966 | tap_mprs_xx_1966 | tap_mpr_iii_2000 | uu_10_2004 | uu_12_2011
  valid_from DATE NOT NULL,
  valid_to DATE,
  rank_order INT NOT NULL,         -- 1 = highest
  instrument_type TEXT NOT NULL,   -- UUD, TAP_MPR, UU, PERPPU, ...
  notes TEXT
);

-- Numbered source text (Extractor output)
CREATE TABLE source_text (
  id UUID PRIMARY KEY, manifestation_id UUID REFERENCES manifestation,
  source_kind TEXT,                -- native | ocr | manual_transcription
  lines JSONB,                     -- [{n, text, page}]
  page_map JSONB, text_sha256 TEXT, extractor_version TEXT
);
```

### 1.2 Structure and Versioning
```sql
-- Node (smallest provision) in a source document
CREATE TABLE node (
  id UUID PRIMARY KEY, source_text_id UUID REFERENCES source_text,
  work_id UUID REFERENCES work,
  node_key TEXT NOT NULL,          -- stable ID: uu-1-2004/pasal-5/ayat-2/huruf-b OR bw-1847-23/buku-3/bab-2/pasal-1320
  type TEXT, label TEXT,           -- "Pasal", "5A", "Buku", "Alinea" exactly as written
  parent_id UUID REFERENCES node, ord INT,
  start_line INT, end_line INT,
  text TEXT NOT NULL,              -- verbatim slice of source_text
  text_sha256 TEXT, verbatim_ok BOOL, notes TEXT
);

-- Change operations read from amending instruments, court rulings, and scope derogations
CREATE TABLE amendment_op (
  id UUID PRIMARY KEY, source_work_id UUID, target_work_id UUID,
  op TEXT,                         -- replace | insert_after | insert_before | delete | revoke | revoke_partial | scope_derogation | court_annulment | conditional_interpretation
  target_node_key TEXT, content_node_id UUID,   -- new wording = verbatim node of the amending instrument
  is_scope_derogation BOOL DEFAULT false,       -- blanket subject-matter derogation (e.g. UUPA vs Buku II BW)
  derogation_subject TEXT,                      -- agraria_tanah | perkawinan | hukum_pidana
  scope_clause TEXT, exception_clause TEXT,
  effective_date DATE, effective_date_rule TEXT,-- immediate|fixed_delay|phased_provision|retroactive|contingent
  evidence_node_id UUID, evidence_lines INT4RANGE,
  confidence REAL, status TEXT
);

-- Per-provision version history (Git-like provision commit history)
CREATE TABLE node_version (
  id UUID PRIMARY KEY,
  work_id UUID, node_key TEXT, version_seq INT,
  content_node_id UUID REFERENCES node,   -- source node holding the wording in this version (null if deleted)
  change_type TEXT,                       -- original|amended|inserted|deleted|revoked|annulled_by_court|conditionally_unconstitutional
  valid_from DATE, valid_to DATE,         -- valid_to NULL = currently in force
  caused_by_op UUID REFERENCES amendment_op,
  court_annotation TEXT,                  -- amar putusan for MK/MA conditional interpretations
  phrase_mask JSONB,                      -- word/character offset masks for phrase-level court annulments
  renumbered_from TEXT,
  UNIQUE (work_id, node_key, version_seq),
  EXCLUDE USING gist (work_id WITH =, node_key WITH =, daterange(valid_from, valid_to) WITH &&)
);

CREATE TABLE consolidation_snapshot (
  id UUID PRIMARY KEY, work_id UUID, as_of DATE,
  tree JSONB, built_from_hash TEXT, built_at TIMESTAMPTZ
);
```

### 1.3 Relations
```sql
CREATE TABLE relation_type (code TEXT PRIMARY KEY, label TEXT, is_custom BOOL, inverse_code TEXT);

CREATE TABLE relation (
  id UUID PRIMARY KEY,
  from_work_id UUID, from_node_key TEXT,   -- nullable node → instrument-level relation
  to_work_id UUID,   to_node_key TEXT,
  type_code TEXT REFERENCES relation_type, custom_label TEXT,
  evidence_node_id UUID, evidence_lines INT4RANGE,
  confidence REAL, status TEXT             -- proposed | qc_passed | rejected | needs_review
);

CREATE TABLE unresolved_reference (
  id UUID PRIMARY KEY, from_node_id UUID, raw_reference TEXT, candidates JSONB, status TEXT
);
```

### 1.4 Execution, Logs, Tokens
```sql
CREATE TABLE run (
  id UUID PRIMARY KEY, mode TEXT,          -- manual | auto
  scope JSONB, status TEXT, started_at TIMESTAMPTZ, finished_at TIMESTAMPTZ,
  budget_usd NUMERIC, est_tokens BIGINT
);

CREATE TABLE doc_stage (                   -- status and attempts per document per stage
  work_id UUID, stage TEXT, status TEXT, attempts INT, last_error TEXT,
  input_hash TEXT, output_ref TEXT, updated_at TIMESTAMPTZ, PRIMARY KEY (work_id, stage)
);

CREATE TABLE agent_instance (
  id TEXT PRIMARY KEY, category TEXT, state TEXT,   -- idle|walking|working|blocked|dead
  current_task_id UUID, last_heartbeat TIMESTAMPTZ, host TEXT
);

CREATE TABLE task (
  id UUID PRIMARY KEY, run_id UUID, work_id UUID, stage TEXT, agent_id TEXT,
  task_key TEXT UNIQUE, status TEXT, started_at TIMESTAMPTZ, finished_at TIMESTAMPTZ, error TEXT
);

CREATE TABLE llm_call (
  id UUID PRIMARY KEY, run_id UUID, task_id UUID, work_id UUID, node_id UUID,
  agent_category TEXT, stage TEXT, prompt_id TEXT, preamble_version TEXT, model_deployment TEXT,
  prompt_tokens INT, completion_tokens INT, cached_tokens INT, reasoning_tokens INT,
  cost_usd NUMERIC(12,6), latency_ms INT, status TEXT, retry_of UUID,
  request_blob_key TEXT, response_blob_key TEXT,   -- MinIO, compressed
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE http_request_log (            -- proof of scraping-delay compliance
  id BIGSERIAL PRIMARY KEY, domain TEXT, url TEXT, status INT,
  applied_delay_ms INT, duration_ms INT, created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE event_log (                   -- append-only
  id BIGSERIAL PRIMARY KEY, ts TIMESTAMPTZ DEFAULT now(),
  run_id UUID, work_id UUID, agent_id TEXT, type TEXT, payload JSONB
);

CREATE TABLE qc_result (
  id UUID PRIMARY KEY, work_id UUID, tier TEXT, passed BOOL,
  issues JSONB, routed_to TEXT, created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE review_item (
  id UUID PRIMARY KEY, work_id UUID, node_id UUID, reason TEXT,
  payload JSONB, status TEXT, resolved_by TEXT, resolved_at TIMESTAMPTZ
);

CREATE TABLE prompt_version (id TEXT, version INT, body TEXT, golden_score REAL, active BOOL, PRIMARY KEY (id, version));
```

Key indexes: `node(work_id, node_key)`, `node_version(work_id, node_key, valid_from)`, `llm_call(created_at)`, `llm_call(agent_category, created_at)`, `event_log(ts)`, GIN on `relation`/`payload` where needed, `pg_trgm` on `work.judul`.
