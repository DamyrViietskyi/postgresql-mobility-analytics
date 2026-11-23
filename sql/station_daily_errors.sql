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
