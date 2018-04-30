-- Create function to check whether resources should be published.
CREATE OR REPLACE FUNCTION publish_resource_check() RETURNS trigger AS $$
BEGIN
    IF NEW.status_id = (
        SELECT id
            FROM sdg.submission_status
            WHERE status = 'Accepted')
    THEN
        UPDATE sdg.resource AS r SET publish = TRUE
        WHERE r.uuid = NEW.resource_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger resource publication check on submission update.
CREATE TRIGGER submission_update
    AFTER UPDATE ON sdg.submission
    FOR EACH ROW EXECUTE PROCEDURE publish_resource_check();