\pset pager off
SET TIME ZONE 'UTC';

BEGIN;
DROP INDEX IF EXISTS mobility.idx_events_device_time, mobility.idx_events_station_time;

\echo Baseline: latest device events
EXPLAIN (ANALYZE, BUFFERS)
SELECT *
FROM mobility.events
WHERE device_id = 42
ORDER BY event_time DESC, event_id DESC
LIMIT 20;

\echo Baseline: daily station errors
EXPLAIN (ANALYZE, BUFFERS)
SELECT
    (event_time AT TIME ZONE 'UTC')::date AS activity_date,
    COUNT(*) AS total_events,
    COUNT(*) FILTER (WHERE status = 'error') AS error_events
FROM mobility.events
WHERE station_id = 7
    AND event_time >= '2026-03-01 00:00:00+00'
    AND event_time < '2026-03-08 00:00:00+00'
GROUP BY activity_date
ORDER BY activity_date ASC;

\echo Baseline: complete station-day grid
EXPLAIN (ANALYZE, BUFFERS)
SELECT s.station_id, s.station_name, d.activity_date,
    COUNT(e.event_id) AS total_events,
    COALESCE(SUM(CASE WHEN e.status = 'error' THEN 1 ELSE 0 END), 0) AS error_events
FROM mobility.stations AS s
CROSS JOIN (
    SELECT generate_series('2026-03-01'::date, '2026-03-31'::date, INTERVAL '1 day')::date AS activity_date
) AS d
LEFT JOIN mobility.events AS e
    ON e.station_id = s.station_id
    AND e.event_time >= d.activity_date::timestamp AT TIME ZONE 'UTC'
    AND e.event_time < (d.activity_date + 1)::timestamp AT TIME ZONE 'UTC'
GROUP BY s.station_id, s.station_name, d.activity_date
ORDER BY d.activity_date ASC, s.station_id ASC;

\echo Baseline: station rank and running total
EXPLAIN (ANALYZE, BUFFERS)
WITH daily_activity AS (
    SELECT
        s.station_id,
        s.station_name,
        d.activity_date,
        COALESCE(COUNT(e.event_id), 0) AS total_events,
        COALESCE(
            SUM(CASE WHEN e.status = 'error' THEN 1 ELSE 0 END),
            0
        ) AS error_events

    FROM mobility.stations AS s

    CROSS JOIN (
        SELECT generate_series(
            '2026-01-01'::date,
            '2026-06-29'::date,
            INTERVAL '1 day'
        )::date AS activity_date
    ) AS d

    LEFT JOIN mobility.events AS e
        ON e.station_id = s.station_id
        AND e.event_time >= d.activity_date::timestamp AT TIME ZONE 'UTC'
        AND e.event_time < (d.activity_date + 1)::timestamp AT TIME ZONE 'UTC'

    GROUP BY
        s.station_id,
        s.station_name,
        d.activity_date
)

SELECT
    station_id,
    station_name,
    activity_date,
    total_events,
    error_events,

    DENSE_RANK() OVER (
        PARTITION BY activity_date
        ORDER BY total_events DESC
    ) AS daily_rank,

    SUM(total_events) OVER (
        PARTITION BY station_id
        ORDER BY activity_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_events

FROM daily_activity

ORDER BY
    activity_date ASC,
    station_id ASC;

\ir indexes.sql

\echo Indexed: latest device events
EXPLAIN (ANALYZE, BUFFERS)
SELECT *
FROM mobility.events
WHERE device_id = 42
ORDER BY event_time DESC, event_id DESC
LIMIT 20;

\echo Indexed: daily station errors
EXPLAIN (ANALYZE, BUFFERS)
SELECT
    (event_time AT TIME ZONE 'UTC')::date AS activity_date,
    COUNT(*) AS total_events,
    COUNT(*) FILTER (WHERE status = 'error') AS error_events
FROM mobility.events
WHERE station_id = 7
    AND event_time >= '2026-03-01 00:00:00+00'
    AND event_time < '2026-03-08 00:00:00+00'
GROUP BY activity_date
ORDER BY activity_date ASC;

\echo Indexed: complete station-day grid
EXPLAIN (ANALYZE, BUFFERS)
SELECT s.station_id, s.station_name, d.activity_date,
    COUNT(e.event_id) AS total_events,
    COALESCE(SUM(CASE WHEN e.status = 'error' THEN 1 ELSE 0 END), 0) AS error_events
FROM mobility.stations AS s
CROSS JOIN (
    SELECT generate_series('2026-03-01'::date, '2026-03-31'::date, INTERVAL '1 day')::date AS activity_date
) AS d
LEFT JOIN mobility.events AS e
    ON e.station_id = s.station_id
    AND e.event_time >= d.activity_date::timestamp AT TIME ZONE 'UTC'
    AND e.event_time < (d.activity_date + 1)::timestamp AT TIME ZONE 'UTC'
GROUP BY s.station_id, s.station_name, d.activity_date
ORDER BY d.activity_date ASC, s.station_id ASC;

\echo Indexed: station rank and running total
EXPLAIN (ANALYZE, BUFFERS)
WITH daily_activity AS (
    SELECT
        s.station_id,
        s.station_name,
        d.activity_date,
        COALESCE(COUNT(e.event_id), 0) AS total_events,
        COALESCE(
            SUM(CASE WHEN e.status = 'error' THEN 1 ELSE 0 END),
            0
        ) AS error_events

    FROM mobility.stations AS s

    CROSS JOIN (
        SELECT generate_series(
            '2026-01-01'::date,
            '2026-06-29'::date,
            INTERVAL '1 day'
        )::date AS activity_date
    ) AS d

    LEFT JOIN mobility.events AS e
        ON e.station_id = s.station_id
        AND e.event_time >= d.activity_date::timestamp AT TIME ZONE 'UTC'
        AND e.event_time < (d.activity_date + 1)::timestamp AT TIME ZONE 'UTC'

    GROUP BY
        s.station_id,
        s.station_name,
        d.activity_date
)

SELECT
    station_id,
    station_name,
    activity_date,
    total_events,
    error_events,

    DENSE_RANK() OVER (
        PARTITION BY activity_date
        ORDER BY total_events DESC
    ) AS daily_rank,

    SUM(total_events) OVER (
        PARTITION BY station_id
        ORDER BY activity_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_events

FROM daily_activity

ORDER BY
    activity_date ASC,
    station_id ASC;

SELECT indexname, pg_size_pretty(pg_relation_size(format('%I.%I', schemaname, indexname)::regclass)) AS index_size
FROM pg_indexes
WHERE schemaname = 'mobility' AND tablename = 'events'
ORDER BY indexname;

ROLLBACK;
