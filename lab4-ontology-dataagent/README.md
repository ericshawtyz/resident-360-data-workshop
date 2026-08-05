[← Workshop home](../README.md)

# Lab 4 · Just Ask
## Ontology + data agent — semantic model vs. ontology

**⏱ 45 min**  ·  **🎯 Focus:** #1 Data lineage (capstone)

### The story
HPB programme designers want to ask plain-English questions across Rahim's unified view. You'll **generate an ontology
from your data** (a notebook does the modelling), wire a **data agent** to it, and compare it — on the **same tables** —
against a semantic-model agent to see where each approach fits.

### You'll build
- An **ontology** (`resident_ontology`) — its blueprint **generated from your `gold`/`silver` data** by a notebook.
  **Resident** binds to **three** tables (profile + diet log + Healthpoints ledger) and **Region** to **two**
  (region attributes + events hosted) — the ontology reads several tables as one entity.
- Two data agents over the **same tables**: one on the **`sm_resident360`** semantic model, one on the **ontology**.
- A side-by-side **comparison** on a multi-hop question, plus **end-to-end lineage**.

### Where this fits

```mermaid
flowchart LR
  subgraph LH["Lakehouse · lh_resident360 ✓ Lab 1"]
    GLD["gold.resident_360"]
    SLV["silver.fact_*"]
  end
  NB["Notebook · generate_ontology"]
  SM["Semantic model · sm_resident360 ✓ Lab 1<br/>(same tables)"]
  ONT["Ontology · resident_ontology"]
  AG1["Agent A · semantic-model source"]
  AG2["Agent B · ontology source"]
  GLD --> NB --> ONT
  SLV --> NB
  GLD --> SM
  SLV --> SM
  SM --> AG1
  ONT --> AG2
  classDef item fill:#cce5ff,stroke:#0066cc,stroke-width:2px,color:#003366;
  class ONT,AG1,AG2 item;
  classDef done fill:#eeeeee,stroke:#999999,color:#333333;
  class GLD,SLV,SM done;
```

**Builds on:** the medallion + `sm_resident360` from Lab 1. This is the governed, conversational capstone.

### Files
- `notebooks/generate_ontology.ipynb` — reads your data and prints the ontology **blueprint**.
- `assets/data_agent_questions.md` — the agent instructions + question bank.

> **New to Fabric?** Each step is small and self-contained — follow them in order.

---

### Task 1 — Generate the ontology blueprint from your data

1. Import **`generate_ontology.ipynb`** (workspace **Import → Notebook → From this computer**) and open it.
2. Attach the **`lh_resident360`** Lakehouse (Explorer → **Add data items → From OneLake catalog** → the Lakehouse).
3. Click **Run all**.
4. Read Section 1's output — the **entities** it found (Resident, Region, Event, Programme, Challenge) with their keys and instance counts. Note the **multi-binding** entities: **Resident** lists **three** binding rows — a static profile (Timestamp = None) **plus two timeseries** (`silver.fact_meal_log`@`log_date` and `silver.fact_rewards`@`txn_date`) — and **Region** lists **two** (a static profile **plus** `silver.fact_event_attendance`@`event_date`).
5. Read Section 2's output — the **relationships** it found (e.g. Resident —livesIn→ Region), with the exact key columns.
6. Scroll to Section 3 — the **blueprint** (two tables: entities and relationships). **Keep this on screen** for Task 2.

![Generated ontology blueprint — the entities table (Resident, Region, Event, Programme, Challenge with keys, Lakehouse bindings, Timestamp column; Resident shown with two timeseries binding rows and Region with one) and the relationships table (livesIn, attended, heldIn, enrolledIn, participatesIn) with origin → target keys](../docs/images/lab4/lab4-01-blueprint.png)

> **Done when you see:** a printed blueprint listing the entities and the relationships with their mapping tables and `origin → target` keys — with **Resident** showing **two** extra timeseries binding rows and **Region** showing **one** (a date column in the Timestamp position).

---

### Task 2 — Create the ontology and apply the blueprint

You're not designing anything — simply applying the spec the notebook generated.

