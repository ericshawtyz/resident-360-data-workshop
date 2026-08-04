[← Workshop home](../README.md)

# Lab 2 · Govern & Trace

## Metadata-driven lakehouse — observability & traceability

**⏱ 60 min**  ·  **🎯 Focus:** #6 Data quality & traceability

### The story

In Lab 1 you built the Resident 360 medallion by hand. In production, HPB runs **hundreds** of such
loads — and needs to answer, at a glance: *did every load succeed? how many rows moved? how long did it
take? is the data consistent?* That's what a **metadata-driven lakehouse** gives you: a small **control +
audit database** (`metadatadb`) that every load reports into, and a **dashboard** that turns those rows
into observability and traceability — over a medallion that follows the exact bronze → silver → gold
pattern you just built.

You won't build the framework from scratch (that's a facilitator preflight — see
`assets/PROVISIONING-RUNBOOK.md`). Instead you'll **connect your Lab 1 medallion to it** and watch your
own transform runs surface in the governance dashboard.

### You'll do

- Read the framework's **control** table from your Lab 1 notebook to see how loads are config-driven.
- Add **one audit-hook cell** to your Lab 1 notebook so each run reports into `metadatadb`.
- Read the **audit** trail to see your own load on the record.
- Open the **Lakehouse Ingestion Dashboard** and read the observability + traceability story for **your** load.

> **Why from the notebook?** The framework workspace is shared with you **read-only**, so its `metadatadb`
> query editor is disabled for participants. Instead you'll read `metadatadb` straight from **your own**
> Lab 1 notebook using a tiny helper — it runs with **your** identity, which has read access to the tables.
> This is also closer to how a real pipeline talks to the control store.

### Where this fits

```mermaid
flowchart LR
  subgraph L1["Lab 1 · lh_resident360 ✓"]
    B["bronze.h365_*"]
    S["silver.fact_*"]
    G["gold.resident_360"]
  end
  HOOK["Audit-hook cell"]
  subgraph FW["HPB Metadata Framework"]
    MDB["metadatadb<br/>mtd.ingest_control<br/>mtd.ingest_audit"]
    DASH["Lakehouse Ingestion Dashboard"]
  end
  B --> HOOK; S --> HOOK; G --> HOOK
  HOOK --> MDB --> DASH
  classDef item fill:#cce5ff,stroke:#0066cc,stroke-width:2px,color:#003366;
  class MDB,DASH,HOOK item;
  classDef done fill:#eeeeee,stroke:#999999,color:#333333;
  class B,S,G done;
```

**Builds on:** the medallion from Lab 1. Everything here reports on tables you already created.

### Files

- `assets/metadatadb-read-cell.py` — a small helper cell that lets you read `metadatadb` from your notebook
  (defines `q("SELECT ...")`). You paste this in **Task 1**.
- `assets/audit-hook-cell.py` — the cell you paste at the end of your Lab 1 notebook to report your load
  into `metadatadb`. You paste this in **Task 2**.
- `assets/PROVISIONING-RUNBOOK.md` — *facilitator only*: how the framework was deployed (`metadatadb`,
  lakehouses, pipelines, dashboard). Read this only if you're setting the framework up.

> **Facilitator preflight (before the room starts):** deploy/verify the framework, share the
> `HPB Metadata Framework` workspace as **Viewer** with participants, grant them `SELECT` + `EXECUTE` on the
> `mtd` schema, and fill `SQL_SERVER` / `SQL_DB` into both asset cells. Full steps and the live values are in
> `assets/PROVISIONING-RUNBOOK.md` and the private facilitator record.

> **New to Fabric?** Each step is small and self-contained — just follow them in order.

---

### Task 1 — See the framework's brain: the control table

The framework is driven by a config table — no hard-coded pipelines. You'll read it from **your own**
Lab 1 notebook.

1. Go to **your** workspace and open your **Lab 1 medallion notebook** (`resident360_medallion`).
2. **Add a new cell** (anywhere after the first setup cell). Open `assets/metadatadb-read-cell.py`, copy its
   full contents, and paste them in.
