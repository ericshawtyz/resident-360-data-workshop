# Lab 6 · Three semantic models (plan)

All three are **Direct Lake** over `lh_resident360`. Relate every fact to the resident on **`resident_id`**.

> **Build from the SQL analytics endpoint.** On a schema-enabled lakehouse the Home-ribbon *New semantic model*
> dialog lists no tables — open `lh_resident360`, switch to the **SQL analytics endpoint**, then **New semantic
> model** (it shows the `bronze` / `silver` / `gold` schema folders).

## 1. `sm_activity` — Activity & Fitness *(reuse from Lab 1)*
| Table | Source | Key columns |
|-------|--------|-------------|
| `dim_resident` | Databricks mirror | resident_id, age_band, gender, region, planning_area |
| `daily_activity` | Databricks mirror | resident_id, activity_date, steps, mvpa_minutes, sleep_minutes, goal_met |
**Measures:** `Avg Steps` · `% Goal Met`

## 2. `sm_diet` — Nutrition & Diet
| Table | Source | Key columns |
|-------|--------|-------------|
| `fact_meal_log` | silver | resident_id, log_date, meal_type, calories, healthier_choice_flag |
| `resident_360` | gold | resident_id, meal_logs, avg_calories, pct_healthier_choice, region, region_is_hazy |
**Measures:** `Avg Calories` · `% Healthier Choice`  ·  *(carries `region_is_hazy` for air-quality questions)*

## 3. `sm_engagement` — Engagement, Programmes & Rewards
| Table | Source | Key columns |
|-------|--------|-------------|
| `fact_event_attendance` | silver | resident_id, event_id, event_type, attended_flag, region |
| `fact_programme_enrolment` | silver | resident_id, programme_name, status, channel |
| `fact_rewards` | silver | resident_id, points_earned, points_redeemed, source |
| `fact_challenge` | silver | resident_id, challenge_name, current_tier, progress_pct |
| `fact_evoucher_redemption` | silver | resident_id, merchant, voucher_value_sgd, healthpoints_spent |
**Measures:** `Events Attended` · `Programmes Dropped` · `Healthpoints Earned` · `Avg Challenge Progress`

> The ontology's `Resident` entity unifies these domains at the entity level; the semantic models give the agent
> pre-aggregated measures. Together they let the agent answer both metric and relationship questions.
