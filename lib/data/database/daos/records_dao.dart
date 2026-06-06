part of '../app_database.dart';

@DriftAccessor(tables: [Records])
class RecordsDao extends DatabaseAccessor<AppDatabase>
    with _$RecordsDaoMixin {
  RecordsDao(super.attachedDatabase);

  Future<void> insertRecords(List<RecordsCompanion> recordList) async {
    await batch((batch) {
      batch.insertAll(records, recordList);
    });
  }

  Future<List<Record>> getRecordsBySectionId(int sectionId) =>
      (select(records)
            ..where((t) => t.sectionId.equals(sectionId))
            ..orderBy([(t) => OrderingTerm.asc(t.rowIndex)]))
          .get();

  Future<Record?> getRecordById(int id) =>
      (select(records)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<void> deleteRecordsBySectionId(int sectionId) =>
      (delete(records)..where((t) => t.sectionId.equals(sectionId))).go();

  Stream<List<Record>> watchRecordsBySectionId(int sectionId) {
    return (select(records)
          ..where((t) => t.sectionId.equals(sectionId))
          ..orderBy([(t) => OrderingTerm.asc(t.rowIndex)]))
        .watch();
  }
}
