import 'dart:io';

import 'save_models.dart';

/// Stardew Valley のセーブフォルダを検出するユーティリティ。
class SaveLocator {
  /// 既定のローカルセーブディレクトリ (存在確認済み) を返します。
  /// 見つからない場合は null。
  static String? defaultLocalSaveRoot() {
    try {
      if (Platform.isWindows) {
        final appData = Platform.environment['APPDATA'];
        if (appData == null || appData.isEmpty) return null;
        final path = _join(appData, 'StardewValley', 'Saves');
        return Directory(path).existsSync() ? path : null;
      } else if (Platform.isMacOS) {
        final home = Platform.environment['HOME'];
        if (home == null || home.isEmpty) return null;
        final path = _join(home, 'Library', 'Application Support', 'StardewValley', 'Saves');
        return Directory(path).existsSync() ? path : null;
      } else if (Platform.isLinux) {
        final home = Platform.environment['HOME'];
        if (home == null || home.isEmpty) return null;
        final path = _join(home, '.config', 'StardewValley', 'Saves');
        return Directory(path).existsSync() ? path : null;
      }
    } catch (_) {
      // ignore
    }
    return null;
  }

  /// 既知の Steam Cloud セーブの候補ルート(存在確認済み)を返します。
  static List<String> steamCloudRoots() {
    final roots = <String>[];
    try {
      if (Platform.isWindows) {
        // 例: C:\Program Files (x86)\Steam\userdata\<SteamID>\413150\remote
        final pf86 = Platform.environment['PROGRAMFILES(X86)'];
        final pf = Platform.environment['PROGRAMFILES'];
        final candidates = <String>[];
        if (pf86 != null && pf86.isNotEmpty) {
          candidates.add(_join(pf86, 'Steam', 'userdata'));
        }
        if (pf != null && pf.isNotEmpty) {
          candidates.add(_join(pf, 'Steam', 'userdata'));
        }
        for (final base in candidates) {
          final dir = Directory(base);
          if (!dir.existsSync()) continue;
          for (final entry in dir.listSync().whereType<Directory>()) {
            final remote = Directory(_join(entry.path, '413150', 'remote'));
            if (remote.existsSync()) roots.add(remote.path);
          }
        }
      } else if (Platform.isMacOS) {
        final home = Platform.environment['HOME'];
        if (home != null && home.isNotEmpty) {
          final base = _join(home, 'Library', 'Application Support', 'Steam', 'userdata');
          final dir = Directory(base);
          if (dir.existsSync()) {
            for (final entry in dir.listSync().whereType<Directory>()) {
              final remote = Directory(_join(entry.path, '413150', 'remote'));
              if (remote.existsSync()) roots.add(remote.path);
            }
          }
        }
      } else if (Platform.isLinux) {
        final home = Platform.environment['HOME'];
        final bases = <String>[];
        if (home != null && home.isNotEmpty) {
          bases.add(_join(home, '.local', 'share', 'Steam', 'userdata'));
          bases.add(_join(home, '.steam', 'steam', 'userdata'));
        }
        for (final base in bases) {
          final dir = Directory(base);
          if (!dir.existsSync()) continue;
          for (final entry in dir.listSync().whereType<Directory>()) {
            final remote = Directory(_join(entry.path, '413150', 'remote'));
            if (remote.existsSync()) roots.add(remote.path);
          }
        }
      }
    } catch (_) {
      // ignore
    }
    return roots;
  }

  /// セーブフォルダを列挙します。
  /// [includeSteamCloud] を有効にすると Steam Cloud 側も探索します。
  static Future<List<SaveFolder>> discoverSaves({bool includeSteamCloud = true}) async {
    final results = <SaveFolder>[];

    final local = defaultLocalSaveRoot();
    if (local != null) {
      results.addAll(_scanRoot(local, source: 'local'));
    }

    if (includeSteamCloud) {
      for (final root in steamCloudRoots()) {
        results.addAll(_scanRoot(root, source: 'steamCloud'));
      }
    }

    return results;
  }

  // ----- helpers -----

  static List<SaveFolder> _scanRoot(String rootPath, {required String source}) {
    final dir = Directory(rootPath);
    if (!dir.existsSync()) return const [];
    final items = <SaveFolder>[];
    for (final entry in dir.listSync().whereType<Directory>()) {
      final base = entry.path.split(_sep).last;
      final infoPath = _join(entry.path, 'SaveGameInfo');
      String? mainPath;
      final mainCandidate = _join(entry.path, base);
      if (File(mainCandidate).existsSync()) {
        mainPath = mainCandidate;
      } else {
        // 念のため XML 拡張子や同名ファイルを探す
        final files = entry.listSync().whereType<File>();
        for (final f in files) {
          final name = f.path.split(_sep).last;
          if (name == base || name == '$base.xml') {
            mainPath = f.path;
            break;
          }
        }
      }
      final uniqueId = _extractUniqueIdFromBasename(base);
      items.add(SaveFolder(
        folderPath: entry.path,
        basename: base,
        source: source,
        mainFilePath: mainPath,
        infoFilePath: File(infoPath).existsSync() ? infoPath : null,
        uniqueId: uniqueId,
      ));
    }
    return items;
  }

  static String? _extractUniqueIdFromBasename(String base) {
    final idx = base.lastIndexOf('_');
    if (idx <= 0 || idx + 1 >= base.length) return null;
    final tail = base.substring(idx + 1);
    return tail.isNotEmpty ? tail : null;
  }

  static const String _sep = '/';

  static String _join(String a, [String? b, String? c, String? d, String? e, String? f]) {
    final parts = <String>[a, if (b != null) b, if (c != null) c, if (d != null) d, if (e != null) e, if (f != null) f];
    final isWin = Platform.isWindows;
    final sep = isWin ? '\\' : '/';
    // 正規化と結合
    final cleaned = parts
        .where((p) => p.isNotEmpty)
        .map((p) => p.replaceAll('\\', sep).replaceAll('/', sep))
        .toList();
    return cleaned.join(sep);
  }
}

