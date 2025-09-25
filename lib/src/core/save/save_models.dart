import 'dart:io';

/// 保存フォルダのメタ情報。
class SaveFolder {
  SaveFolder({
    required this.folderPath,
    required this.basename,
    required this.source,
    this.mainFilePath,
    this.infoFilePath,
    this.uniqueId,
  });

  /// 例: C:\\Users\\<User>\\AppData\\Roaming\\StardewValley\\Saves\\Farm_12345
  final String folderPath;

  /// フォルダ名 (Farm_12345)
  final String basename;

  /// 検出元 (local / steamCloud)
  final String source;

  /// メインのセーブXMLファイルのフルパス (Farm_12345)
  final String? mainFilePath;

  /// SaveGameInfo のフルパス
  final String? infoFilePath;

  /// フォルダ名から推測されるユニークID
  final String? uniqueId;

  bool get isValid =>
      File(infoFilePath ?? '').existsSync() && File(mainFilePath ?? '').existsSync();
}

/// セーブのサマリー情報 (読み込み画面相当)。
class SaveGameSummary {
  SaveGameSummary({
    this.farmName,
    this.playerName,
    this.money,
    this.dayOfMonth,
    this.season,
    this.year,
    this.uniqueId,
  });

  final String? farmName;
  final String? playerName;
  final int? money;
  final int? dayOfMonth;
  final String? season;
  final int? year;
  final String? uniqueId;
}

