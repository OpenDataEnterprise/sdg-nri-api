DROP TABLE IF EXISTS sdg.resource_countries;

ALTER TABLE sdg.resource ADD COLUMN IF NOT EXISTS country_id;
