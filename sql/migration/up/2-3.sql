DROP TEXT SEARCH DICTIONARY IF EXISTS sdg.english_stem_nostop CASCADE;

/* Create text search dictionary without stop words. */
CREATE TEXT SEARCH DICTIONARY sdg.english_stem_nostop (
    template = snowball, /* Use template based on Snowball stemming algorithm. */
    language = english
);

/* Create text search configuration without stop words. */
CREATE TEXT SEARCH CONFIGURATION sdg.english_nostop ( COPY = pg_catalog.english );
ALTER TEXT SEARCH CONFIGURATION sdg.english_nostop
    ALTER MAPPING FOR asciiword, asciihword, hword_asciipart, hword, hword_part, word
    WITH sdg.english_stem_nostop;

/* Create search index update function. */
CREATE OR REPLACE FUNCTION resource_tsv_update_trigger() RETURNS trigger AS $$
DECLARE
    disabled BOOLEAN;
BEGIN
    BEGIN
        disabled := current_setting('sdg.resource_tsv_update_trigger_disabled');
    EXCEPTION WHEN OTHERS THEN
        disabled := 'false';
    END;

    IF disabled = 'true' THEN
        RETURN NEW;
    ELSE
        NEW.tsv :=
            setweight(to_tsvector('sdg.english_nostop', COALESCE(NEW.title, '')), 'A') ||
            setweight(to_tsvector('sdg.english_nostop', COALESCE(NEW.organization, '')), 'B') ||
            setweight(to_tsvector('sdg.english_nostop', COALESCE(array_to_string(NEW.tags, ','), '{}')), 'C') ||
            setweight(to_tsvector('sdg.english_nostop', COALESCE(NEW.description, '')), 'D');
        NEW.updated_at := CURRENT_TIMESTAMP;
        RETURN NEW;
    END IF;
END
$$ LANGUAGE plpgsql;

/* Disable update trigger from working while bulk updating. */
SET sdg.resource_tsv_update_trigger_disabled = 'true';

/* Update all search indices. */
UPDATE sdg.resource SET
    tsv =
        setweight(to_tsvector('sdg.english_nostop', COALESCE(title, '')), 'A') ||
        setweight(to_tsvector('sdg.english_nostop', COALESCE(organization, '')), 'B') ||
        setweight(to_tsvector('sdg.english_nostop', COALESCE(array_to_string(tags, ','), '{}')), 'C') ||
        setweight(to_tsvector('sdg.english_nostop', COALESCE(description, '')), 'D'),
    updated_at = CURRENT_TIMESTAMP;

/* Reenable trigger. */
SET sdg.resource_tsv_update_trigger_disabled = 'false';