1. Workspace → **+ New item** → search **Ontology** → click **Ontology (preview)** → name it **`resident_ontology`** → **Create**.
2. If a welcome dialog appears, check **Don't show again** and close it.
3. **Add the entities.** For each row in the blueprint's *entities* table:
   1. Ribbon → **Add entity type** → name it (e.g. **Resident**).
   2. **Configure entity type → Add properties from data → Add data binding → Lakehouse table** → select the blueprint's **binding** table.
   3. Set the **key** to the blueprint's key column.
   4. In **Timeseries data**, set **Timestamp = None**.
   5. **Save**.
   6. **Multi-binding entities (Resident, Region).** The blueprint lists extra **timeseries** bindings for these. After the first (static) binding saves, stay on that entity → **Manage property bindings → Add binding and properties → Add data binding → Lakehouse table** → select the next table → the key auto-maps → in **Timeseries data** select the **date column** as **Timestamp** → **Save**. Repeat for each extra binding:
      - **Resident** (3 bindings total): add `silver.fact_meal_log` (Timestamp `log_date`), then `silver.fact_rewards` (Timestamp `txn_date`).
      - **Region** (2 bindings total): add `silver.fact_event_attendance` (Timestamp `event_date`).

      The entity now reads a static profile **and** its timeseries as one entity.

   > ⚠️ **One non-timeseries binding only.** The first binding is non-timeseries (**Timestamp = None**). Every **additional** binding **must be timeseries** — the editor requires you to select a date column and disables **None** ("Only one non-timeseries binding is allowed per entity type"). A second static table (no date column) is rejected with *"The selected data source has no date/time columns."*
   > ⚠️ Bind **Lakehouse tables only** (the picker also offers Eventhouse).
   > ⚠️ **Duplicate columns:** if the second table repeats a column already bound (e.g. `resident_id`), the editor flags *"…already bound in another binding"* — click **Delete property binding** on that row in the second binding before Save.

4. **Add the relationships.** For each row in the blueprint's *relationships* table:
   1. Ribbon → **Add relationship** → set **name**, **origin**, **target** → **Create**.
   2. Click the new **edge** on the canvas → **Browse available sources** → select the blueprint's **mapping table**.
   3. Map the **origin key** and the **target key** exactly as the blueprint shows.
   4. **Verify both `Matched <Entity>` dropdowns** show the intended columns, then **Save**.

> **Done when you see:** the entity nodes joined by the named edges on the canvas (the editor auto-saves — no publish).

![resident_ontology graph — Resident at the hub joined to Region (livesIn), Event (attended), Programme (enrolledIn) and Challenge (participatesIn); Event also joins Region (heldIn)](../docs/images/lab4/lab4-02-ontology-graph.png)

> **Editor tips (preview) — quick reference.** Bind **Lakehouse tables only** (the picker also offers Eventhouse). On the **first (static)** binding, set **Timestamp = None** *last*, right before Save — selecting the entity key can reset the Timestamp field to empty. The three flows:
>
> - **Entity · first binding:** Configure entity type → Add properties from data → Add data binding → Lakehouse table → select table → Define entity type key → set **Timestamp = None** → **Save**.
> - **Entity · extra timeseries binding:** Manage property bindings → Add binding and properties → Add data binding → Lakehouse table → select the fact table → select the **date column** as Timestamp → delete any duplicated column → **Save**.
> - **Relationship:** select an entity → Add relationship → name / origin / target → Create → View Relationship Type details → Browse available sources → select the mapping table → map both keys → **Save**.

---

### Task 3 — Build the semantic-model agent

1. Workspace → **+ New item → Data agent** → name **`Resident360 SM Agent`** → **Create**.
2. Toolbar → **Add data → Data source** → select **`sm_resident360`** (the Lab 1 model, built on the same `gold`/`silver` tables the ontology uses) → **Add**.
3. In the Explorer, check all six tables: **`resident_360`**, **`fact_event_attendance`**, **`fact_meal_log`**, **`fact_rewards`**, **`fact_programme_enrolment`**, **`fact_challenge`**.
4. Toolbar → **Agent instructions** → paste the instructions from `assets/data_agent_questions.md`.
   *(The instructions box is a **Markdown preview** — click it once to switch to edit mode, then paste.)*

---

### Task 4 — Build the ontology agent

