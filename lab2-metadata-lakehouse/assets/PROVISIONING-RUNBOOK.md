# Metadata-Driven Lakehouse — Provisioning Runbook (facilitator)

**Purpose:** recreate the metadata-driven framework in the HPB workshop workspace (tenant + capacity
coordinates in the private facilitator record) so it **audits and surfaces the medallion the participants build in Lab 1**
(Option C integration). This runbook makes future provisioning fast and repeatable.

> This was first deployed in an earlier demo tenant ("Metadata Driven Lakehouse Workspace"). This runbook reproduces it
> in the workshop tenant and wires it to Lab 1's `lh_resident360`.

---

## 0 · What gets deployed (21 items)

| Item | Type | Role |
|------|------|------|
| `metadatadb` | Fabric **SQL Database** | Config + audit store — the "brain" (`mtd.ingest_control`, `mtd.ingest_audit`, `capture_audit_event_sp`) |
| `bronze_layer_lakehouse` / `silver_layer_lakehouse` / `gold_layer_lakehouse` | Lakehouse ×3 | The framework's own medallion (reference) |
| `PL_Auditing` | Data pipeline | Writes every run's row counts / status / duration into `mtd.ingest_audit` |
| `PL_DynamicIngestionPipelineFullLoad_SQL` / `…IncrmLoad_SQL` | Data pipeline ×2 | Config-driven full + incremental ingestion |
| `PL_SendEmailNotification` / `PL_SendTeamsNotification` | Data pipeline ×2 | Success/failure notifications *(disabled on MCAP — see note)* |
| `elt_bronze_to_gold`, `data_validation`, `data_profiling`, `nb_profiling_setup` | Notebook ×4 | ELT + DQ + profiling |
| `LakehouseIngestionDashboard`, `LakehouseDashboard_MultiPage` | Report + Semantic model ×2 | **Observability & traceability** UI |

