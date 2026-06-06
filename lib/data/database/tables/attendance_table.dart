import 'package:drift/drift.dart';
import 'sessions_table.dart';
import 'records_table.dart';

class Attendance extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get sessionId => integer().references(Sessions, #id)();
  IntColumn get recordId => integer().references(Records, #id)();
  BoolColumn get isPresent => boolean().withDefault(const Constant(true))();
  DateTimeColumn get markedAt => dateTime()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {sessionId, recordId},
      ];
}