1. Workspace → **+ New item → Data agent** → name **`Resident360 Ontology Agent`** → **Create**.
2. Toolbar → **Add data → Data source** → select **`resident_ontology`** → **Add** (added whole — no tables to check).
3. Toolbar → **Agent instructions** → paste the same instructions from `assets/data_agent_questions.md`.

---

### Task 5 — Semantic model vs. ontology, on the same data

Both agents now read the **same six tables** — the SM agent through the `sm_resident360` star schema, the ontology agent through the `resident_ontology` graph. Ask each the **same multi-hop question** and compare *how* each answers.

1. Ask **both** agents:

   > *"Among residents who dropped a programme, how many attended at least one event, broken down by the region where those events were held? Return a chart by region."*

   This spans three domains — programme enrolment, event attendance, and the event's region.

2. Read the **SM agent's** answer. It plans a query over the star schema (joining the facts through `resident_360` on `resident_id`) and returns a chart.

   ![Semantic-model agent answers the multi-hop question from the star schema — a bar chart of residents by region](../docs/images/lab4/lab4-04-sm-answer.png)

3. Read the **Ontology agent's** answer. It **traverses named relationships** — Resident —enrolledIn→ Programme and Resident —attended→ Event —heldIn→ Region — and returns the **same numbers**.

   ![Ontology agent traverses enrolledIn / attended / heldIn and returns the same result](../docs/images/lab4/lab4-03-ontology-answer.png)

4. Try 2–3 more questions from the bank on both agents and **generate a visual** for each.

> **What this shows.** On a clean star schema with a capable data agent, **both approaches answer correctly** — the semantic model is not "beaten" on Q&A once it has the same tables. The ontology's value is **architectural**, not a different number:
> - **Named, typed relationships** — `livesIn` (a resident's home region) and `heldIn` (an event's region) are *distinct* edges, so multi-hop questions are unambiguous instead of relying on the agent to guess which `region` column to join.
> - **Graph-native traversal** — deep or variable-length paths across entities are first-class, not hand-built joins.
> - **A governed, reusable semantic layer** — one ontology can back many agents and apps.
>
> **Rule of thumb:** reach for the **semantic model** for classic BI metrics and dashboards; reach for the **ontology** when relationships, multi-hop traversal, and reuse across agents matter.

> **Note:** a multi-hop answer takes ~30–90 sec on either agent (plan → query → chart). Both report by group, never by individual `resident_id`.

> ⚠️ **Facilitator note — choose questions that resolve.** Two easy traps:
> - **Contradictory filters.** The `is_disengaged` flag means *low steps **AND no events attended** AND a dropped programme*, so "**disengaged** residents who **attended** events" is an empty set — an agent correctly answers *"no data."* Ask the traversal **without** the disengaged filter.
> - **Ambiguous "region".** `region` appears on several tables (a resident's home region vs. an event's region). Phrase the question so the intended hop is clear (e.g. *"the region where those events were held"*) — the ontology's named `heldIn`/`livesIn` edges make this explicit; the flat model relies on the agent picking the right column.

---

### Task 6 — End-to-end lineage

1. In the workspace, switch to **Lineage view**.
2. Trace one artifact back through the graph — from an agent/report to the semantic model, to `gold.resident_360`, to `silver`/`bronze`, to the mirrored Databricks tables. *(Read the actual graph on screen — it's your authoritative lineage.)*

   ![Lineage view of the workspace — Azure Databricks → hpb_databricks_mirror → semantic model → report and the Resident360 data agents, plus lh_resident360 → medallion notebook → experiment → ML model.](../docs/images/lab4/lab4-05-lineage.png)

3. Right-click a mirrored table → **Impact analysis** ("if this changes, what breaks?").
4. **Endorse** a semantic model: **⋯ (More options) → Settings → Endorsement and discovery → Promoted → Apply**.

---

### ✅ Checkpoint
- [ ] Ran the generator notebook → got the blueprint
- [ ] `resident_ontology` built from the blueprint (Resident with 3 bindings, Region with 2, + 5 relationships)
- [ ] Two agents built over the same tables (`sm_resident360` and the ontology)
- [ ] Asked both the same multi-hop question and compared how each answers
- [ ] Lineage traced; a model endorsed

---

### Next up
**Wrap-up & next steps**
