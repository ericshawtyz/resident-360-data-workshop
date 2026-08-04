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

   > **Note:** a fresh workspace opens on a **"predesigned task flow"** panel at the top — ignore it. Everything in
   > this lab starts from the **+ New item** button on the toolbar.

   ![Empty workspace with the "+ New item" button on the toolbar.](../docs/images/lab1/lab1-01-workspace-newitem.png)

2. In the panel, search `lakehouse` and click the **Lakehouse** tile.

   ![The New item panel with the Lakehouse tile.](../docs/images/lab1/lab1-02-newitem-panel.png)

3. Name it **`lh_resident360`**, keep **Lakehouse schemas** ticked, click **Create**.

   ![The New Lakehouse dialog with "lh_resident360" typed and Lakehouse schemas ticked.](../docs/images/lab1/lab1-04-lakehouse-named.png)

4. Back in the workspace, click **+ New item** again → search `Mirrored Azure Databricks` → click the
   **Mirrored Azure Databricks catalog** tile.

   ![The New item panel filtered to the Mirrored Azure Databricks catalog tile.](../docs/images/lab1/lab1-06-newitem-mirror-search.png)

5. In the wizard, the connection dropdown starts **empty** — no connection exists yet, so select **New connection**
   and fill in the shared Databricks details your facilitator provides:
   - **Databricks workspace URL** — e.g. `https://adb-....azuredatabricks.net`
   - **Authentication kind** — keep the default (**OAuth 2.0**); **sign in** with your workshop account when prompted.

   Click **Connect** (or **Next**).

   ![The New connection form for the Mirrored Azure Databricks catalog, with the workspace URL and OAuth sign-in.](../docs/images/lab1/lab1-08-mirror-connection.png)

   > If a connection was **already** set up for you, it appears in the dropdown listed by its Databricks **URL**
   > (`https://adb-....azuredatabricks.net`) — keep **Existing connection** and just pick it.

6. Choose catalog **`hpb_databricks`**, tick the **`gold`** schema → **Next**.

   ![The Choose data step with hpb_databricks and the gold schema ticked.](../docs/images/lab1/lab1-09-mirror-choosedata.png)

7. On **Review and create**, set the **Name** to **`hpb_databricks_mirror`** → **Create**.

   ![The Review step with the name set to hpb_databricks_mirror.](../docs/images/lab1/lab1-10-mirror-review-name.png)

   > **Note:** the notebook reads the mirror through a variable **`DBX = "hpb_databricks_mirror.gold"`**, set in the
   > notebook's **Section 0 · Setup** cell (and re-declared in the **Section 4 · Gold** cells). You can name the mirror
   > whatever you like — but if you use a name **other than** `hpb_databricks_mirror`, update every
   > `DBX = "...gold"` line to `"<your_mirror_name>.gold"` before you run the notebook. If sign-in ever says
   > *"Sign in canceled,"* click **Sign in** again (1–3 tries).

