[← Workshop home](../README.md)

# Lab 1 · Build the Resident 360
## Medallion end-to-end — mirror, ingest, transform, observe

**⏱ 90 min**  ·  **🎯 Focus:** #1 lineage (intro) · #2 orchestration · #3 Spark UI · #4 resource prioritisation · #5 DE features

### The story
Rahim's steps live in **Databricks**; his meals, events, programmes, rewards and the day's air quality are scattered
across app files and a public API. Today you bring it **all together in Fabric** — without moving the Databricks
estate — into a single **Resident 360** view, and you watch how Spark builds it.

### You'll build
- One **Lakehouse** (`lh_resident360`) with three schemas — **`bronze` → `silver` → `gold`**.
- A **zero-copy mirror** of the shared Databricks estate (`hpb_databricks_mirror`).
- The full medallion in **one well-documented notebook**: ingest app files + a live API → Bronze, clean → Silver,
  join with the mirror → **`gold.resident_360`** — trying **Data Wrangler** and **Copilot agent mode** along the way.
- A Direct Lake **semantic model** and a **Copilot-generated report**.
- Hands-on **Spark UI, resource prioritisation and monitoring** while your jobs run.

### Where this fits

```mermaid
flowchart LR
  DBX[("Azure Databricks<br/>hpb_databricks.gold")]
  FILES["Healthy 365 files"]
  API["data.gov.sg API"]
  subgraph LH["Lakehouse · lh_resident360"]
    MIR["Mirror · hpb_databricks_mirror<br/>(zero-copy)"]
    BRZ["bronze.*"]
    SLV["silver.fact_*"]
    GLD["gold.resident_360"]
  end
  SM["Semantic model · sm_activity"]
  RPT["Copilot report"]
  DBX -->|mirror| MIR
  FILES --> BRZ
  API --> BRZ
  BRZ --> SLV --> GLD
  MIR --> GLD
  GLD --> SM --> RPT
  style LH fill:#f7fbff,stroke:#0066cc,color:#003366
  classDef item fill:#cce5ff,stroke:#0066cc,stroke-width:2px,color:#003366;
  class SM,RPT item;
  classDef done fill:#eeeeee,stroke:#999999,color:#333333;
  class DBX done;
```

**Builds on:** the pre-seeded Databricks estate. Everything in Labs 2–4 extends the medallion you build here.

### Files
- `data/` — the seven Healthy 365 files you upload to the Lakehouse.
- `notebooks/resident360_medallion.ipynb` — the **one** end-to-end notebook (Bronze → Silver → Gold + observability).

> **New to Fabric?** Every screen is pictured below. If a button hides behind a **⋯ (More options)** menu or the
> window feels cramped, **maximise your browser** — Fabric hides ribbon buttons on narrow windows.

---

### Task 1 — Workspace, Lakehouse & mirror the Databricks estate

**A Lakehouse** is the storage container for all your tables; **mirroring** brings the Databricks `gold` tables into
Fabric with **zero copies** (Fabric reads them live).

1. Open your assigned workspace **`HPB Workshop - <Your Name>`**. On the toolbar click **+ New item**.

   ![Empty workspace with the "+ New item" button on the toolbar.](../docs/images/lab1/lab1-01-workspace-newitem.png)

2. In the panel, search `lakehouse` and click the **Lakehouse** tile.

   ![The New item panel with the Lakehouse tile.](../docs/images/lab1/lab1-02-newitem-panel.png)

3. Name it **`lh_resident360`**, keep **Lakehouse schemas** ticked, click **Create**.

   ![The New Lakehouse dialog with "lh_resident360" typed and Lakehouse schemas ticked.](../docs/images/lab1/lab1-04-lakehouse-named.png)

4. Back in the workspace, click **+ New item** again → search `Mirrored Azure Databricks` → click the
   **Mirrored Azure Databricks catalog** tile.

   ![The New item panel filtered to the Mirrored Azure Databricks catalog tile.](../docs/images/lab1/lab1-06-newitem-mirror-search.png)

5. In the wizard: keep **Existing connection**, pick the shared workshop connection → **Next** → choose catalog
   **`hpb_databricks`**, tick the **`gold`** schema → **Next**.

   ![The Choose data step with hpb_databricks and the gold schema ticked.](../docs/images/lab1/lab1-09-mirror-choosedata.png)

6. On **Review and create**, change the **Name** to exactly **`hpb_databricks_mirror`** → **Create**.

   ![The Review step with the name changed to hpb_databricks_mirror.](../docs/images/lab1/lab1-10-mirror-review-name.png)

   > ⚠️ The name **must** be `hpb_databricks_mirror` (with the `_mirror` suffix) — the notebook refers to it by this
   > exact name. If sign-in ever says *"Sign in canceled,"* click **Sign in** again (1–3 tries).

7. The `gold` tables sync in 1–3 min. **Verify (zero-copy):** open the mirror → **SQL analytics endpoint** →
   **New SQL query** → `SELECT COUNT(*) FROM hpb_databricks_mirror.gold.dim_resident;` → expect **1500**.

> **Note:** don't shortcut the mirror into a `gold`/`silver`/`bronze` schema of `lh_resident360` — a read-only shortcut
> collides with the writable medallion you build next. The notebook reads the mirror directly instead.

---

### Task 2 — Upload the files & run the medallion notebook

This is the heart of the lab: land the raw files, then run **one notebook** that builds Bronze → Silver → Gold.

#### 2a · Upload the seven app files to `Files/landing/`

