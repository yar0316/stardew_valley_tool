from __future__ import annotations

import json
import re
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Dict, Iterable, List, Tuple

import requests
from bs4 import BeautifulSoup


BASE_URL = "https://ja.stardewvalleywiki.com"

ROOT = Path(__file__).resolve().parents[2]
RAW_DIR = ROOT / "data" / "raw"
SQL_DIR = ROOT / "data" / "sql"


@dataclass
class Item:
    key: str
    name_ja: str
    name_en: str | None
    type: str  # 'crop' | 'fish' | 'material' | ...
    sell_price: int | None = None
    notes: str | None = None


@dataclass
class FishRow:
    key: str
    name_ja: str
    season_mask: int
    weather_mask: int
    time_start: int
    time_end: int
    locations: str  # CSV / simple text


@dataclass
class NpcRow:
    key: str
    name_ja: str
    name_en: str | None


@dataclass
class BundleRow:
    room: str
    name_ja: str
    reward_desc: str | None


@dataclass
class BundleItemRow:
    bundle_name_ja: str
    item_name_ja: str
    qty: int
    quality_req: int | None


def fetch(url: str) -> BeautifulSoup:
    r = requests.get(url, timeout=30)
    r.raise_for_status()
    return BeautifulSoup(r.text, "lxml")


def parse_table(table: BeautifulSoup) -> List[List[str]]:
    rows: List[List[str]] = []
    for tr in table.select("tr"):
        cols = [c.get_text(strip=True) for c in tr.select("th,td")]
        if cols:
            rows.append(cols)
    return rows


def scrape_crops() -> Tuple[List[Item], List[Dict[str, Any]]]:
    items: List[Item] = []
    crops: List[Dict[str, Any]] = []
    # The Japanese wiki organizes crops by season; collect from each season page
    season_pages = {
        "春": "/%E6%98%A5",
        "夏": "/%E5%A4%8F",
        "秋": "/%E7%A7%8B",
        "冬": "/%E5%86%AC",
    }
    season_mask_map = {"春": 1, "夏": 2, "秋": 4, "冬": 8}
    seen: set[str] = set()
    for name, path in season_pages.items():
        try:
            soup = fetch(BASE_URL + path)
        except Exception:
            continue
        # Heuristic: find tables with 作物名/成長日数/種価格 等の見出し
        for table in soup.select("table"):  # narrow later if needed
            rows = parse_table(table)
            if not rows or len(rows[0]) < 3:
                continue
            header = rows[0]
            if not any("作物" in h or "名称" in h for h in header):
                continue
            # Attempt to locate column indices
            def idx_of(keys: Iterable[str]) -> int | None:
                for i, h in enumerate(header):
                    if any(k in h for k in keys):
                        return i
                return None

            i_name = idx_of(["作物", "名称", "作物名"]) or 0
            i_days = idx_of(["成長", "日数"]) or 1
            i_seed = idx_of(["種", "価格"]) or 2
            for row in rows[1:]:
                if len(row) <= max(i_name, i_days, i_seed):
                    continue
                name_ja = row[i_name]
                if not name_ja or name_ja in seen:
                    continue
                seen.add(name_ja)
                # extract integers
                def to_int(s: str) -> int | None:
                    m = re.search(r"\d+", s)
                    return int(m.group(0)) if m else None

                days = to_int(row[i_days]) or 0
                seed_price = to_int(row[i_seed])
                key = re.sub(r"[^a-z0-9_]+", "_", name_ja.lower())
                items.append(Item(key=key, name_ja=name_ja, name_en=None, type="crop"))
                crops.append(
                    {
                        "key": key,
                        "season_mask": season_mask_map[name],
                        "seed_price": seed_price,
                        "days_to_grow": days,
                        "regrow_days": None,
                        "avg_yield": 1.0,
                    }
                )
    return items, crops


def _season_mask_from_text(text: str) -> int:
    mask = 0
    if any(s in text for s in ["春", "春季", "Spring"]):
        mask |= 1
    if any(s in text for s in ["夏", "夏季", "Summer"]):
        mask |= 2
    if any(s in text for s in ["秋", "秋季", "Fall", "Autumn"]):
        mask |= 4
    if any(s in text for s in ["冬", "冬季", "Winter"]):
        mask |= 8
    return mask


