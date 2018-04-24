-- Create tag table.
CREATE TABLE IF NOT EXISTS sdg.tag (
    uuid UUID PRIMARY KEY DEFAULT uuid_generate_v1mc(),
    name TEXT NOT NULL UNIQUE
);

-- Create associative table between resources and tags.
CREATE TABLE IF NOT EXISTS sdg.resource_tags (
    resource_id UUID REFERENCES sdg.resource (uuid) ON UPDATE CASCADE ON DELETE CASCADE,
    tag_id UUID REFERENCES sdg.tag (uuid) ON UPDATE CASCADE ON DELETE CASCADE,
    PRIMARY KEY (resource_id, tag_id)
);

-- Copy existing tags into tag table.
INSERT INTO sdg.tag (name)
    SELECT DISTINCT ON (tag) unnest(tags) AS tag
        FROM sdg.resource;

CREATE OR REPLACE FUNCTION resource_tag_array_update() RETURNS trigger AS $$
BEGIN
    UPDATE sdg.resource AS r SET tags = (
        SELECT array_remove(array_agg(t.name), NULL)
            FROM sdg.resource_tags AS rt
            LEFT JOIN sdg.tag AS t ON rt.tag_id = t.uuid
            WHERE rt.resource_id = NEW.resource_id)
        WHERE r.uuid = NEW.resource_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER resource_tags_update
    AFTER INSERT OR UPDATE ON sdg.resource_tags
    FOR EACH ROW EXECUTE PROCEDURE resource_tag_array_update();

-- Create associations between resources and tags.
INSERT INTO sdg.resource_tags (resource_id, tag_id)
    SELECT r.uuid, t.uuid
        FROM (SELECT uuid, unnest(tags) AS tag
            FROM sdg.resource) AS r
        INNER JOIN sdg.tag AS t ON r.tag = t.name;