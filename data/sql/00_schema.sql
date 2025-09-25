-- SQLite schema for Stardew Valley Tools master data
PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS item (
  id INTEGER PRIMARY KEY,
  key TEXT NOT NULL UNIQUE,
  name_ja TEXT NOT NULL,
  name_en TEXT,
  type TEXT NOT NULL, -- crop, fish, forage, resource, material, gem, etc.
  sell_price INTEGER,
  notes TEXT
);

CREATE TABLE IF NOT EXISTS crop (
  id INTEGER PRIMARY KEY,
  item_id INTEGER NOT NULL REFERENCES item(id) ON DELETE CASCADE,
  season_mask INTEGER NOT NULL, -- 1:spring, 2:summer, 4:fall, 8:winter
  seed_price INTEGER,
  days_to_grow INTEGER NOT NULL,
  regrow_days INTEGER, -- NULL if not regrowable
  avg_yield REAL DEFAULT 1.0 -- average units per harvest (e.g., blueberries ~3)
);

CREATE TABLE IF NOT EXISTS npc (
  id INTEGER PRIMARY KEY,
  key TEXT NOT NULL UNIQUE,
  name_ja TEXT NOT NULL,
  name_en TEXT
);

CREATE TABLE IF NOT EXISTS gift_preference (
  npc_id INTEGER NOT NULL REFERENCES npc(id) ON DELETE CASCADE,
  item_id INTEGER NOT NULL REFERENCES item(id) ON DELETE CASCADE,
  preference TEXT NOT NULL CHECK (preference IN ('love','like','neutral','dislike','hate')),
  PRIMARY KEY (npc_id, item_id)
);

CREATE TABLE IF NOT EXISTS fish (
  id INTEGER PRIMARY KEY,
  item_id INTEGER NOT NULL REFERENCES item(id) ON DELETE CASCADE,
  season_mask INTEGER NOT NULL,  -- 1:spring 2:summer 4:fall 8:winter (bitwise OR)
  weather_mask INTEGER NOT NULL, -- 1:sunny 2:rain 4:storm 8:wind 16:snow (bitwise OR)
  time_start INTEGER NOT NULL,   -- minutes from 0:00 (e.g., 6:00 -> 360)
  time_end INTEGER NOT NULL,
  locations TEXT                 -- JSON/CSV of locations
);

CREATE TABLE IF NOT EXISTS bundle (
  id INTEGER PRIMARY KEY,
  room TEXT NOT NULL,
  name_ja TEXT NOT NULL,
  reward_desc TEXT
);

CREATE TABLE IF NOT EXISTS bundle_item (
  bundle_id INTEGER NOT NULL REFERENCES bundle(id) ON DELETE CASCADE,
  item_id INTEGER NOT NULL REFERENCES item(id) ON DELETE CASCADE,
  qty INTEGER NOT NULL DEFAULT 1,
  quality_req INTEGER, -- 0: normal, 1: silver, 2: gold, 3: iridium
  PRIMARY KEY (bundle_id, item_id)
);

CREATE TABLE IF NOT EXISTS name_alias (
  id INTEGER PRIMARY KEY,
  item_id INTEGER NOT NULL REFERENCES item(id) ON DELETE CASCADE,
  alias TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS data_version (
  schema_semver TEXT NOT NULL,
  data_semver TEXT NOT NULL,
  locale TEXT NOT NULL
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_item_key ON item(key);
CREATE INDEX IF NOT EXISTS idx_alias_alias ON name_alias(alias);
CREATE INDEX IF NOT EXISTS idx_gift_pref ON gift_preference(npc_id, preference);
CREATE INDEX IF NOT EXISTS idx_fish_season_weather ON fish(season_mask, weather_mask);
CREATE INDEX IF NOT EXISTS idx_bundle_item ON bundle_item(bundle_id, item_id);

-- Daily checklist tables
CREATE TABLE IF NOT EXISTS checklist_day (
  id INTEGER PRIMARY KEY,
  year INTEGER NOT NULL,
  season INTEGER NOT NULL,      -- 0:spring 1:summer 2:fall 3:winter
  day_of_month INTEGER NOT NULL,
  UNIQUE(year, season, day_of_month)
);

CREATE TABLE IF NOT EXISTS checklist_item (
  id INTEGER PRIMARY KEY,
  day_id INTEGER NOT NULL REFERENCES checklist_day(id) ON DELETE CASCADE,
  type TEXT NOT NULL CHECK (type IN ('event','watering','custom')),
  title TEXT NOT NULL,
  time_minutes INTEGER,         -- minutes from 0:00 (nullable)
  is_required INTEGER NOT NULL DEFAULT 0, -- 0/1
  is_checked INTEGER NOT NULL DEFAULT 0,  -- 0/1
  is_auto INTEGER NOT NULL DEFAULT 0      -- 0/1
);

CREATE INDEX IF NOT EXISTS idx_checklist_item_day ON checklist_item(day_id);