def _weather_mask_from_text(text: str) -> int:
    mask = 0
    if any(s in text for s in ["晴", "晴れ", "Sunny"]):
        mask |= 1
    if any(s in text for s in ["雨", "Rain"]):
        mask |= 2
    if any(s in text for s in ["嵐", "Storm"]):
        mask |= 4
    if any(s in text for s in ["風", "Wind"]):
        mask |= 8
    if any(s in text for s in ["雪", "Snow"]):
        mask |= 16
    # Default to all weather if none detected
    if mask == 0:
        mask = 1 | 2 | 4 | 8 | 16
    return mask


def _parse_time_range(text: str) -> tuple[int, int]:
    # Accept forms like "6:00-19:00" or "6:00 – 19:00" or "6時-19時"
    text = text.replace("–", "-").replace("—", "-")
    m = re.findall(r"(\d{1,2})[:時](\d{2})?", text)
    if len(m) >= 1:
        def to_min(h: str, mm: str | None) -> int:
            return int(h) * 60 + (int(mm) if (mm and mm.isdigit()) else 0)
        if len(m) == 1:
            h1, mm1 = m[0][0], m[0][1] or "00"
            return to_min(h1, mm1), to_min(h1, mm1)
        h1, mm1 = m[0][0], m[0][1] or "00"
        h2, mm2 = m[1][0], m[1][1] or "00"
        return to_min(h1, mm1), to_min(h2, mm2)
    # Fallback: whole day
    return 0, 1440


def scrape_fish() -> Tuple[List[Item], List[FishRow]]:
    items: List[Item] = []
    fish: List[FishRow] = []
    candidates = ["/魚", "/%E9%AD%9A", "/Fish"]
    soup = None
    for path in candidates:
        try:
            soup = fetch(BASE_URL + path)
            break
        except Exception:
            continue
    if soup is None:
        return items, fish
    for table in soup.select("table"):
        rows = parse_table(table)
        if not rows or len(rows[0]) < 3:
            continue
        header = rows[0]
        if not (any("魚" in h or "名称" in h for h in header) and any("時間" in h for h in header)):
            continue
        def idx_of(keys: Iterable[str]) -> int | None:
            for i, h in enumerate(header):
                if any(k in h for k in keys):
                    return i
            return None
        i_name = idx_of(["魚", "名称", "名前"]) or 0
        i_season = idx_of(["季節"]) or 1
        i_weather = idx_of(["天気"]) or 2
        i_time = idx_of(["時間"]) or 3
        i_loc = idx_of(["場所"]) or (4 if len(header) > 4 else 3)
        for row in rows[1:]:
            if len(row) <= max(i_name, i_season, i_weather, i_time, i_loc):
                continue
            name_ja = row[i_name]
            if not name_ja:
                continue
            key = re.sub(r"[^a-z0-9_]+", "_", name_ja.lower())
            s_mask = _season_mask_from_text(row[i_season])
            w_mask = _weather_mask_from_text(row[i_weather])
            t_start, t_end = _parse_time_range(row[i_time])
            loc = row[i_loc]
            items.append(Item(key=key, name_ja=name_ja, name_en=None, type="fish"))
            fish.append(FishRow(
                key=key,
                name_ja=name_ja,
                season_mask=s_mask or (1 | 2 | 4 | 8),
                weather_mask=w_mask,
                time_start=t_start,
                time_end=t_end,
                locations=loc,
            ))
    return items, fish


def scrape_npcs() -> List[NpcRow]:
    npcs: List[NpcRow] = []
    candidates = ["/住人", "/%E4%BD%8F%E4%BA%BA", "/村人", "/%E6%9D%91%E4%BA%BA", "/Villagers"]
    soup = None
    for path in candidates:
        try:
            soup = fetch(BASE_URL + path)
            break
        except Exception:
            continue
    if soup is None:
        return npcs
    for table in soup.select("table"):
        rows = parse_table(table)
        if not rows or len(rows[0]) < 2:
            continue
        header = rows[0]
        if not any("名前" in h or "名称" in h for h in header):
            continue
        def idx_of(keys: Iterable[str]) -> int | None:
            for i, h in enumerate(header):
                if any(k in h for k in keys):
                    return i
            return None
        i_name = idx_of(["名前", "名称"]) or 0
        i_en = idx_of(["英名", "英語", "English"]) or None
        for row in rows[1:]:
            if len(row) <= i_name:
                continue
            name_ja = row[i_name]
            if not name_ja:
                continue
            name_en = row[i_en] if (i_en is not None and len(row) > i_en) else None
            key = re.sub(r"[^a-z0-9_]+", "_", name_ja.lower())
            npcs.append(NpcRow(key=key, name_ja=name_ja, name_en=name_en))
    return npcs


