DROP TRIGGER IF EXISTS event_locations_update ON sdg.event_locations;
DROP FUNCTION IF EXISTS event_location_array_update();

-- Drop views and tables.
DROP TABLE IF EXISTS sdg.event_locations;
DROP TABLE IF EXISTS sdg.locations;