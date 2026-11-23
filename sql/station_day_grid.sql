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