def scrape_bundles() -> Tuple[List[BundleRow], List[BundleItemRow]]:
    bundles: List[BundleRow] = []
    items: List[BundleItemRow] = []
    candidates = ["/バンドル", "/%E3%83%90%E3%83%B3%E3%83%89%E3%83%AB", "/コミュニティセンター", "/Community_Center"]
    soup = None
    for path in candidates:
        try:
            soup = fetch(BASE_URL + path)
            break
        except Exception:
            continue
    if soup is None:
        return bundles, items
    # Heuristic: sections (h2/h3) contain bundle names; tables/lists below enumerate required items
    for sec in soup.select("h2, h3"):
        title = sec.get_text(strip=True)
        if not title or ("バンドル" not in title and "Bundle" not in title and "室" not in title):
            continue
        room = title
        # Find following tables until next heading
        sib = sec
        while True:
            sib = sib.find_next_sibling()
            if sib is None or sib.name in {"h2", "h3"}:
                break
            # Table listing bundles
            if sib.name == "table":
                rows = parse_table(sib)
                if not rows or len(rows[0]) < 2:
                    continue
                header = rows[0]
                # columns might be: 名称 / 必要アイテム / 報酬
                def idx_of(keys: Iterable[str]) -> int | None:
                    for i, h in enumerate(header):
                        if any(k in h for k in keys):
                            return i
                    return None
                i_name = idx_of(["名称", "バンドル", "Name"]) or 0
                i_items = idx_of(["必要", "アイテム", "要求", "Items"]) or None
                i_reward = idx_of(["報酬", "Reward"]) or None
                for row in rows[1:]:
                    if len(row) <= i_name:
                        continue
                    bname = row[i_name]
                    reward = row[i_reward] if (i_reward is not None and len(row) > i_reward) else None
                    bundles.append(BundleRow(room=room, name_ja=bname, reward_desc=reward))
                    if i_items is not None and len(row) > i_items:
                        # split items by separators
                        raw = row[i_items]
                        parts = re.split(r"[、,・/]|\s+and\s+|\s+or\s+", raw)
                        for p in parts:
                            it = p.strip()
                            if not it:
                                continue
                            items.append(BundleItemRow(bundle_name_ja=bname, item_name_ja=it, qty=1, quality_req=None))
    return bundles, items


