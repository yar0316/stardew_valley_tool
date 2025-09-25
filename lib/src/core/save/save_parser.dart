import 'dart:convert';
import 'dart:io';

import 'package:xml/xml.dart';

import 'save_models.dart';

/// Stardew Valley のセーブXMLを読み、必要な情報を抽出するユーティリティ。
class SaveParser {
  /// SaveGameInfo もしくはメインセーブからサマリーを取得。
  static Future<SaveGameSummary?> readSummaryFromFolder(SaveFolder folder) async {
    // SaveGameInfo を優先
    if (folder.infoFilePath != null && File(folder.infoFilePath!).existsSync()) {
      final s = await _parseSummary(File(folder.infoFilePath!));
      if (s != null) return s;
    }
    if (folder.mainFilePath != null && File(folder.mainFilePath!).existsSync()) {
      final s = await _parseSummary(File(folder.mainFilePath!));
      if (s != null) return s;
    }
    return null;
  }

  /// XMLから必要最低限のサマリー情報を抽出
  static Future<SaveGameSummary?> _parseSummary(File file) async {
    try {
      final xmlStr = await file.openRead().transform(utf8.decoder).join();
      final doc = XmlDocument.parse(xmlStr);
      final root = doc.rootElement; // SaveGame

      String? _t(Iterable<String> path) => _tryText(root, path);

      final farmName = _t(['player', 'farmName']) ?? _t(['farmName']);
      final playerName = _t(['player', 'name']);
      final moneyStr = _t(['player', 'money']);
      final money = int.tryParse(moneyStr ?? '');
      final day = int.tryParse(_t(['dayOfMonth']) ?? '');
      final season = _t(['season']);
      final year = int.tryParse(_t(['year']) ?? '');

      return SaveGameSummary(
        farmName: farmName,
        playerName: playerName,
        money: money,
        dayOfMonth: day,
        season: season,
        year: year,
      );
    } catch (_) {
      return null;
    }
  }

  // ------- XML Helpers -------

  static String? _tryText(XmlElement root, Iterable<String> path) {
    XmlElement? node = root;
    for (final seg in path) {
      final next = node.findElements(seg).cast<XmlElement?>().firstWhere(
            (e) => e != null,
            orElse: () => null,
          );
      if (next == null) return null;
      node = next;
    }
    final text = node.text.trim();
    return text.isEmpty ? null : text;
  }
}

