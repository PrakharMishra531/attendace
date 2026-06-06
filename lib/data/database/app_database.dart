import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';

import 'tables/sections_table.dart';
import 'tables/records_table.dart';
import 'tables/sessions_table.dart';
import 'tables/attendance_table.dart';

part 'app_database.g.dart';

part 'daos/sections_dao.dart';
part 'daos/records_dao.dart';
part 'daos/sessions_dao.dart';
part 'daos/attendance_dao.dart';

@DriftDatabase(
  tables: [Sections, Records, Sessions, Attendance],
  daos: [SectionsDao, RecordsDao, SessionsDao, AttendanceDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        onUpgrade: (m, from, to) async {},
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
          await customStatement('PRAGMA journal_mode = WAL');
        },
      );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'attendance.db'));
    return NativeDatabase.createInBackground(file);
  });
}
