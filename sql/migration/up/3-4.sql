/* Create associative table between resources and countries. */
CREATE TABLE sdg.resource_countries (
    resource_id UUID REFERENCES sdg.resource (uuid) ON UPDATE CASCADE ON DELETE CASCADE,
    country_id CHARACTER(3) REFERENCES sdg.country (iso_alpha3) ON UPDATE CASCADE ON DELETE CASCADE,
    PRIMARY KEY (resource_id, country_id)
);

/* Move existing country foreign keys to associative table. */
INSERT INTO sdg.resource_countries (resource_id, country_id)
    SELECT uuid, country_id
    FROM sdg.resource
    WHERE country_id IS NOT NULL;

/* Remove original foreign key from resource table. */
ALTER TABLE sdg.resource DROP COLUMN IF EXISTS country_id;
