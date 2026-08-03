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

**Full replica deployed (22 workspace items).** Beyond the SQL DB + 3 lakehouses, the following were deployed
via API to make the workspace faithfully match the original framework workspace:
- **9 framework notebooks** (`etl_constants`, `data_quality`, `elt_parallel`, `common_utils`,
  `transformation_utils`, `anonymization_utils`, `data_profiling`, `data_validation`, `prep_validation_criteria`)
  — imported from the framework repo's `elt_framework` / `data_profiling` / `data_validation` modules.
- **3 pipelines** (`PL_Auditing`, `PL_SendEmailNotification`, `PL_SendTeamsNotification`) — created via the
  Fabric `dataPipelines` REST API.
- **Dashboard** (`LakehouseIngestionDashboard` **report + semantic model**) — published via the Power BI
  Import API.

**Known post-deploy fix-ups (tracked in backlog — connections point at the dead old server):**
1. **2 dynamic-ingestion pipelines** (`PL_DynamicIngestionPipelineFullLoad_SQL`, `…IncrmLoad_SQL`) would **not**
   convert via REST (Copy activities carry embedded dataset/connection refs). Import via the UI:
   **New → Data pipeline → Import from pipeline template** (zips in the private
   `hpb-fabric-workshop-facilitator/framework-pipelines/`), then rewire connections.
2. **Pipeline connections.** The 3 API-created pipelines reference the legacy linked service
   `…database.windows.net;metadatadb admin` + a connection GUID that doesn't exist here → they **error on run**
   until rewired to the new `metadatadb` (notifications also fail on MCAP). Expected.
3. **Dashboard semantic-model rebind.** The published semantic model still carries the **old** metadatadb
   connection baked into the `.pbix`. Rebind it to the new `metadatadb`.

   **Option A — UI (quick):** workspace → the `LakehouseIngestionDashboard`
   **semantic model** → **Settings → Parameters** (set `SQL connection string` = `<SQL_SERVER>`,
   `Database name` = `<SQL_DB>` from the private record) → **Data source credentials** → sign in with **Entra/OAuth2**,
   then refresh. Until then the report shows no data.

   **Option B — scripted (validated, repeatable):** run the following against the Power BI REST API
   (Azure CLI signed in as a workspace admin). Replace `<WS>`, `<DATASET>`, `<SQL_SERVER>`, `<SQL_DB>`:

   ```powershell
   $ws="<WS>"; $dataset="<DATASET>"
   $server="<SQL_SERVER>"; $db="<SQL_DB>"
   $pbi = az account get-access-token --resource "https://analysis.windows.net/powerbi/api" --query accessToken -o tsv
   $sql = az account get-access-token --resource "https://database.windows.net/" --query accessToken -o tsv
   $h = @{ Authorization="Bearer $pbi"; "Content-Type"="application/json" }
   # 1) repoint parameters
   $body = @{ updateDetails=@(@{name="SQL connection string";newValue=$server},@{name="Database name";newValue=$db}) } | ConvertTo-Json -Depth 5
   Invoke-RestMethod -Method Post -Uri "https://api.powerbi.com/v1.0/myorg/groups/$ws/datasets/$dataset/Default.UpdateParameters" -Headers $h -Body $body
   # 2) take over + read the datasource's gateway/datasource id
   Invoke-RestMethod -Method Post -Uri "https://api.powerbi.com/v1.0/myorg/groups/$ws/datasets/$dataset/Default.TakeOver" -Headers $h
   $ds = (Invoke-RestMethod -Uri "https://api.powerbi.com/v1.0/myorg/groups/$ws/datasets/$dataset/datasources" -Headers $h).value[0]
   # 3) bind Entra/OAuth2 credentials with the SQL access token
   $cred = '{"credentialData":[{"name":"accessToken","value":"' + $sql + '"}]}'
   $cbody = @{ credentialDetails=@{ credentialType="OAuth2"; credentials=$cred; encryptedConnection="Encrypted"; encryptionAlgorithm="None"; privacyLevel="Organizational" } } | ConvertTo-Json -Depth 6
   Invoke-RestMethod -Method Patch -Uri "https://api.powerbi.com/v1.0/myorg/gateways/$($ds.gatewayId)/datasources/$($ds.datasourceId)" -Headers $h -Body $cbody
   # 4) refresh
   Invoke-RestMethod -Method Post -Uri "https://api.powerbi.com/v1.0/myorg/groups/$ws/datasets/$dataset/refreshes" -Headers $h -Body (@{notifyOption="NoNotification"} | ConvertTo-Json)
   ```

   Verify with `GET …/datasets/$dataset/refreshes?$top=1` → `status: Completed`. (The OAuth2 token expires ~1h,
   but the bound credential persists for scheduled refreshes.)

4. **Participant read access (read-mostly Lab 2).** Workspace **Viewers cannot use the `metadatadb` portal
   query editor** (New Query is disabled), so Lab 2 reads `metadatadb` from the participant's **own Lab 1
   notebook** via `assets/metadatadb-read-cell.py`. Preflight per participant: **share the framework workspace
   as Viewer**, then grant DB-level read on the `mtd` schema so the notebook token can query:

   ```sql
   -- run in metadatadb (as an admin) for each participant UPN
   CREATE USER [rahim.tester@contoso.onmicrosoft.com] FROM EXTERNAL PROVIDER;
   GRANT SELECT ON SCHEMA::mtd TO [rahim.tester@contoso.onmicrosoft.com];
   GRANT EXECUTE ON SCHEMA::mtd TO [rahim.tester@contoso.onmicrosoft.com];  -- for the audit-hook SP
   ```

   Fill `SQL_SERVER` / `SQL_DB` into both `assets/metadatadb-read-cell.py` and `assets/audit-hook-cell.py`.

5. **Rebrand the dashboard title (cosmetic).** The stock report title reads *"Contoso Data Ingestion
   Dashboard"*. Before the workshop, edit the report → the title text box → rename to an HPB-appropriate
   label (e.g. *"HPB Lakehouse Ingestion Dashboard"*).

> Option C (audit-hook + seeded rows) already delivers the observability/traceability story for the workshop
> **without** the pipelines running — the fix-ups above only matter for a live end-to-end ingestion demo.