def write_json(path: Path, data: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")


def generate_sql(
    items: List[Item],
    crops: List[Dict[str, Any]],
    fish_rows: List[FishRow],
    npc_rows: List[NpcRow],
    bundles: List[BundleRow],
    bundle_items: List[BundleItemRow],
) -> str:
    # Assign IDs deterministically by order
    lines: List[str] = []
    lines.append("BEGIN TRANSACTION;")
    lines.append("DELETE FROM gift_preference;")
    lines.append("DELETE FROM name_alias;")
    lines.append("DELETE FROM bundle_item;")
    lines.append("DELETE FROM bundle;")
    lines.append("DELETE FROM fish;")
    lines.append("DELETE FROM npc;")
    lines.append("DELETE FROM crop;")
    lines.append("DELETE FROM item;")

    for idx, it in enumerate(items, start=1):
        name_en = it.name_en.replace("'", "''") if it.name_en else None
        notes = it.notes.replace("'", "''") if it.notes else None
        sell_price = "NULL" if it.sell_price is None else str(it.sell_price)
        lines.append(
            "INSERT INTO item(id,key,name_ja,name_en,type,sell_price,notes) VALUES ({},'{}','{}',{},'{}',{},{});".format(
                idx,
                it.key.replace("'", "''"),
                it.name_ja.replace("'", "''"),
                f"'{name_en}'" if name_en else "NULL",
                it.type,
                sell_price,
                f"'{notes}'" if notes else "NULL",
            )
        )
    key_to_id = {it.key: i + 1 for i, it in enumerate(items)}
    for i, c in enumerate(crops, start=1):
        item_id = key_to_id.get(c["key"]) or i
        regrow = "NULL" if c["regrow_days"] is None else str(c["regrow_days"])
        avg_yield = c.get("avg_yield", 1.0)
        lines.append(
            "INSERT INTO crop(id,item_id,season_mask,seed_price,days_to_grow,regrow_days,avg_yield) VALUES ({},{},{},{},{},{},{});".format(
                i,
                item_id,
                c["season_mask"],
                c["seed_price"] if c["seed_price"] is not None else "NULL",
                c["days_to_grow"],
                regrow,
                avg_yield,
            )
        )
    # NPC
    for i, n in enumerate(npc_rows, start=1):
        name_en = n.name_en.replace("'", "''") if n.name_en else None
        lines.append(
            "INSERT INTO npc(id,key,name_ja,name_en) VALUES ({},'{}','{}',{});".format(
                i,
                n.key.replace("'", "''"),
                n.name_ja.replace("'", "''"),
                f"'{name_en}'" if name_en else "NULL",
            )
        )
    # Fish
    for i, f in enumerate(fish_rows, start=1):
        item_id = key_to_id.get(f.key, 0)
        if not item_id:
            # Create a new item_id if missing
            item_id = len(key_to_id) + 1
            key_to_id[f.key] = item_id
            lines.append(
                "INSERT INTO item(id,key,name_ja,name_en,type,sell_price,notes) VALUES ({},'{}','{}',NULL,'fish',NULL,NULL);".format(
                    item_id,
                    f.key.replace("'", "''"),
                    f.name_ja.replace("'", "''"),
                )
            )
        lines.append(
            "INSERT INTO fish(id,item_id,season_mask,weather_mask,time_start,time_end,locations) VALUES ({},{},{},{},{},{},'{}');".format(
                i,
                item_id,
                f.season_mask,
                f.weather_mask,
                f.time_start,
                f.time_end,
                str(f.locations).replace("'", "''"),
            )
        )
    # Bundles
    for i, b in enumerate(bundles, start=1):
        reward = b.reward_desc.replace("'", "''") if b.reward_desc else None
        lines.append(
            "INSERT INTO bundle(id,room,name_ja,reward_desc) VALUES ({},'{}','{}',{});".format(
                i,
                b.room.replace("'", "''"),
                b.name_ja.replace("'", "''"),
                f"'{reward}'" if reward else "NULL",
            )
        )
    # Bundle items (link by bundle name)
    bundle_name_to_id = {b.name_ja: i + 1 for i, b in enumerate(bundles)}
    for bi in bundle_items:
        b_id = bundle_name_to_id.get(bi.bundle_name_ja)
        if not b_id:
            continue
        # ensure item exists
        item_key = re.sub(r"[^a-z0-9_]+", "_", bi.item_name_ja.lower())
        item_id = key_to_id.get(item_key)
        if not item_id:
            item_id = len(key_to_id) + 1
            key_to_id[item_key] = item_id
            lines.append(
                "INSERT INTO item(id,key,name_ja,name_en,type,sell_price,notes) VALUES ({},'{}','{}',NULL,'material',NULL,NULL);".format(
                    item_id,
                    item_key.replace("'", "''"),
                    bi.item_name_ja.replace("'", "''"),
                )
            )
        qty = bi.qty
        qual = "NULL" if bi.quality_req is None else str(bi.quality_req)
        lines.append(
            "INSERT INTO bundle_item(bundle_id,item_id,qty,quality_req) VALUES ({},{},{},{});".format(
                b_id, item_id, qty, qual
            )
        )
    lines.append("COMMIT;")
    return "\n".join(lines)


def main() -> None:
    base_items, crops = scrape_crops()
    fish_items, fish_rows = scrape_fish()
    npcs = scrape_npcs()
    bundles, bundle_items = scrape_bundles()

    # Merge items (by key)
    items_map: Dict[str, Item] = {i.key: i for i in base_items}
    for it in fish_items:
        items_map.setdefault(it.key, it)
    items = list(items_map.values())

    # Persist JSON intermediates
    write_json(RAW_DIR / "items.json", [it.__dict__ for it in items])
    write_json(RAW_DIR / "crops.json", crops)
    write_json(RAW_DIR / "fish.json", [f.__dict__ for f in fish_rows])
    write_json(RAW_DIR / "npcs.json", [n.__dict__ for n in npcs])
    write_json(RAW_DIR / "bundles.json", [b.__dict__ for b in bundles])
    write_json(RAW_DIR / "bundle_items.json", [b.__dict__ for b in bundle_items])

    # Generate SQL inserts
    sql = generate_sql(items, crops, fish_rows, npcs, bundles, bundle_items)
    SQL_DIR.mkdir(parents=True, exist_ok=True)
    (SQL_DIR / "50_generated_data.sql").write_text(sql, encoding="utf-8")
    print("Wrote:", SQL_DIR / "50_generated_data.sql")


if __name__ == "__main__":
    main()
