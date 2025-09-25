# Stardew Valley 便利ツール 技術要件（Flutter/SQLite/drift）

## 目的 / スコープ

- 目的: 仕様で定義した機能を、Flutterを用いてクロスプラットフォーム実装するための技術選定・設計方針を確定する。
- スコープ: 読み取り専用の同梱SQLiteをマスタデータ源とし、アプリ本体はオフライン完結。将来のWeb/デスクトップ対応を見据えた選定を行う。

## 対応プラットフォーム

- v1: Android / iOS / Windows / macOS / Linux
- 以降（任意）: Web（WASM, drift web）

---

## 中核技術選定（決定）

- データベース: SQLite（配布DBを読み取り専用で同梱）
- ORM/クエリ: drift（旧moor）
  - backend: FFI（`drift/native.dart`）
  - ネイティブバイナリ: `sqlite3_flutter_libs` を採用（FTS5/JSON1対応）
- データファイル配置: `assets/db/data.sqlite` をバンドル、初回起動時にアプリ専用ディレクトリへコピー
- オープンモード: 読み取り専用（`PRAGMA query_only=ON;`、URIで `immutable=1` を付与可能）
- 状態管理: Riverpod 採用（`flutter_riverpod`、必要に応じて `hooks_riverpod`）

---

## 推奨パッケージ（Flutter）

- 必須
  - `drift`: 型安全なクエリ、DAO、マイグレーション（将来）
  - `sqlite3_flutter_libs`: ネイティブSQLite（FTS5/JSON1込み）
  - `flutter_riverpod`: 状態管理（2.x系）
  - `path_provider`: アセットDBをアプリ書き込み領域へコピー
  - `path`: ファイルパス操作
- 開発支援
  - `drift_dev`（dev） + `build_runner`（dev）: コード生成
  - `flutter_lints`（dev）: Lint
- アプリ共通（提案）
  - ルーティング: `go_router`
  - 多言語: Flutter標準 `flutter_localizations` + `intl`
  - 任意: `hooks_riverpod`（Widgetでのフック利用）

備考：ORM不要方針に切替える場合は `sqlite3` 直利用へ移行可能（今回の決定は drift）。

---

## データベース運用方針

- 配布形態: `data.sqlite` をアセットとして同梱し、初回起動でアプリディレクトリへコピーして利用。
- 読み取り専用:
  - 可能なら URI: `file:$path?immutable=1&mode=ro` を用いてオープン。
  - セッション開始時に `PRAGMA query_only=ON;` を実行。
- 機能利用: `FTS5` で名前/別名の全文検索、`JSON1` は将来の柔軟な属性格納に備える。
- バージョニング: `data_version(schema_semver, data_semver, locale)` テーブルを参照してアプリ側で互換性チェック。
- 更新: 新バージョン配布時は `data.sqlite` 差し替えのみ（マイグレーション不要）。

---

## スキーマ（概要）

- `item(id, key, name_ja, name_en, type, sell_price, notes)`
- `crop(id, item_id, season_mask, seed_price, days_to_grow, regrow_days)`
- `npc(id, key, name_ja, name_en)`
- `gift_preference(npc_id, item_id, preference)`  // love/like/neutral/dislike/hate
- `fish(id, item_id, season_mask, weather_mask, time_start, time_end, locations)`
- `bundle(id, room, name_ja, reward_desc)`
- `bundle_item(bundle_id, item_id, qty, quality_req)`
- `name_alias(item_id, alias)`  // かな/カナ/英名/ローマ字/俗称
- `data_version(schema_semver, data_semver, locale)`

インデックス（例）: `item.key`, `name_alias.alias`, `gift_preference(npc_id, preference)`, `fish(season_mask, weather_mask)`, `bundle_item(bundle_id, item_id)`

FTS5: `search_index(item_id, content)` に item名/別名/タグを集約（`content_rowid`で`item`と連携）。

---

## drift 実装方針

