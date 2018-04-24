CREATE OR REPLACE FUNCTION drop_index (
    schema_name TEXT,
    table_name TEXT,
    column_name TEXT,
    index_type TEXT
) RETURNS void AS $$
DECLARE index_name TEXT;
BEGIN
    SELECT tc.constraint_name INTO index_name
        FROM information_schema.table_constraints AS tc
        LEFT JOIN information_schema.key_column_usage AS kcu
            ON tc.constraint_catalog = kcu.constraint_catalog
            AND tc.constraint_schema = kcu.constraint_schema
            AND tc.constraint_name = kcu.constraint_name
        WHERE tc.table_schema = drop_index.schema_name
            AND tc.table_name = drop_index.table_name
            AND kcu.column_name = drop_index.column_name
            AND tc.constraint_type = drop_index.index_type;
    IF FOUND THEN
        EXECUTE FORMAT('ALTER TABLE %I.%I DROP CONSTRAINT IF EXISTS %I',
            schema_name, table_name, index_name);
    END IF;
END;
$$ LANGUAGE plpgsql;

SELECT drop_index('sdg', 'content_type', 'name', 'UNIQUE');
SELECT drop_index('sdg', 'tag', 'name', 'UNIQUE');
SELECT drop_index('sdg', 'submission_status', 'status', 'UNIQUE');