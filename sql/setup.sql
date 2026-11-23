BEGIN;

CREATE SCHEMA mobility;

CREATE TABLE mobility.stations (
    station_id integer PRIMARY KEY,
    station_name text NOT NULL UNIQUE
);

CREATE TABLE mobility.events (
    event_id bigint PRIMARY KEY,
    device_id integer NOT NULL,
    station_id integer NOT NULL REFERENCES mobility.stations,
    event_time timestamptz NOT NULL,
    event_type text NOT NULL,
    status text NOT NULL CHECK (status IN ('ok', 'error'))
);

INSERT INTO mobility.stations
SELECT n, 'Station ' || n
FROM generate_series(1, 32) AS g(n);

INSERT INTO mobility.events
SELECT n, 1 + ((n * 137) % 1009), 1 + ((n * 17) % 32),
       TIMESTAMPTZ '2026-01-01 00:00:00+00'
           + ((n * 7919::bigint) % 15552000) * INTERVAL '1 second',
       CASE WHEN n % 5 = 0 THEN 'arrival' ELSE 'departure' END,
       CASE WHEN n % 13 = 0 THEN 'error' ELSE 'ok' END
FROM generate_series(1, 250000) AS g(n);

ANALYZE mobility.events;
ANALYZE mobility.stations;

COMMIT;
