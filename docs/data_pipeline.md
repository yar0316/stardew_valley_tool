% データパイプライン（Wiki→SQLite）

## 概要
- 出典: Stardew Valley Wiki 日本語版（https://ja.stardewvalleywiki.com）
- 手順: スクレイピング → JSON中間 → SQL生成 → SQLiteビルド

## 生成物
- JSON: `data/raw/*.json`
- SQL: `data/sql/50_generated_data.sql`
- DB: `data/data.sqlite`

## 実行手順（開発端末）
1) Python仮想環境を用意し依存をインストール
   - Windows: `python -m venv .venv && .venv\Scripts\activate && pip install -r scripts/wiki_scraper/requirements.txt`
2) スクレイピングを実行
   - `python scripts/wiki_scraper/scrape.py`
3) DBをビルド
   - `python scripts/build_db.py`
4) アプリに同梱
   - `data/data.sqlite` を `assets/db/data.sqlite` へ配置（Flutter側で参照）

## 注意
- ネットワーク環境によりスクレイピングがブロックされる場合、ローカル保存したHTMLを読み込むように `scrape.py` を拡張してください。
- Wikiの構造変更に備え、スクレイパはテーブル検出をヘuristicに実装しています。必要に応じてセレクタを調整してください。
- スキーマは `data/sql/00_schema.sql` を参照。FTSは `99_fts.sql`。

