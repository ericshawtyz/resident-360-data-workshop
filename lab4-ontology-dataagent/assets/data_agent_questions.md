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

### Guided path (Resident · Event · Region) — the headline multi-hop
These traverse **Resident → attended → Event → heldIn → Region**, so the flat Lab 1 agent (activity only) can't
answer them.
1. **How many residents attended events in each region? Return a chart by region.**  *(the headline win — resolves reliably on the graph)*
2. Do residents attend more events in some regions than others? Show the top and bottom regions.
3. On average, how many events does a resident attend, broken down by region?

> ⚠️ Filtering on **`region_is_hazy`** (e.g. *"…events in hazy-air regions…"*) needs the **Region** entity bound to a
> table that carries the haze flag. In the base ontology Region is bound to `resident_360` + `fact_event_attendance`,
> which don't expose it, so a haze-filtered question may error with *"couldn't retrieve the data."* Add that binding
> first if you want the haze cut.

### Full graph (challenge — after you add Programme & Challenge)
Needs the 5-entity ontology from the challenge.
4. Which programmes do disengaged residents in the East most often drop, and are they in challenges?
5. Which regions have the most residents enrolled in "Eat Drink Shop Healthy" but with low challenge progress?

### Engagement & risk
6. Which regions have the highest share of disengaged residents?
7. How many residents are disengaged by age band?
8. Compare average daily steps for residents who attended ≥1 event vs those who attended none.

### Diet & screening
9. What is the % Healthier Choice for residents at High screening risk vs Low?
10. Average calories logged per meal type.

### Rewards & challenges *(full graph)*
11. Healthpoints earned by programme, and eVoucher value redeemed by region.
12. Which challenges have the highest completion, and in which regions?

## Compare vs the Lab 1 agent
Ask **Q1** to both the **Lab 1 agent** (`Resident360 Agent`, activity-only) and the **ontology agent**. The Lab 1
agent has no event or region data, so it can't join those domains; the ontology agent traverses
Resident → Event → Region and answers directly, grouped by region. This is the headline "why an ontology" moment.
After the challenge (5-entity graph), Q4 shows the same win across programmes and challenges.

## Demo flow
1. Q6 → bar chart of disengaged share by region.
2. Q1 → the multi-hop win (ontology vs Lab 1 agent).
3. *(after the challenge)* Q4 or Q12 → matrix (programme/challenge × region). Pin the three visuals.
