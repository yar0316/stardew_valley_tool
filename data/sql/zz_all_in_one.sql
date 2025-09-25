-- >>> 00_schema.sql

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



-- >>> 50_generated_data.sql

BEGIN TRANSACTION;
DELETE FROM gift_preference;
DELETE FROM name_alias;
DELETE FROM bundle_item;
DELETE FROM bundle;
DELETE FROM fish;
DELETE FROM npc;
DELETE FROM crop;
DELETE FROM item;
INSERT INTO item(id,key,name_ja,name_en,type,sell_price,notes) VALUES (1,'_','パウダーメロン',NULL,'crop',NULL,NULL);
INSERT INTO crop(id,item_id,season_mask,seed_price,days_to_grow,regrow_days,avg_yield) VALUES (1,1,1,30,7,NULL,1.0);
INSERT INTO crop(id,item_id,season_mask,seed_price,days_to_grow,regrow_days,avg_yield) VALUES (2,1,1,80,12,NULL,1.0);
INSERT INTO crop(id,item_id,season_mask,seed_price,days_to_grow,regrow_days,avg_yield) VALUES (3,1,1,40,4,NULL,1.0);
INSERT INTO crop(id,item_id,season_mask,seed_price,days_to_grow,regrow_days,avg_yield) VALUES (4,1,1,70,6,NULL,1.0);
INSERT INTO crop(id,item_id,season_mask,seed_price,days_to_grow,regrow_days,avg_yield) VALUES (5,1,1,20,4,NULL,1.0);
INSERT INTO crop(id,item_id,season_mask,seed_price,days_to_grow,regrow_days,avg_yield) VALUES (6,1,1,50,6,NULL,1.0);
INSERT INTO crop(id,item_id,season_mask,seed_price,days_to_grow,regrow_days,avg_yield) VALUES (7,1,1,100,13,NULL,1.0);
INSERT INTO crop(id,item_id,season_mask,seed_price,days_to_grow,regrow_days,avg_yield) VALUES (8,1,1,20,6,NULL,1.0);
INSERT INTO crop(id,item_id,season_mask,seed_price,days_to_grow,regrow_days,avg_yield) VALUES (9,1,1,40,3,NULL,1.0);
INSERT INTO crop(id,item_id,season_mask,seed_price,days_to_grow,regrow_days,avg_yield) VALUES (10,1,1,0,3,NULL,1.0);
INSERT INTO crop(id,item_id,season_mask,seed_price,days_to_grow,regrow_days,avg_yield) VALUES (11,1,1,2500,10,NULL,1.0);
INSERT INTO crop(id,item_id,season_mask,seed_price,days_to_grow,regrow_days,avg_yield) VALUES (12,1,1,60,10,NULL,1.0);
INSERT INTO crop(id,item_id,season_mask,seed_price,days_to_grow,regrow_days,avg_yield) VALUES (13,1,1,100,8,NULL,1.0);
INSERT INTO crop(id,item_id,season_mask,seed_price,days_to_grow,regrow_days,avg_yield) VALUES (14,1,2,80,12,NULL,1.0);
INSERT INTO crop(id,item_id,season_mask,seed_price,days_to_grow,regrow_days,avg_yield) VALUES (15,1,2,100,7,NULL,1.0);
INSERT INTO crop(id,item_id,season_mask,seed_price,days_to_grow,regrow_days,avg_yield) VALUES (16,1,2,40,6,NULL,1.0);
INSERT INTO crop(id,item_id,season_mask,seed_price,days_to_grow,regrow_days,avg_yield) VALUES (17,1,2,100,9,NULL,1.0);
INSERT INTO crop(id,item_id,season_mask,seed_price,days_to_grow,regrow_days,avg_yield) VALUES (18,1,2,400,13,NULL,1.0);
INSERT INTO crop(id,item_id,season_mask,seed_price,days_to_grow,regrow_days,avg_yield) VALUES (19,1,2,50,8,NULL,1.0);
INSERT INTO crop(id,item_id,season_mask,seed_price,days_to_grow,regrow_days,avg_yield) VALUES (20,1,2,200,8,NULL,1.0);
INSERT INTO crop(id,item_id,season_mask,seed_price,days_to_grow,regrow_days,avg_yield) VALUES (21,1,2,10,4,NULL,1.0);
INSERT INTO crop(id,item_id,season_mask,seed_price,days_to_grow,regrow_days,avg_yield) VALUES (22,1,2,80,13,NULL,1.0);
INSERT INTO crop(id,item_id,season_mask,seed_price,days_to_grow,regrow_days,avg_yield) VALUES (23,1,2,150,14,NULL,1.0);
INSERT INTO crop(id,item_id,season_mask,seed_price,days_to_grow,regrow_days,avg_yield) VALUES (24,1,2,60,11,NULL,1.0);
INSERT INTO crop(id,item_id,season_mask,seed_price,days_to_grow,regrow_days,avg_yield) VALUES (25,1,2,40,5,NULL,1.0);
INSERT INTO crop(id,item_id,season_mask,seed_price,days_to_grow,regrow_days,avg_yield) VALUES (26,1,2,50,11,NULL,1.0);
INSERT INTO crop(id,item_id,season_mask,seed_price,days_to_grow,regrow_days,avg_yield) VALUES (27,1,2,0,6,NULL,1.0);
INSERT INTO crop(id,item_id,season_mask,seed_price,days_to_grow,regrow_days,avg_yield) VALUES (28,1,4,70,7,NULL,1.0);
INSERT INTO crop(id,item_id,season_mask,seed_price,days_to_grow,regrow_days,avg_yield) VALUES (29,1,4,30,8,NULL,1.0);
INSERT INTO crop(id,item_id,season_mask,seed_price,days_to_grow,regrow_days,avg_yield) VALUES (30,1,4,20,6,NULL,1.0);
INSERT INTO crop(id,item_id,season_mask,seed_price,days_to_grow,regrow_days,avg_yield) VALUES (31,1,4,50,4,NULL,1.0);
INSERT INTO crop(id,item_id,season_mask,seed_price,days_to_grow,regrow_days,avg_yield) VALUES (32,1,4,200,12,NULL,1.0);
INSERT INTO crop(id,item_id,season_mask,seed_price,days_to_grow,regrow_days,avg_yield) VALUES (33,1,4,100,13,NULL,1.0);
INSERT INTO crop(id,item_id,season_mask,seed_price,days_to_grow,regrow_days,avg_yield) VALUES (34,1,4,1000,24,NULL,1.0);
INSERT INTO crop(id,item_id,season_mask,seed_price,days_to_grow,regrow_days,avg_yield) VALUES (35,1,4,60,10,NULL,1.0);
INSERT INTO crop(id,item_id,season_mask,seed_price,days_to_grow,regrow_days,avg_yield) VALUES (36,1,4,240,7,NULL,1.0);
INSERT INTO crop(id,item_id,season_mask,seed_price,days_to_grow,regrow_days,avg_yield) VALUES (37,1,4,20,5,NULL,1.0);
INSERT INTO crop(id,item_id,season_mask,seed_price,days_to_grow,regrow_days,avg_yield) VALUES (38,1,4,60,10,NULL,1.0);
INSERT INTO crop(id,item_id,season_mask,seed_price,days_to_grow,regrow_days,avg_yield) VALUES (39,1,4,0,8,NULL,1.0);
INSERT INTO crop(id,item_id,season_mask,seed_price,days_to_grow,regrow_days,avg_yield) VALUES (40,1,8,NULL,7,NULL,1.0);
COMMIT;


-- >>> 99_fts.sql

-- FTS5 virtual table for item name search (names + aliases)
DROP TABLE IF EXISTS search_index;
CREATE VIRTUAL TABLE search_index USING fts5(
  content,
  item_id UNINDEXED,
  tokenize = 'unicode61 remove_diacritics 2'
);

-- Populate search index from items and aliases
INSERT INTO search_index(content, item_id)
SELECT name_ja, id FROM item;

INSERT INTO search_index(content, item_id)
SELECT alias, item_id FROM name_alias;