1. Open **`lh_resident360`**. Hover the **Files** node → **⋯ (More options)** → **New subfolder** → name it **`landing`**.

   ![The ⋯ menu on the Files node with New subfolder.](../docs/images/lab2/lab2-02-files-menu.png)

2. Hover **`landing`** → **⋯** → **Upload → Upload files** → select **all seven files** from the kit's `data/` folder →
   **Upload**. Confirm the folder shows *"Files 7"*.

   ![The landing folder with all seven uploaded files.](../docs/images/lab2/lab2-08-landing-files.png)

#### 2b · Import & attach the notebook

3. Workspace toolbar → **Import → Notebook → From this computer** → pick
   **`resident360_medallion.ipynb`** from the kit's `notebooks/` folder.

   ![Import → Notebook → From this computer.](../docs/images/lab2/lab2-09-import-notebook-menu.png)

4. Open the notebook → Explorer **Add data items → From OneLake catalog** → tick your **`lh_resident360`**
   **Lakehouse** (the one whose Location is your workspace — **not** its SQL analytics endpoint) → **Add**.

   ![The OneLake catalog picker; choose the Lakehouse, not the SQL endpoint.](../docs/images/lab2/lab2-13-onelake-picker.png)

   > ⚠️ The picker lists `lh_resident360` more than once. Pick the **Lakehouse** — it's the one that can read
   > `Files/landing/` and write tables. The SQL endpoint can't write, so the run would fail.

#### 2c · Run it — and try Data Wrangler, observability & Copilot

5. Read each section's markdown, then **Run all** (first run starts a Spark session, ~1–3 min). Watch the layers
   appear under **Tables**: `bronze.*` → `silver.fact_*` → `gold.resident_360`.

   ![The medallion notebook after a successful run, tables created.](../docs/images/lab2/lab2-15-notebook-run-complete.png)

6. **Data Wrangler (Section 1).** After Bronze lands, open `bronze.h365_meal_logs` in **Data Wrangler** (Explorer ⋯ →
   *Open in Data Wrangler*), try **Drop missing values** on `calories` and a type cast, then **Add code to notebook** —
   see how clicks become code. *(Silver does the authoritative cleaning; this is just to experience the tool.)*
   <!-- screenshot: lab1 Data Wrangler (to capture) -->

7. **Observability (Section 6).** Run the **skewed** then **tuned** cells and compare them in the **Spark jobs** view
   and the **Monitor** hub — one long task vs. many short parallel tasks. Note the **resource-prioritisation** guidance.
   <!-- screenshot: lab1 Spark UI / Monitor (to capture) -->

8. **Copilot agent mode (Section 7).** Open **Copilot** in the toolbar, switch to **agent mode**, and ask it to profile
   or chart `gold.resident_360`. Watch it plan → generate → run.
   <!-- screenshot: lab1 Copilot agent (to capture) -->

> **Done when you see:** `bronze.*` (6 tables + `env_air_quality`), `silver.fact_*` (6), and **`gold.resident_360`**
> (1,500 rows) with an `is_disengaged` split (~30–40% disengaged).

---

### Task 3 — Semantic model

A **semantic model** is the layer reports and (later) the data agent read from. You'll compare it against an **ontology**
in Lab 4 — so build it now.

1. Open the mirror's **SQL analytics endpoint** (or the Lakehouse's) → ribbon **New semantic model** → name it
   **`sm_activity`** → tick **`dim_resident`** and **`daily_activity`** → **Confirm**.

   ![The New semantic model dialog with dim_resident and daily_activity ticked.](../docs/images/lab1/lab1-12-new-semantic-model.png)

2. In the **Model view** (switch **Viewing → Editing** if needed) → **Manage relationships → New relationship**:
   `daily_activity(resident_id)` → `dim_resident(resident_id)`, **Many-to-one**, **Single** → **Save**.

   ![The sm_activity model view with the two tables.](../docs/images/lab1/lab1-13-model-relationship.png)

---

### Task 4 — Let Copilot build the report

Instead of hand-placing visuals, let **Copilot** suggest and build the report pages for you.

1. From **`sm_activity`** → **New report** (or **Create report → Auto-create / with Copilot**).
2. Open **Copilot** in the report → choose **Suggest content** / *"Generate a report"*. Copilot proposes pages
   (e.g. *Activity by region*, *Disengagement overview*) and lays out the visuals automatically.
3. Review the suggested pages, keep what's useful, and **Save** as **`rpt_activity`**.
   <!-- screenshot: lab1 Copilot report (to capture) -->

> **Done when you see:** a multi-page report Copilot built from your semantic model — no manual visual placement.

---

### ✅ Checkpoint
- [ ] `lh_resident360` Lakehouse + `hpb_databricks_mirror` (zero-copy count = 1500)
- [ ] `bronze.*`, `silver.fact_*`, and `gold.resident_360` all created by the one notebook
- [ ] Tried **Data Wrangler**, the **Spark UI / Monitor**, and **Copilot agent mode**
- [ ] `sm_activity` semantic model + a **Copilot-built** report

### 🟡 Challenge (optional)
- **Fell behind?** Materialize the pre-built `resident_360_prebuilt` from the shared estate into your own `gold` schema
  (one Spark cell) and continue.
- Enforce an explicit schema in the Bronze reads and route bad rows to a `bronze.h365_meal_logs_rejects` table.
- Ask Copilot (agent mode) to add a **data-quality summary** cell over `gold.resident_360`.

---

### Next up
**[Lab 2 · Metadata-Driven Lakehouse](../lab2-metadata-lakehouse/README.md)**
