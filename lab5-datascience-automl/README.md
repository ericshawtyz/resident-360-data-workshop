[← Workshop home](../README.md)

# Lab 5 · Nudges That Land
## Train, compare & serve a model in real time

**⏱ 45 min**  ·  **🎯 Focus:** ML pipeline · experiments · real-time endpoint

### The story
To nudge Rahim *before* he disengages, HPB needs a model that spots early warning signs. We train three model
families, tune them, track every run, then serve the best one on a **real-time endpoint** so the app can score a
resident live.

### You'll build
- An **ML pipeline** training **Logistic Regression, LightGBM, XGBoost** with **hyperparameter tuning**.
- An **MLflow experiment** comparing every run's ROC-AUC / accuracy / F1.
- The winning model **registered** as a native flavor and served on a **real-time REST endpoint**.

### Where this fits

```mermaid
flowchart LR
  subgraph LH["Lakehouse · lh_resident360"]
    GLD["Gold · resident_360 ✓ Lab 3"]
  end
  EXP["Experiment · resident360-disengagement<br/>LogReg · LightGBM · XGBoost + tuning"]
  subgraph MODEL["ML model · resident360_disengagement"]
    V1["version 1 · native flavor"]
    EP["real-time endpoint"]
  end
  PRED["Prediction · is_disengaged"]
  GLD -->|nb08 train + track| EXP
  EXP -->|register best| MODEL
  MODEL -->|nb09 score| PRED
  style LH fill:#f7fbff,stroke:#0066cc,color:#003366
  style MODEL fill:#cce5ff,stroke:#0066cc,color:#003366
  classDef item fill:#cce5ff,stroke:#0066cc,stroke-width:2px,color:#003366;
  classDef inner fill:#ffffff,stroke:#0066cc,color:#003366;
  classDef done fill:#eeeeee,stroke:#999999,color:#333333;
  class EXP,PRED item;
  class V1,EP inner;
  class GLD done;
```

**Builds on:** Lab 3's Gold (label `is_disengaged`). Turns the data into a live prediction service.

### Files
- `notebooks/08_train_disengagement_models.ipynb` — train + tune + track + register
- `notebooks/09_call_model_endpoint.ipynb` — score from the registry and via the live endpoint

> Import both notebooks and attach **`lh_resident360`**. Target = `is_disengaged` from `gold.resident_360`.
> The three columns that *define* the label are excluded from the features, so the models learn genuine risk
> signals (MVPA, sleep, diet, healthpoints, challenges, screening) rather than memorising the rule.

---

### Task 1 — Train & compare models
1. Open **`08_train_disengagement_models`**, attach the Lakehouse, **Run all**.
2. It trains and tunes three families, logging **one MLflow run per configuration** with params + metrics.
3. Read the printed leaderboard — each run shows AUC / accuracy / F1, and the **winner** (highest AUC) is chosen.

> **Done when you see:** a printed leaderboard with a selected winner (typically XGBoost, AUC ≈ 0.99) and the
> model **`resident360_disengagement`** registered in the workspace.

> **Note:** The first cell installs LightGBM/XGBoost if the session lacks them (~1 min) and the kernel restarts once —
> that's expected; the run continues automatically.

### Task 2 — Compare runs in the experiment
1. Workspace → open **Experiments → `resident360-disengagement`**.
2. Select the runs → **Compare** → sort by **auc**. See how the model families and hyperparameters stack up.

> **Fun fact:** MLflow is the same open-source tracking you may use in Databricks — it works natively in Fabric,
> no setup required.

### Task 3 — Register & activate the endpoint
1. Notebook `08` already **registers the winner** as `resident360_disengagement` with a scalar signature (native
   flavor = servable).
2. Open the model **`resident360_disengagement`** (from the workspace list) → select **Version 1** → in the ribbon
   select **Activate version endpoint**. Wait for **Status = Active** (endpoint provisioning takes several
   minutes on first activation — use **Refresh** to check).
3. **Set the default version** so the friendly scoring URL resolves: **Manage endpoints → Default version →
   Version 1**. The selection applies immediately (no Save button). Without this, the default endpoint URL
   returns HTTP 404 (`EndpointOrResourceNotFound`).
4. Open **Manage endpoints** → copy the **Model endpoint URL** (ends with `/score`) for Task 4B.

> **Note:** Registry scoring (Task 4A) works even before the endpoint is activated.
>
> **Can't see the `Activate version endpoint` button?** It lives in the **Home** ribbon of the version
> details page, but the ribbon **collapses it when the browser window is narrow** — maximise the window
> (or zoom out) and it reappears as a split button. Select it → **Activate version endpoint**. The
> **Status** field can lag; click **Refresh** to see it move `Deactivated → Activating → Active`.

### Task 4 — Score Rahim
1. Open **`09_call_model_endpoint`**, attach the Lakehouse.
2. **Option A — registry:** run the first cell to load the model and score five residents in-notebook.
3. **Option B — endpoint:** paste the `/score` URL from Task 3 into `ENDPOINT_URL`, run the cell → a live
   `{"predictions":[[1]]}` (1 = at disengagement risk).

> **No-code alternative:** on the model's version page, ribbon **Preview predictions** → **Autofill** (or
> type feature values) → **Get predictions** calls the live endpoint and shows the result right in the UI —
> handy to confirm the endpoint works without touching the notebook.

> **Note:** The first endpoint call may fail with a `ReadTimeout` while the endpoint warms up (cold start).
> Just run the cell again — the warmed endpoint responds in a few seconds.
>
> **Alternative:** If you skip setting a default version (Task 3 step 3), call a specific version instead by
> using the version scoring URL: `…/mlmodels/<id>/endpoint/versions/1/score`.

---

### ✅ Checkpoint
- [ ] Three model families trained + tuned; runs visible in the experiment
- [ ] Winner registered as a native flavor
- [ ] Real-time endpoint returns a live prediction

### 🟡 Challenge (optional) — log a feature-importance plot
1. After training, read `best['model'].feature_importances_` (or the LR coefficients) into a DataFrame keyed by `FEATURES`.
2. Plot a horizontal bar chart of the top 10 features with matplotlib.
3. Log it to the run: `mlflow.log_figure(fig, "feature_importance.png")`.
4. Open the run in the **`resident360-disengagement`** experiment and confirm the artifact.

**Other ideas:** add a fourth model or a wider hyperparameter grid; or score a hold-out set and record precision/recall at your chosen threshold.

---

### Next up
**[Lab 6 · Just Ask](../lab6-ontology-dataagent/README.md)**

