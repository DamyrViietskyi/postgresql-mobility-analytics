# Mobility Event Analytics

**SQL · PostgreSQL · Window Functions · EXPLAIN**

How do device and station activity change over time, and which reports benefit from composite indexes?

## Reports

| Script | Output |
| --- | --- |
| `recent_device_events.sql` | Latest 20 events for a device, with a deterministic tie-breaker. |
| `station_daily_errors.sql` | Daily volume and errors for one station in a UTC date range. |
| `station_day_grid.sql` | A complete March station-day grid with zero counts on inactive days. |
| `station_rank_and_running_total.sql` | Daily activity rank and cumulative events per station. |

## Run locally

```sh
createdb mobility_demo
psql -X -v ON_ERROR_STOP=1 -d mobility_demo -f sql/setup.sql
psql -X -v ON_ERROR_STOP=1 -d mobility_demo -f sql/station_rank_and_running_total.sql
psql -X -v ON_ERROR_STOP=1 -d mobility_demo -f sql/benchmark.sql
```

The setup generates 250,000 synthetic events and 32 stations. The benchmark runs the same four queries before and after creating indexes on `(device_id, event_time DESC, event_id DESC)` and `(station_id, event_time)`. It prints execution plans, buffer usage and index sizes, then rolls back the index changes. Compare scan types and buffers across runs. Timing depends on caching and hardware.

Adapted from database coursework at Kyiv School of Economics.
