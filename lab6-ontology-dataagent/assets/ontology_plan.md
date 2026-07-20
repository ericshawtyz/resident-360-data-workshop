# Lab 6 · Ontology plan (Fabric IQ)

> **Bind LAKEHOUSE tables only** (`lh_resident360` → `gold` / `silver`). The picker offers *Lakehouse table* /
> *Eventhouse table*. The mirrored `dim_resident` / `health_screening` are a Mirrored catalog (not a Lakehouse),
> so resident demographics, screening and **regional air quality** all come from **`gold.resident_360`**, which
> already carries them.

---

## Guided path — 3 entities + 3 relationships (do this in the lab)

A tight **Resident · Region · Event** triangle. `gold.resident_360` carries `region_psi` / `region_is_hazy`
(added in Lab 3), so **Region** — and any event linked to it — knows whether its air is hazy. That powers the
headline multi-hop question the flat Lab 1 agent can't answer.

### Entity types

| Entity | Key column | Binding (Lakehouse table) | Timestamp |
|--------|-----------|---------------------------|-----------|
| **Resident** | `resident_id` | `gold.resident_360` | **None** |
| **Region** | `region` | `gold.resident_360` | **None** |
| **Event** | `event_id` | `silver.fact_event_attendance` | **None** |

> **Set Timestamp = None on all three.** Each binding table carries a date/time column (`gold.resident_360` has
> `join_date`; `fact_event_attendance` has an event date) that the editor auto-detects, surfacing a **required**
> Timestamp field. Leave it and the binding won't save — pick **None** for each entity.

- **Resident** provides demographics, all domain aggregates, screening fields (`latest_bmi`, `latest_systolic`,
  `screening_risk`), the `is_disengaged` label and the `region_is_hazy` context.
- **Region** provides `planning_area`, `region_psi`, `region_is_hazy`.
- **Event** provides `event_name`, `event_type`, `region`, `event_date`.

### Relationships
Each relationship needs a **mapping table that contains both keys**. Create the relationship, then open its edge
and map the columns.

| Relationship | Mapping table | Origin key → Target key |
|---|---|---|
| `Resident —livesIn→ Region` | `gold.resident_360` | `resident_id` → `region` |
| `Resident —attended→ Event` | `silver.fact_event_attendance` | `resident_id` → `event_id` |
| `Event —heldIn→ Region` | `silver.fact_event_attendance` | `event_id` → `region` |

---

## Challenge — extend to 5 entities + 5 relationships (optional)

Add programmes and challenges so the agent can also answer *"which programmes do disengaged residents drop, and
are they in challenges?"*.

### Extra entity types (single fact binding each, **Timestamp = None**)

| Entity | Key column | Binding (Lakehouse table) |
|--------|-----------|---------------------------|
| **Programme** | `programme_name` | `silver.fact_programme_enrolment` |
| **Challenge** | `challenge_name` | `silver.fact_challenge` |

### Extra relationships

| Relationship | Mapping table | Origin key → Target key |
|---|---|---|
| `Resident —enrolledIn→ Programme` | `silver.fact_programme_enrolment` | `resident_id` → `programme_name` |
| `Resident —participatesIn→ Challenge` | `silver.fact_challenge` | `resident_id` → `challenge_name` |

### Optional — make Resident multi-timeseries
Add two **timeseries** bindings to **Resident** (its `resident_360` static binding defines the key first):

| Binding | Lakehouse table | Kind | Timestamp |
|---------|-----------------|------|-----------|
| 2 | `silver.fact_meal_log` | timeseries | `log_date` |
| 3 | `silver.fact_rewards` | timeseries | `txn_date` |

---

## Binding notes
- Bind the **static table first** (it defines the key), then any timeseries facts.
- A fact table used as the **only** binding must define instances (non-timeseries) → set **Timestamp column =
  None**, or you get *"Non-timeseries binding required."*
- For entities you build via **Add properties from data**, the key is set **after** the binding: **Define entity
  type key → pick column → Esc → Save**.
- **Property-name collisions across bindings are rejected** — delete the duplicate property in the second binding
  (the first already provides it).
- On a **schema-enabled lakehouse**, the table picker shows a **Tables** node → expand it to reveal the
  `bronze` / `silver` / `gold` schema folders.
- The preview editor **auto-saves** — no separate publish step. If the *"Welcome to Ontology"* dialog keeps
  reappearing, tick **Don't show again**.

## Worked example — bind `Resident`
1. Select the **`Resident`** node → **Configure entity type → Add properties from data**.
2. Select **Add data binding → Lakehouse table** → `lh_resident360` → expand **Tables → gold → `resident_360`** →
   **Select** → **Define entity type key → `resident_id` → Esc → Save** → *"Entity type updated successfully."*
3. Repeat for **Region** (bind `gold.resident_360`, key **`region`**, **Timestamp = None**) and **Event** (bind
   `silver.fact_event_attendance`, key **`event_id`**, **Timestamp = None**).

## Worked example — a relationship (`livesIn`)
1. On the ribbon, select **Add relationship** → name `livesIn`, origin **Resident**, target **Region** → **Create**.
2. Click the **`livesIn`** edge → **Browse available sources → `resident_360`**.
3. Map **Resident** key column = `resident_id`, **Region** key column = `region` → **Save**
   (*"Successfully updated the relationship type"*).
   - After picking the mapping table, one column auto-binds and the other shows **Select a column**. Set it, then
     **double-check BOTH `Matched <Entity>` dropdowns** point at the right source column before Save — picking a
     column can otherwise overwrite the auto-bound one.
4. Repeat for `attended` (`resident_id` → `event_id`) and `heldIn` (`event_id` → `region`) using the mapping tables
   in the guided table above, verifying both matched columns each time.
