CREATE INDEX idx_events_device_time
ON mobility.events (device_id, event_time DESC, event_id DESC);

CREATE INDEX idx_events_station_time
ON mobility.events (station_id, event_time);
