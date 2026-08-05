# Lab 4 · Data agent — instructions & question bank

## Agent instructions (paste into the data agent → Setup → Agent instructions)
```
You are the HPB Resident 360 assistant. Use HPB terminology:
- "MVPA" = moderate-to-vigorous physical activity minutes.
- "Healthpoints" = the Healthy 365 rewards currency; eVouchers are redeemed with them.
- A resident is "disengaged" when is_disengaged = 1 (low steps AND no events attended AND a dropped programme).
- "hazy" / poor-air region = region_is_hazy = 1 (regional 24-hour PSI >= 55).
Prefer the ontology for resident-level and relationship questions; use the semantic models for aggregated metrics.
When comparing groups, return a chart. Never expose individual resident_ids — report by region, age band,
programme, event or challenge.
```

## Question bank

### Multi-hop relationship questions (Resident · Programme · Event · Region)
These span several domains. **Both** agents attempt them once the semantic model has the same tables — the point
is to compare *how* each does it (star joins vs. named-relationship traversal). The **semantic-model agent** returns
the correct per-group figures; the **ontology agent** (preview) illustrates the traversal but may not reproduce those
figures exactly, so validate its numbers against the semantic model.
1. **Among residents who dropped a programme, how many attended at least one event, broken down by the region where those events were held? Return a chart by region.**  *(the headline comparison — spans enrolledIn + attended + heldIn)*
2. How many residents attended events in each region? Return a chart by region.
3. On average, how many events does a resident attend, broken down by their home region?

> ⚠️ **"region" is ambiguous** — it appears as a resident's *home* region (`livesIn`) and an event's *held-in* region
> (`heldIn`). Phrase the question so the intended hop is explicit. The ontology's named edges disambiguate; the flat
> model relies on the agent picking the right `region` column.

### Engagement & risk
4. Which regions have the highest share of disengaged residents?
5. How many residents are disengaged by age band?
6. Compare average daily steps for residents who attended ≥1 event vs those who attended none.

### Diet, rewards & screening
7. What is the % Healthier Choice for residents at High screening risk vs Low?
8. Average calories logged per meal type.
9. Healthpoints earned by programme, and eVoucher value redeemed by region.

### Programmes & challenges
10. Which programmes do disengaged residents in the East most often drop?
11. Which regions have the most residents enrolled in "Eat Drink Shop Healthy" but with low challenge progress?
12. Which challenges have the highest completion, and in which regions?

## Compare the two agents (the point of Task 5)
Ask **Q1** to **both** the **`Resident360 SM Agent`** (on `sm_resident360`) and the **`Resident360 Ontology Agent`**
(on `resident_ontology`). Both read the same six tables, so the comparison is about *how* each answers — not a promise
of identical numbers. The **SM agent** returns the correct per-region breakdown (use it as the source of truth); the
**ontology agent** (preview) demonstrates named-relationship traversal but may return different or incorrect figures on
this multi-hop aggregate. The difference is *architectural*: the SM agent joins the star on `resident_id`; the ontology
agent traverses named relationships (`enrolledIn`, `attended`, `heldIn`). Discuss when each fits:
- **Semantic model** — classic BI metrics, dashboards, well-understood star schemas.
- **Ontology** — named/typed relationships, deep or variable-length multi-hop traversal, and a governed layer reused
  across many agents and apps.

## Demo flow
1. Q4 → bar chart of disengaged share by region.
2. Q1 → ask both agents; show the SM agent's correct chart as the source of truth, then contrast star joins vs. graph traversal (don't promise identical numbers — the ontology preview agent may differ).
3. Q12 → matrix (challenge × region). Pin the visuals.
