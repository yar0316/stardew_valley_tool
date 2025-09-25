import 'dart:async';
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
      final season = _t(['season']) ?? _t(['currentSeason']);
      final year = int.tryParse(_t(['year']) ?? '');
      final dayOfWeek = int.tryParse(
            _t(['dayOfWeek']) ?? _t(['currentDayOfWeek']) ?? _t(['player', 'dayOfWeek']) ?? '',
          );
      final luckStr = _t(['player', 'dailyLuck']) ?? _t(['dailyLuck']);
      final dailyLuck = double.tryParse(luckStr ?? '');
      final weatherIcon = _t(['weatherIcon']);
      final isRaining = _parseBool(_t(['isRaining']) ?? _t(['player', 'isRaining']));
      final isLightning =
          _parseBool(_t(['isLightning']) ?? _t(['player', 'isLightning']));
      final isSnowing = _parseBool(_t(['isSnowing']) ?? _t(['player', 'isSnowing']));
      final isDebris =
          _parseBool(_t(['isDebrisWeather']) ?? _t(['player', 'isDebrisWeather']));

      return SaveGameSummary(
        farmName: farmName,
        playerName: playerName,
        money: money,
        dayOfMonth: day,
        season: season,
        year: year,
        dayOfWeek: dayOfWeek,
        dailyLuck: dailyLuck,
        weatherIcon: weatherIcon,
        isRaining: isRaining,
        isLightning: isLightning,
        isSnowing: isSnowing,
        isDebrisWeather: isDebris,
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

  static bool? _parseBool(String? text) {
    if (text == null) return null;
    final lower = text.trim().toLowerCase();
    if (lower == 'true' || lower == '1') return true;
    if (lower == 'false' || lower == '0') return false;
    return null;
  }

  /// 指定フォルダのセーブファイル更新を監視し、サマリーをストリームで返す。
  static Stream<SaveGameSummary?> watchSummary(SaveFolder folder) {
    final controller = StreamController<SaveGameSummary?>.broadcast();
    StreamSubscription<FileSystemEvent>? sub;

    Future<void> emit() async {
      try {
        final summary = await readSummaryFromFolder(folder);
        if (!controller.isClosed) {
          controller.add(summary);
        }
      } catch (e) {
        if (!controller.isClosed) {
          controller.addError(e);
        }
      }
    }

    void startWatch() {
      emit();
      final dir = Directory(folder.folderPath);
      if (!dir.existsSync()) return;
      final targetNames = <String>{};
      if (folder.infoFilePath != null) {
        targetNames.add(File(folder.infoFilePath!).uri.pathSegments.last);
      }
      if (folder.mainFilePath != null) {
        targetNames.add(File(folder.mainFilePath!).uri.pathSegments.last);
      }
      sub = dir
          .watch(events: FileSystemEvent.modify | FileSystemEvent.create)
          .listen((event) {
        final eventName = File(event.path).uri.pathSegments.last;
        if (targetNames.isEmpty || targetNames.contains(eventName)) {
          emit();
        }
      });
    }

    controller
      ..onListen = startWatch
      ..onCancel = () async {
        await sub?.cancel();
        if (!controller.hasListener) {
          await controller.close();
        }
      };

    return controller.stream;
  }
}

