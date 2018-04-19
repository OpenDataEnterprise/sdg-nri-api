/* Create publication timestamp field. */
ALTER TABLE sdg.news
    ADD COLUMN published_at TIMESTAMPTZ NOT NULL DEFAULT now();

/* Create publication flags. */
ALTER TABLE sdg.news
    ADD COLUMN publish BOOLEAN NOT NULL DEFAULT FALSE;
ALTER TABLE sdg.event
    ADD COLUMN publish BOOLEAN NOT NULL DEFAULT FALSE;