- レイヤ構成
  - data: driftテーブル/DAO（`*.drift.dart` 生成物は `lib/generated/`）
  - repository: DAOを集約し、ユースケース向けメソッドを提供
  - domain: 計算ロジック（収益計算/最適化）は純Dartで実装
  - presentation: UI + Riverpodプロバイダ
- DB初期化
  - 起動時にアセットを `appSupportDirectory` 配下へコピー（存在チェック）。
  - driftの接続生成時に `PRAGMA query_only=ON;` を実行。
  - 低層を差し替え可能にするため、`DatabaseConnection` のDIを用意。
- Web対応（将来）
  - `drift/web.dart` + `sqlite3/wasm` でWASMバックエンドへ切替。
  - アセットDBはfetch→`OPFS`/`IndexedDB` へ展開し、`SqlJs`/WASMで読み取り。

---

## 状態管理（Riverpod）方針

- バージョン: `flutter_riverpod` 2.x
- 分類:
  - Repository/DB接続: `Provider`（アプリライフサイクルでシングルトン）。
  - クエリ系: `FutureProvider.family` / `StreamProvider.family` でパラメータ化し、`AsyncValue` でロード/エラーを表現。
  - 画面状態: `Notifier`/`AsyncNotifier` を用いてUIロジックを集約（副作用はRepository経由）。
- 最適化: `ref.watch(select(...))` や familyキーでリビルドを最小化。
- 例外処理: ドメイン例外→UI向けにマッピング、`AsyncValue.guard` を活用。
- デバッグ: `ProviderObserver` を開発ビルドで有効化。
- テスト: `ProviderContainer` でDIし、DB/Repositoryをモックまたは小型のテスト用SQLiteで検証。

---

## コアクエリ（例・方針）

- 作物収益: `crop` JOIN `item`、期間・成長日数・再収穫間隔から回数算出（計算はDart側）。
- ギフト嗜好: `gift_preference` JOIN `npc`/`item`、preferenceでフィルタ。
- 魚検索: `fish` 条件（season_mask, weather_mask, time帯, location LIKE）。
- バンドル: `bundle` JOIN `bundle_item` JOIN `item`。
- FTS: `search_index MATCH :query` → `item`へJOINして候補表示。

---

## ビルド/コード生成

- `build_runner` + `drift_dev` を利用。`lib/db/schema.drift` などでテーブル定義し、DAO/データクラスを生成。
- 生成物はコミット対象（CIでのコード生成時間短縮、再現性確保）。

---

## テスト戦略

- DAO/クエリ: driftのインメモリDB（`NativeDatabase.memory()`）でユニットテスト。
- 計算ロジック: 純Dartのユニットテスト（境界ケース: 成長日数=期間-1、再収穫、端数切り捨て）。
- アセットDB結合: テスト用に縮小版`data.sqlite`を同梱し、実クエリの健全性を検証。

---

## ロギング/診断

- 開発時: `logStatements: true` でSQLを出力可能。
- 本番: ログ抑制、個人データは扱わないためPIIなし。

---

## セキュリティ/プライバシー

- すべてローカル処理。ネットワーク不要。
- セーブ読込（将来）もローカルのみで、データは送信しない。

---

## ライセンス/出典表記

- マスタデータ出典: Stardew Valley Wiki（日本語版）。アプリ内とドキュメントに出典とクレジットを明記。
- 配布DBにはメタデータとして `data_version` と `source` 情報を保持。

---

## 未決定事項 / オプション

- Web対応の有無と時期（WASMバックエンド）
- ルーティング・状態管理の最終選定（推奨を初期採用）
- セーブ読込の実装時期と対象プラットフォーム

---

## 次アクション

1) `pubspec.yaml` に上記パッケージを追加（drift一式）
2) DBアセット配置ルールと初回コピー実装の雛形追加
3) `schema.drift` の初期バージョン作成（テーブル/FTS/インデックス）
4) 最小DAO/Repositoryとサンプルクエリ（魚検索・ギフト嗜好）
