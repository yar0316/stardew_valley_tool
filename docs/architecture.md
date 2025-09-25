% アプリケーション アーキテクチャ（簡潔版）

## 方針
- シンプルかつ機能的。画面（presentation）/ビジネスロジック（application）/モデル（domain）/データ取得（data）を明確分離。
- 機能単位（feature-first）で配置し、共通は `core/` に集約。
- Riverpodで依存注入と状態管理。DB実装（drift）は data 層に閉じ込める。

## ディレクトリ構成（概要）

```
lib/
  src/
    app.dart                 # ルートアプリ（MaterialApp等）
    core/
      db/                    # DB接続（drift実装は後日）
      utils/                 # 共通ユーティリティ
    features/
      dashboard/
        presentation/        # 画面・ウィジェット
        application/         # Riverpodコントローラ/Provider
        domain/              # エンティティ/値オブジェクト
        data/                # Repository/DAO（drift実装）
      fish/
        ...                  # 同上（必要時に追加）
      npc/
        ...
      goals/
        ...
```

## レイヤ役割
- presentation: UIのみ。`flutter_riverpod` で Provider を監視。
- application: ユースケース/画面状態の管理（StateNotifier等）。
- domain: エンティティ/値、純粋ロジック（収益計算など）。
- data: Repository実装、drift DAO/クエリ。domain/applicationにインターフェースを提供。

