-- Create internal notes field for resources.
ALTER TABLE IF EXISTS sdg.resource
    ADD COLUMN IF NOT EXISTS notes TEXT;