3. Check the two values at the top — `SQL_SERVER` and `SQL_DB` — match the facilitator's `metadatadb`
   (they're usually pre-filled on the kit you were handed; if not, the facilitator will give you the two values).
4. **Run that cell.** You should see `✅ metadatadb reader ready`.
5. **Add another new cell** and run this read:

   ```python
   q("""
   SELECT source_schema_name, source_table_name, load_type, target_object, enable_flag
   FROM mtd.ingest_control
   ORDER BY source_schema_name, source_table_name
   """)
   ```

6. Notice the rows describe **your** medallion tables — `bronze.h365_*`, `silver.fact_*`, `gold.resident_360` —
   each with its **load type** (Full / Incr) and **target**. This config *is* the framework: add a row, and
   a new table is governed. No code change.

![Reading the mtd.ingest_control table from the notebook — five control rows mapping your bronze, silver and gold tables to gold.resident_360](../docs/images/lab2/lab2-02-read-control.png)

> **Done when you see:** five control rows naming your bronze / silver / gold tables.

---

### Task 2 — Connect your Lab 1 notebook to the audit store

Now make your transform **report** each run into the framework.

1. Go back to **your** workspace and open your **Lab 1 medallion notebook** (`resident360_medallion`).
2. **Add a new cell at the very end.**
3. Open `assets/audit-hook-cell.py`, copy its full contents, and paste them into that cell.
4. Confirm the `SQL_SERVER` and `SQL_DB` values at the top match the facilitator's `metadatadb`
   — these are the **same two values** you used for the reader cell in Task 1.
5. **Run just that cell.**

   ![The audit-hook cell at the end of the notebook, printing "✅ Audit rows written to metadatadb" after the Spark jobs succeed.](../docs/images/lab2/lab2-05-audit-hook.png)

> **Done when you see:** `✅ Audit rows written to metadatadb …`. (If you see a ⚠️ skip message, tell the
> facilitator — your Lab 1 results are unaffected either way.)

---

### Task 3 — Read the audit trail

1. Back in your notebook, **add a new cell** and run this read (uses the same `q()` helper from Task 1):

   ```python
   q("""
   SELECT item_name, load_type, rows_written, status,
          copy_duration AS seconds, event_end_time
   FROM mtd.ingest_audit
   ORDER BY event_end_time DESC
   """)
   ```

2. Each row is one **traceable** load event: which table, how many rows, success/failure, how long, and when.
3. Find the row for **`gold.resident_360`** — that's your unified view's load, now on the record.

![Reading the mtd.ingest_audit table from the notebook — your latest run tops the list with gold.resident_360 at 1500 rows and Success](../docs/images/lab2/lab2-03-read-audit.png)

> **Done when you see:** an audit row for `gold.resident_360` with your row count and `Success`.

---

### Task 4 — Open the observability dashboard

1. In the **`HPB Metadata Framework`** workspace, open the **Lakehouse Ingestion Dashboard**.
2. Read the tiles: **rows / data ingested by layer**, **success vs. failure**, **load duration**, **runs over time**.
3. Filter to **`gold.resident_360`** (or your run) — the dashboard now tells the operational story of the
   medallion **you** built: what moved, whether it was consistent, and how long it took.

![Lakehouse Ingestion Dashboard — datasets ingested, success rate, rows written, and a per-layer audit grid showing your bronze/silver/gold loads](../docs/images/lab2/lab2-01-dashboard.png)

> **Done when you see:** your `gold.resident_360` load reflected in the dashboard tiles.

---

### Task 5 — Trace it end-to-end

1. In the workspace, switch to **Lineage view** (top-right toggle, next to the search box).
2. Follow the chain: **dashboard → semantic model → `metadatadb`** and, in your own workspace,
   **`gold.resident_360` → silver → bronze → the mirrored Databricks tables**.
3. This is **traceability**: from a governance tile back to the raw source, and — via the audit table —
   *when* each hop last ran and whether it succeeded.

![Lineage view of the HPB Metadata Framework workspace — the Ingestion Dashboard report and semantic model, metadatadb, and the bronze/silver/gold layer lakehouses](../docs/images/lab2/lab2-04-lineage.png)

> **Done when you see:** the lineage graph linking the dashboard to `metadatadb`, and your medallion back to the mirror.

---

### ✅ Checkpoint

- [ ] Found your tables in `mtd.ingest_control`
- [ ] Added the audit-hook cell and got `✅ Audit rows written`
- [ ] Read your load in `mtd.ingest_audit`
- [ ] Saw your `gold.resident_360` load in the Ingestion Dashboard
- [ ] Traced lineage from the dashboard back to your medallion

---

### Next up

**[Lab 3 · Predict — machine learning on the medallion →](../lab3-datascience-ml/README.md)**
