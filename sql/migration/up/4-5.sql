-- Create publication timestamp field.
ALTER TABLE IF EXISTS sdg.news
    ADD COLUMN IF NOT EXISTS published_at TIMESTAMPTZ NOT NULL DEFAULT now();

-- Create publication flags.
ALTER TABLE IF EXISTS sdg.news
    ADD COLUMN publish BOOLEAN NOT NULL DEFAULT FALSE;
ALTER TABLE IF EXISTS sdg.event
    ADD COLUMN publish BOOLEAN NOT NULL DEFAULT FALSE;

-- Set all existing news and events to be published by default.
UPDATE sdg.news SET publish = true;
UPDATE sdg.event SET publish = true;