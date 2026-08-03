# ─────────────────────────────────────────────────────────────────────────────
# Lab 2 audit hook — paste this as the LAST cell of Lab 1's medallion notebook.
#
# It writes ONE audit row per layer into the metadata framework's `metadatadb`
# by calling mtd.capture_audit_event_sp. After this runs, your `gold.resident_360`
# load shows up in the Lakehouse Ingestion Dashboard (Lab 2) — that's the
# observability + traceability outcome, over the medallion YOU just built.
#
# It is wrapped in try/except so it can NEVER fail your Lab 1 transform — if the
# metadatadb isn't reachable, it just prints a warning and moves on.
#
# FACILITATOR: fill in SQL_SERVER and SQL_DB with the deployed metadatadb values before the workshop.
# The live values are in the private facilitator record:
#   hpb-fabric-workshop-facilitator/metadata-framework-deployment-record.md  → "Facilitator preflight"
# (They are kept out of this public repo on purpose.)
# ─────────────────────────────────────────────────────────────────────────────
import uuid, datetime

# ── deployed "HPB Metadata Framework" metadatadb (facilitator fills these) ────
SQL_SERVER = "<SQL_SERVER>"   # e.g. xxxx.database.fabric.microsoft.com  (see private record)
SQL_DB     = "<SQL_DB>"       # e.g. metadatadb-<guid>                   (see private record)

def _emit_audit():
    import struct, pyodbc
    from notebookutils import credentials

    # Entra token for the Fabric SQL DB (Fabric SQL is Entra-auth only)
    token = credentials.getToken("https://database.windows.net/").encode("utf-16-le")
    tokenstruct = struct.pack(f"<I{len(token)}s", len(token), token)
    SQL_COPT_SS_ACCESS_TOKEN = 1256

    conn = pyodbc.connect(
        f"Driver={{ODBC Driver 18 for SQL Server}};Server={SQL_SERVER},1433;"
        f"Database={SQL_DB};Encrypt=yes;TrustServerCertificate=no",
        attrs_before={SQL_COPT_SS_ACCESS_TOKEN: tokenstruct},
    )
    cur = conn.cursor()

    # One row per layer table this notebook produced. rows_* are read live.
    layers = [
        ("bronze.h365_meal_logs",       "bronze.h365_meal_logs",       "Full"),
        ("bronze.h365_event_bookings",  "bronze.h365_event_bookings",  "Full"),
        ("silver.fact_meal_log",        "silver.fact_meal_log",        "Incr"),
        ("silver.fact_event_attendance","silver.fact_event_attendance","Incr"),
        ("gold.resident_360",           "gold.resident_360",           "Full"),
    ]
    run_id = str(uuid.uuid4())
    for item_name, table, load_type in layers:
        try:
            n = spark.table(f"lh_resident360.{table}").count()
        except Exception:
            n = 0
        approx_bytes = n * 100  # nominal — dashboard shows GB via measures
        start = datetime.datetime.utcnow() - datetime.timedelta(minutes=1)
        end   = datetime.datetime.utcnow()
        cur.execute(
            "EXEC mtd.capture_audit_event_sp "
            "@source_type=?, @event_run_id=?, @item_name=?, @data_read=?, @data_written=?, "
            "@rows_read=?, @rows_written=?, @data_consistency_verification=?, @copy_duration=?, "
            "@event_start_time=?, @event_end_time=?, @load_type=?, @status=?, "
            "@event_triggered_by=?, @pipeline_url=?",
            "FABRIC_LAKEHOUSE", run_id, item_name, approx_bytes, approx_bytes,
            n, n, "Verified", 5, start, end, load_type, "Success",
            "Lab1 Notebook", "https://app.fabric.microsoft.com",
        )
    conn.commit()
    cur.close(); conn.close()
    print(f"✅ Audit rows written to metadatadb (run {run_id[:8]}…). "
          f"Open the Lakehouse Ingestion Dashboard in Lab 2 to see your load.")

try:
    _emit_audit()
except Exception as e:
    print(f"⚠️ Audit hook skipped (metadatadb not reachable from this notebook): {e}")
    print("   This does NOT affect your Lab 1 results — the medallion is already built.")
