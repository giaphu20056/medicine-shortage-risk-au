-- Schema for medicine-shortage-risk-au. Re-runnable: drops and recreates tables.
-- ingredient_key in tga_episodes is NOT a foreign key: unmatched rows are kept (not measurable, not zero).
DROP TABLE IF EXISTS tga_episodes;
DROP TABLE IF EXISTS pbs_public_monthly;
DROP TABLE IF EXISTS pbs_ingredient_lookup;

CREATE TABLE tga_episodes (
    artg_id                         INTEGER NOT NULL,
    artg_name                       TEXT,
    active_ingredients              TEXT,
    dosage_form                     TEXT,
    quantity_of_active_ingredients  TEXT,
    sponsor                         TEXT,
    shortage_status                 TEXT,
    supply_impact_start_date        TEXT,
    supply_impact_end_date          TEXT,
    deletion_from_market            TEXT,
    shortage_impact_rating          TEXT,
    availability                    TEXT,
    reason                          TEXT,
    management_action               TEXT,
    last_updated                    TEXT,
    source                          TEXT,
    end_lt_start                    INTEGER,
    end_after_report                INTEGER,
    episode_type                    TEXT,
    end_passed                      INTEGER,
    no_ingredient                   INTEGER,
    valid_duration                  INTEGER,
    duration_days                   REAL,
    ingredient_key                  TEXT,
    in_pbs_map                      INTEGER,
    in_pbs_public                   INTEGER
);
CREATE INDEX idx_tga_ingredient ON tga_episodes (ingredient_key);
CREATE INDEX idx_tga_type ON tga_episodes (episode_type);

CREATE TABLE pbs_public_monthly (
    month           TEXT    NOT NULL,
    ingredient_key  TEXT    NOT NULL,
    prescriptions   INTEGER NOT NULL
);
CREATE INDEX idx_pbs_ing_month ON pbs_public_monthly (ingredient_key, month);

CREATE TABLE pbs_ingredient_lookup (
    ingredient_key  TEXT PRIMARY KEY,
    pbs_drug_names  TEXT
);