8. The `gold` tables sync in 1–3 min. **Verify (zero-copy):** open **`hpb_databricks_mirror`**, then switch to its
   **SQL analytics endpoint**. There are two ways to get there:
   - Inside the open mirror, click the **Databricks** dropdown (top-right) → **SQL analytics endpoint**, **or**
   - Click the green **View SQL endpoint** button in the centre of the mirror's page.

   ![The open mirror with the Databricks dropdown showing the "SQL analytics endpoint" option and the "View SQL endpoint" button.](../docs/images/lab1/lab1-1-sql-endpoint-switch.png)

   Then **New SQL query** → run `SELECT COUNT(*) FROM hpb_databricks_mirror.gold.dim_resident;` → expect **1500**.

   ![A New SQL query on the mirror's SQL analytics endpoint returning 1500 for dim_resident.](../docs/images/lab1/lab1-18-verify-count.png)

> **Note:** don't shortcut the mirror into a `gold`/`silver`/`bronze` schema of `lh_resident360` — a read-only shortcut
> collides with the writable medallion you build next. The notebook reads the mirror directly instead.

---

### Task 2 — Upload the files & run the medallion notebook

This is the heart of the lab: land the raw files, then run **one notebook** that builds Bronze → Silver → Gold.

#### 2a · Upload the seven app files to `Files/landing/`

1. Open **`lh_resident360`**. Hover the **Files** node → **⋯ (More options)** → **New subfolder** → name it **`landing`**.

   ![The ⋯ menu on the Files node with New subfolder.](../docs/images/lab2/lab2-02-files-menu.png)

2. Hover **`landing`** → **⋯** → **Upload → Upload files** → select **all seven files** from the kit's `data/` folder →
   **Upload**. Watch each file reach a green **Completed** tick, then confirm the folder shows *"Files 7"*.

   ![The Upload files panel with all seven files showing Completed.](../docs/images/lab1/lab1-2a-upload-complete.png)

   ![The landing folder listing all seven uploaded files (Files 7).](../docs/images/lab1/lab1-2a-landing-7files.png)

#### 2b · Import & attach the notebook

3. Workspace toolbar → **Import → Notebook → From this computer** → pick
   **`resident360_medallion.ipynb`** from the kit's `notebooks/` folder.

   ![Import → Notebook → From this computer.](../docs/images/lab2/lab2-09-import-notebook-menu.png)

4. Open the notebook → Explorer **Add data items → From OneLake catalog** → tick your **`lh_resident360`**
   **Lakehouse** (the one whose Location is your workspace — **not** its SQL analytics endpoint) → **Add**.

   ![The OneLake catalog picker; choose the Lakehouse, not the SQL endpoint.](../docs/images/lab2/lab2-13-onelake-picker.png)

   > ⚠️ The picker lists `lh_resident360` more than once. Pick the **Lakehouse** — it's the one that can read
   > `Files/landing/` and write tables. The SQL endpoint can't write, so the run would fail.

   Once attached, the Explorer shows **`lh_resident360`** and the notebook is ready to **Run all**.

   ![The medallion notebook open with lh_resident360 attached in the Explorer and Run all on the toolbar.](../docs/images/lab1/lab1-2b-notebook-attached.png)

#### 2c · Run it — and try Data Wrangler, observability & Copilot

5. Read each section's markdown, then **Run all** (first run starts a Spark session, ~1–3 min). Watch the layers
   appear under **Tables**: `bronze.*` → `silver.fact_*` → `gold.resident_360`. The full run is ~15–20 min on a
   shared capacity.

   ![The medallion notebook running all cells after the Spark session starts.](../docs/images/lab1/lab1-2c-run-all-started.png)

6. **Data Wrangler (Section 1).** After Bronze lands, get a feel for Fabric's no-code data cleaning:
   1. In the Explorer, expand **`lh_resident360` → Tables → `bronze`** and hover **`h365_meal_logs`** → **⋯** →
      **Open in Data Wrangler** (or ribbon **Home → Data Wrangler → bronze.h365_meal_logs**).
   2. In the left **Operations** panel, choose **Find and replace → Drop missing values**, pick the **`calories`**
      column, and **Apply** — watch the row count drop and the change appear in the **Cleaning steps** list.
   3. Try a second operation, e.g. **Transformations → Change column type** on `calories` → **Decimal**.
   4. Click **Add code to notebook** (top right) — Data Wrangler drops the equivalent PySpark into a new cell so you
      can see how the clicks became code. *(You don't need to run it — the notebook's Silver step does the
      authoritative cleaning; this is just to experience the tool.)*

   ![Data Wrangler open on bronze.h365_meal_logs: the column profiles, Operations panel, Cleaning steps and Summary.](../docs/images/lab1/lab1-2c-data-wrangler.png)

7. **Spark UI, monitoring & resource prioritisation (Section 6).** See *how* your jobs ran:
   1. Run the **skewed** cell, then the **tuned** cell in Section 6.
   2. Under a running/finished cell, click **… → View Spark job** (or the **Spark jobs** link) to open the **Spark UI**
      — compare the **skewed** job (one long-running task on a single partition) with the **tuned** job (many short,
      parallel tasks after Adaptive Query Execution).
   3. Left nav → **Monitor** hub → open this notebook's run to see duration, status and the Spark detail for each cell.
   4. Read the **resource-prioritisation** note in the cell (custom pool / Autoscale Billing for Spark) — how a
      nightly ETL and ad-hoc queries share the capacity.

   ![The inline Spark jobs monitor under a cell: job status Succeeded, stages/tasks, duration, rows and data read/written.](../docs/images/lab1/lab1-2c-spark-ui.png)

8. **Copilot in the notebook (Section 7).** Experience the AI assistant:
   1. Click **Copilot** on the notebook toolbar to open the chat panel.
   2. Ask it a concrete question about your data, for example:
      - *"Profile `gold.resident_360`: row count, % disengaged, and average steps by region. Add the result as a new cell."*
      - *"Chart average `mvpa_minutes` by `age_band` from `gold.resident_360`."*
   3. Watch Copilot **plan → generate a cell → run it**, then review the cell it added.

   ![Copilot in the notebook generating and running a cell over gold.resident_360.](../docs/images/lab1/lab1-21-copilot-agent.png)

> **Done when you see:** `bronze.*` (6 tables + `env_air_quality`), `silver.fact_*` (6), and **`gold.resident_360`**
> (1,500 rows) with an `is_disengaged` split of **roughly 12% disengaged** (about 180 of 1,500 residents flagged `1`).

![The Gold section output: gold.resident_360 = 1,500 rows, is_disengaged split ~182/1,318, and the DQ gate PASSED.](../docs/images/lab1/lab1-2c-gold-dq-results.png)

---

### Task 3 — Semantic model

A **semantic model** is the layer reports and (later) the data agent read from. You'll compare it against an **ontology**
in Lab 4 — so build it now on the two Databricks-mirror tables.

#### 3a · Create the model

1. Open **`hpb_databricks_mirror`** → its **SQL analytics endpoint**. On the **Home** ribbon click **New semantic model**.

   ![The mirror's SQL analytics endpoint with the New semantic model button on the ribbon.](../docs/images/lab1/lab1-11-mirror-tables.png)

2. In the dialog:
   - **Name** the model **`sm_activity`**.
   - Leave **Direct Lake on SQL** selected.
   - Under the **`gold`** folder, tick **`daily_activity`** and **`dim_resident`** (leave the others unticked).
   - Click **Confirm**.

   > ⚠️ Make sure **both** `daily_activity` **and** `dim_resident` show a tick before **Confirm** — it's easy to miss
   > one. (If you end up with only one, you can add the other later in step 3 via **Edit tables**.)

   ![The New semantic model dialog: name sm_activity, Direct Lake on SQL, daily_activity and dim_resident both ticked.](../docs/images/lab1/lab1-3a-new-sm-both-ticked.png)

#### 3b · Add the relationship

3. Open **`sm_activity`** — from the workspace list, click the model. It opens in **Model view**, starting in
   **Viewing** mode (read-only). Switch to **Editing**: click the **Viewing** button on the ribbon (top-left) → choose **Editing**.

   > **Note:** the model may **not** open automatically after you click **Confirm** — if it doesn't, open **`sm_activity`**
   > from the workspace list. The first switch to Editing shows a one-time *"Converting semantic model…"* message (~10 sec) — expected.

   ![Switching sm_activity from Viewing to Editing: the Viewing/Editing dropdown open on the ribbon, over the daily_activity and dim_resident tables.](../docs/images/lab1/lab1-3b-editing-switch.png)

4. If only one table is on the canvas, click **Edit tables** on the ribbon and tick the missing one (`daily_activity`
   or `dim_resident`), then **Confirm**.

5. On the ribbon click **Manage relationships → + New relationship** and set:
   - **From table:** `daily_activity`, **column** `resident_id`
   - **To table:** `dim_resident`, **column** `resident_id`
   - **Cardinality:** **Many to one (\*:1)** · **Cross-filter direction:** **Single** · **Make active:** on

   Click **Save**. *(Direct Lake infers cardinality from row counts and shows a banner saying so — here it correctly
   detects Many-to-one / Single.)*

   ![The New relationship dialog with both resident_id columns selected, Cardinality Many to one, Cross-filter Single, Make active on.](../docs/images/lab1/lab1-3b-new-relationship.png)

6. Close the dialog — the two tables now show the relationship line on the canvas.

   ![The sm_activity model view with the *→1 relationship line between daily_activity and dim_resident.](../docs/images/lab1/lab1-3b-relationship-line.png)

---

### Task 4 — Let Copilot build the report

Instead of hand-placing visuals, let **Copilot** suggest and build the report pages for you.

1. In the workspace list, hover the **`sm_activity`** row → **⋯ (More options)** → **Create report**. This opens the
   report editor bound to `sm_activity` (both tables appear in the **Data** pane).
   > *Tip:* the model view also has a **New report** button, but the **⋯ → Create report** path from the list is the
   > most reliable.

   ![The sm_activity ⋯ menu with Create report.](../docs/images/lab1/lab1-25-create-report-menu.png)

2. In the report editor, click **Copilot** on the toolbar to open the panel, then choose
   **Suggest content for a new report page**. Copilot proposes an outline of pages (e.g. *Resident activity overview*,
   *Steps and movement analysis*, *Sleep quality and recovery*, *Health metrics by demographic profile*).

   ![The Copilot panel in the report editor with "Suggest content for a new report page".](../docs/images/lab1/lab1-4-copilot-panel.png)

   ![Copilot's suggested report-page outline built from sm_activity.](../docs/images/lab1/lab1-4-copilot-suggested-pages.png)

3. Click **Create** under a page you like — Copilot builds the page and lays out the visuals for you. Repeat for any
   other pages, then press **Ctrl+S** and **Save** the report as **`rpt_activity`**.

   ![The Resident Activity Overview page Copilot built — cards and charts over sm_activity.](../docs/images/lab1/lab1-4-copilot-report-built.png)

> **Done when you see:** a report Copilot built from your semantic model — no manual visual placement. *(Copilot drafts
> may briefly show an axis warning on a visual until the fields settle — that's normal.)*

---

### ✅ Checkpoint
- [ ] **Task 1** — `lh_resident360` Lakehouse + `hpb_databricks_mirror` created; zero-copy count on the mirror's SQL analytics endpoint = **1500**
- [ ] **Task 2** — one notebook built `bronze.*`, `silver.fact_*`, and `gold.resident_360` (1,500 rows, ~12% disengaged); tried **Data Wrangler**, the **Spark UI / Monitor**, and **Copilot in the notebook**
- [ ] **Task 3** — `sm_activity` semantic model (Direct Lake) with the **`daily_activity` → `dim_resident` (Many-to-one)** relationship
- [ ] **Task 4** — a **Copilot-built** report saved as **`rpt_activity`**

---

### Next up
**[Lab 2 · Govern & Trace](../lab2-metadata-lakehouse/README.md)**
