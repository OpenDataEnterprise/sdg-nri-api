-- Disable update trigger from working while bulk updating.
SET sdg.resource_tsv_update_trigger_disabled = 'true';

-- Revert all search indices to previous version.
UPDATE sdg.resource SET
    tsv =
        setweight(to_tsvector('english', COALESCE(title, '')), 'A') ||
        setweight(to_tsvector('english', COALESCE(organization, '')), 'B') ||
        setweight(to_tsvector('sdg.english_nostop', COALESCE(array_to_string(tags, ','), '{}')), 'C') ||
        setweight(to_tsvector('sdg.english_nostop', COALESCE(description, '')), 'D'),
    updated_at = CURRENT_TIMESTAMP;

-- Reenable trigger.
SET sdg.resource_tsv_update_trigger_disabled = 'false';

-- Rollback search index update function to previous version.
CREATE OR REPLACE FUNCTION resource_tsv_update_trigger() RETURNS trigger AS $$
BEGIN
    NEW.tsv :=
        setweight(to_tsvector('english', COALESCE(NEW.title,'')), 'A') ||
        setweight(to_tsvector('english', COALESCE(NEW.organization,'')), 'B') ||
        setweight(to_tsvector('english', COALESCE(NEW.description,'')), 'C');
    RETURN NEW;
END
$$ LANGUAGE plpgsql;

DROP TEXT SEARCH CONFIGURATION IF EXISTS sdg.english_nostop CASCADE;
DROP TEXT SEARCH DICTIONARY IF EXISTS sdg.english_stem_nostop CASCADE;
