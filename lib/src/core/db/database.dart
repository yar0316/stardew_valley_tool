import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'database.g.dart';

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'app.sqlite'));
    final db = NativeDatabase.createInBackground(file);
    return db;
  });
}

@DriftDatabase(tables: [])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await customStatement('PRAGMA foreign_keys=ON;');
      // Initialize schema and seed data from bundled SQL
      final sql = await rootBundle.loadString('data/sql/zz_all_in_one.sql');
      for (final stmt in _splitSqlStatements(sql)) {
        if (stmt.trim().isEmpty) continue;
        await customStatement(stmt);
      }
    },
    onUpgrade: (m, from, to) async {
      // handle migrations if schemaVersion increases in the future
    },
  );

  List<String> _splitSqlStatements(String sql) {
    // Naive split on semicolons at line ends; keeps comments ignored
    final lines = sql.split('\n');
    final buf = StringBuffer();
    final statements = <String>[];
    for (var line in lines) {
      final trimmed = line.trimRight();
      if (trimmed.startsWith('--')) continue; // ignore comment lines
      buf.writeln(trimmed);
      if (trimmed.endsWith(';')) {
        statements.add(buf.toString());
        buf.clear();
      }
    }
    final rest = buf.toString().trim();
    if (rest.isNotEmpty) statements.add(rest);
    return statements;
  }
}

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});
