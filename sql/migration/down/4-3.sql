ALTER TABLE IF EXISTS sdg.resource
    ADD COLUMN IF NOT EXISTS country_id CHAR(3);

DROP TABLE IF EXISTS sdg.resource_countries;
