-- Create table for locations.
CREATE TABLE IF NOT EXISTS sdg.location (
    uuid UUID PRIMARY KEY DEFAULT uuid_generate_v1mc(),
    name TEXT NOT NULL UNIQUE
);

-- Create associative table between events and locations.
CREATE TABLE IF NOT EXISTS sdg.event_locations (
    event_id UUID REFERENCES sdg.event (uuid) ON UPDATE CASCADE ON DELETE CASCADE,
    location_id UUID REFERENCES sdg.location (uuid) ON UPDATE CASCADE ON DELETE CASCADE,
    PRIMARY KEY (event_id, location_id)
);

-- Copy existing tags into tag table.
INSERT INTO sdg.location (name)
    SELECT DISTINCT ON (location) unnest(locations) AS location
        FROM sdg.event;

CREATE OR REPLACE FUNCTION event_location_array_update() RETURNS trigger AS $$
BEGIN
    UPDATE sdg.event AS e SET locations = (
        SELECT array_remove(array_agg(l.name), NULL)
            FROM sdg.event_locations AS el
            LEFT JOIN sdg.location AS l ON el.location_id = l.uuid
            WHERE el.event_id = NEW.event_id)
        WHERE e.uuid = NEW.event_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER event_locations_update
    AFTER INSERT OR UPDATE ON sdg.event_locations
    FOR EACH ROW EXECUTE PROCEDURE event_location_array_update();

-- Create associations between events and locations.
INSERT INTO sdg.event_locations (event_id, location_id)
    SELECT e.uuid, l.uuid
        FROM (SELECT uuid, unnest(locations) AS location
            FROM sdg.event) AS e
        INNER JOIN sdg.location AS l ON e.location = l.name;