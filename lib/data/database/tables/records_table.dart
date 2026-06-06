import 'package:drift/drift.dart';
import 'sections_table.dart';

class Records extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get sectionId => integer().references(Sections, #id)();
  IntColumn get rowIndex => integer()();
  TextColumn get data => text()();
  DateTimeColumn get createdAt => dateTime()();
}
