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