**Artifacts to deploy them are in** `./framework-artifacts/`:
- `MetaStoreSetup_01.sql` (+ `_02`) — creates the `mtd` schema, control/audit tables, `capture_audit_event_sp`.
- `Insert_In_SQLDB_Source_information_For_FullLoad.sql` / `…IncrLoad.sql` — sample control rows.
- `PL_*.zip` ×5 — the AzureSQLDB-variant pipelines (import via **New item → Data pipeline → Import**).
  **These live in the private `hpb-fabric-workshop-facilitator/framework-pipelines/`** (kept out of the public
  repo — they're optional and carry legacy internal connection names). *(All other artifacts here are public.)*
- `elt_metastoresql_script.sql`, `data_quality.ipynb` — ELT/DQ layer.
- `LakehouseIngestionDashboard.pbix`, `LakehouseDashboard_MultiPage.pbit` — the dashboards.

---

## 1 · Deployment steps (LEVEL-UP §5.1–5.12, adapted)

> Do these as the **facilitator/admin** in the HPB workspace, on the **active** F-capacity.

1. **Workspace.** Use a dedicated **`HPB Metadata Framework`** workspace (or a shared reference workspace all
   participants can view), bound to the workshop capacity.
2. **Metadata store.** **+ New item → SQL Database** → name **`metadatadb`**. Open its query editor and run
   **`MetaStoreSetup_01.sql`** then **`MetaStoreSetup_02.sql`** (creates `mtd.ingest_control`, `mtd.ingest_audit`,
   `mtd.capture_audit_event_sp`).
3. **Lakehouses.** Create `bronze_layer_lakehouse`, `silver_layer_lakehouse`, `gold_layer_lakehouse`
   (keep Lakehouse schemas default).
4. **Folder structure.** In each lakehouse's **Files**, create the `data_ingestion/Audit`, `Notification`, and
   `…_To_Fabric_Lakehouse` folders (per guide §5.4).
5. **Import pipelines.** *(Optional — see §5.2; the zips are in `hpb-fabric-workshop-facilitator/framework-pipelines/`.)*
   **+ New item → Data pipeline → Import** for each: `PL_Auditing`, `PL_SendEmailNotification`,
   `PL_SendTeamsNotification`, `PL_DynamicIngestionPipelineFullLoad_SQL`, `…IncrmLoad_SQL`.
6. **Wire connections.** In the Full/Incremental pipelines, set the 4 connections (source DB, `metadatadb`, target
   lakehouse, audit) and the 3 **Invoke pipeline** references (→ `PL_Auditing`, notifications). (Guide §5.8.)
7. **Seed control rows.** Run `Insert_In_SQLDB_Source_information_For_FullLoad.sql` / `…IncrLoad.sql` against
   `metadatadb` to register the sources to ingest.
8. **Run & verify.** Run the **Full Load** pipeline → confirm rows land in `bronze_layer_lakehouse` and an audit row
   appears in `mtd.ingest_audit`. Run **Incremental Load** → confirm the `YYYY/MM/DD` folder + new audit row.
9. **Dashboard.** Publish `LakehouseIngestionDashboard.pbix` (single ingestion page) or open
   `LakehouseDashboard_MultiPage.pbit` in Power BI Desktop → point it at **`metadatadb`**
   (Server = the SQL DB's connection string; Auth = **Microsoft account / Entra**) → publish to the workspace.

> ⚠️ **MCAP tenant:** email/Teams notification activities **fail** (tenant not enabled for O365/Teams send). Import the
> pipelines for completeness but expect the notification steps to error — this is expected and documented in the guide.

---

## 2 · Option C — surface the participants' Lab 1 activity

The goal: the ingestion dashboard shows entries for **their own `lh_resident360` medallion**, not just the framework's
sample loads. Do this by making Lab 1's runs write audit rows into `metadatadb`.

1. **Grant access.** Give the participant (or the shared identity) access to `metadatadb`.
2. **Register their tables.** Insert control rows in `mtd.ingest_control` describing the Lab 1 medallion tables
   (`bronze.h365_*`, `silver.fact_*`, `gold.resident_360`) so the framework "knows" them.
3. **Emit an audit row from Lab 1.** Add one cell at the end of Lab 1's medallion notebook that calls
   `mtd.capture_audit_event_sp` with the run's row counts (`gold.resident_360` count, per-layer counts, status,
   duration, timestamp). Then their transform run **appears in the ingestion dashboard**.
   > A ready-to-paste `capture_audit_event_sp` call (with the Lab 1 counts wired in) lives in
   > `./audit-hook-cell.py` once the deployment is live.
4. **Verify traceability.** Open the dashboard → the participant sees their `gold.resident_360` load with row count,
   status, and timestamp — the observability + traceability outcome, over what *they* built.

---

## 3 · Known gotchas (from the earlier deployment)

- **`metadatadb` connection = Entra only.** In Power BI Desktop, use **Microsoft account** auth, not SQL/Windows.
- **Multi-page `.pbit` lineage tags** must be consistent across `DataModelSchema` / `UnappliedChanges` /
  `DiagramLayout` — if you regenerate pages, reuse the canonical tags already in `DiagramLayout` (see session
  `657f9c93…` for the fix). The pre-built `LakehouseDashboard_MultiPage.pbit` here is already correct.
- **`.pbit` repack must preserve OPC part order** (`[Content_Types].xml` near the front) or Power BI refuses to open.
- **Capacity must be active** to create the SQL DB / import pipelines / run.

---

## 4 · Source of truth

- Framework source: the internal Microsoft metadata-driven lakehouse framework (Customer Success) →
  `Lakehouse Implementation/`. *(Internal repo — request access from the Microsoft team; not linked here.)*
- Full step-by-step guide (with screenshots): the framework's `LEVEL-UP/data-ingestion-fabric/`
  "MetaData Driven Ingestion Framework — Step by Step Deployment Guide".
- Prior working deployment: an earlier internal provisioning run in the demo tenant.

---

## 5 · Live deployment record (workshop tenant)

> 🔒 **The live tenant coordinates for this deployment are kept in the private facilitator file**
> `hpb-fabric-workshop-facilitator/metadata-framework-deployment-record.md` (outside this public repo).
> The placeholders below (`<SQL_SERVER>`, `<SQL_DB>`, `<…-id>`) map 1:1 to that file. Fill them from there.

Deployed into the workshop tenant (id `<tenant-id>`) on the **F8 HPB capacity** (`fchpbfabric071502`).
Everything is live — future runs can point straight at it (no re-provisioning needed unless recreating).

| Thing | Value |
|-------|-------|
| Workspace | **`HPB Metadata Framework`** — id `<workspace-id>` |
| `metadatadb` item | SQL Database, id `<metadatadb-item-id>` |
| **`SQL_SERVER`** (connection string) | `<SQL_SERVER>` |
| **`SQL_DB`** (database name) | `<SQL_DB>` |
| Lakehouses | `bronze_layer_lakehouse` / `silver_layer_lakehouse` / `gold_layer_lakehouse` (ids in private file) |
| Tenant / sub | `<tenant-id>` / `<subscription-id>` |

**Done in this deployment:**
- `metadatadb` created; `MetaStoreSetup_01.sql` run → `mtd.ingest_control`, `mtd.ingest_audit`,
  `mtd.capture_audit_event_sp` all present (verified).
- 3 layer lakehouses created.
- **Option C seeded**: 5 `ingest_control` rows + 5 `ingest_audit` rows describing Lab 1's
  `lh_resident360` medallion (`bronze.h365_*`, `silver.fact_*`, `gold.resident_360`) — so the dashboard
  has real, relevant data on day one, before any participant runs the hook.
- `assets/audit-hook-cell.py` ships with `SQL_SERVER`/`SQL_DB` as **placeholders** — the facilitator fills
  them from the private record before Lab 2 (see that file's "Facilitator preflight" section).

**Two facilitator preflight steps remain (UI-only — can't be done headless):**

1. **Publish the dashboard.** The `.pbix`/`.pbit` here are parameterised on **`SQL connection string`** +
   **`Database name`** with **no baked default** (they prompt on open). In **Power BI Desktop**:
   open `LakehouseIngestionDashboard.pbix` → when prompted enter **`SQL connection string` = `<SQL_SERVER>`**,
   **`Database name` = `<SQL_DB>`** (from the private record) → auth = **Microsoft account / Entra** →
   **Publish** to the `HPB Metadata Framework` workspace.
   > Use **`LakehouseIngestionDashboard.pbix`** — it matches this **Ingestion-Only** deploy
   > (`ingest_control` + `ingest_audit`). The **multi-page `.pbit`** additionally needs
   > `enrich_*` / `serve_*` / `transformation_config` tables (full-medallion metastore) which this
   > Ingestion-Only deployment does **not** create — only use it if you also run the full metastore.
2. **Pipelines are optional.** The 5 `PL_*.zip` (in the private `hpb-fabric-workshop-facilitator/framework-pipelines/`)
   are ARM-template exports hard-wired to the **old demo-tenant** SQL linked service (a legacy
   `…database.windows.net;metadatadb admin` connection) and the notification ones fail on MCAP anyway.
   Option C (audit-hook + seeded rows) delivers the observability/traceability story **without** them.
   Import + rewire via the Fabric UI only if you want live config-driven ingestion.
