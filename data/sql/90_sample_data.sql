-- Sample seed data (subset) to validate schema and UI wiring
BEGIN TRANSACTION;

DELETE FROM data_version;
INSERT INTO data_version(schema_semver, data_semver, locale)
VALUES ('1.0.0', '2025.09.14', 'ja');

-- Items
INSERT INTO item(id, key, name_ja, name_en, type, sell_price, notes) VALUES
  (1, 'parsnip', 'パースニップ', 'Parsnip', 'crop', 35, NULL),
  (2, 'blueberry', 'ブルーベリー', 'Blueberry', 'crop', 50, NULL),
  (3, 'amethyst', 'アメジスト', 'Amethyst', 'gem', 100, NULL),
  (4, 'salmon', 'サーモン', 'Salmon', 'fish', 75, NULL),
  (5, 'milk', 'ミルク', 'Milk', 'resource', 100, NULL),
  (6, 'goat_milk', 'ヤギミルク', 'Goat Milk', 'resource', 225, NULL),
  (7, 'wool', 'ウール', 'Wool', 'resource', 340, NULL),
  (8, 'large_milk', '大ミルク', 'Large Milk', 'resource', 150, NULL),
  (9, 'large_goat_milk', '大ヤギミルク', 'Large Goat Milk', 'resource', 345, NULL);

-- Crops
INSERT INTO crop(id, item_id, season_mask, seed_price, days_to_grow, regrow_days, avg_yield) VALUES
  (1, 1, 1, 20, 4, NULL, 1.0),
  (2, 2, 2, 80, 13, 4, 3.0);

-- NPC
INSERT INTO npc(id, key, name_ja, name_en) VALUES
  (1, 'abigail', 'アビゲイル', 'Abigail');

-- Gifts
INSERT INTO gift_preference(npc_id, item_id, preference) VALUES
  (1, 3, 'love');

-- Fish
-- Salmon: Fall, sunny/rain; 6:00-19:00; River
INSERT INTO fish(id, item_id, season_mask, weather_mask, time_start, time_end, locations) VALUES
  (1, 4, 4, 1|2, 360, 1140, '川');

-- Bundles
INSERT INTO bundle(id, room, name_ja, reward_desc) VALUES
  (1, '工房', '畜産', 'さまざまな畜産品');

INSERT INTO bundle_item(bundle_id, item_id, qty, quality_req) VALUES
  (1, 5, 1, 0),
  (1, 6, 1, 0),
  (1, 7, 1, 0),
  (1, 8, 1, 0),
  (1, 9, 1, 0);

-- Aliases
INSERT INTO name_alias(item_id, alias) VALUES
  (1, 'ぱーすにっぷ'),
  (2, 'ぶるーべりー'),
  (3, 'あめじすと'),
  (4, 'さーもん');

COMMIT;

