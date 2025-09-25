Stardew Valley Wiki Scraper (ja)
================================

Purpose
- Fetch master data from the Japanese Stardew Valley Wiki and generate SQL inserts for SQLite.

Outputs
- JSON intermediates under `data/raw/` (items, crops, fish, npcs, bundles, bundle_items)
- SQL inserts at `data/sql/50_generated_data.sql`

Run
- python -m venv .venv && .venv/Scripts/activate  (Windows)
- pip install -r scripts/wiki_scraper/requirements.txt
- python scripts/wiki_scraper/scrape.py
- python scripts/build_db.py

Coverage (initial)
- Crops: season pages (heuristics for name/days/seed price)
- Fish: fish list (season/weather/time/location)
- NPCs: villager list (names; gift preferences are future work)
- Bundles: community center bundles (bundle name/room/reward, items heuristic)

Notes
- Network calls require internet access. If restricted, point the script at saved HTML files.
- Selectors use heuristics by header keywords; wiki changes may require adjustments.
