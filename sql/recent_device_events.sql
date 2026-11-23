SELECT *
FROM mobility.events
WHERE device_id = 42
ORDER BY event_time DESC, event_id DESC
LIMIT 20;
