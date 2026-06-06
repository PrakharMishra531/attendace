import 'package:drift/drift.dart';

class Sections extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 255)();
  TextColumn get fileName => text()();
  TextColumn get columnNames => text()();
  IntColumn get primaryColumnIndex => integer()();
  IntColumn get secondaryColumnIndex => integer().nullable()();
  IntColumn get totalRecords => integer()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}
