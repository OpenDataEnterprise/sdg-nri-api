-- Add unique constraints to metadata tables.
ALTER TABLE IF EXISTS sdg.content_type ADD UNIQUE (name);
ALTER TABLE IF EXISTS sdg.submission_status ADD UNIQUE (status);