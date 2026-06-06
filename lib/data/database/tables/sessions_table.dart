import 'package:drift/drift.dart';
import 'sections_table.dart';

class Sessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get sectionId => integer().references(Sections, #id)();
  TextColumn get tag => text().nullable()();
  DateTimeColumn get sessionDate => dateTime()();
  TextColumn get status => text()();
  IntColumn get presentCount => integer().withDefault(const Constant(0))();
  IntColumn get absentCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}
