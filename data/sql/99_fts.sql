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

