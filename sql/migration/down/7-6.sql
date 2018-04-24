DROP TRIGGER IF EXISTS resource_tags_update ON sdg.resource_tags;
DROP FUNCTION IF EXISTS resource_tag_array_update();

-- Drop views and tables.
DROP TABLE IF EXISTS sdg.resource_tags;
DROP TABLE IF EXISTS sdg.tag;