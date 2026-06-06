import 'dart:convert';
import '../database/app_database.dart';

class RecordRepository {
  final AppDatabase _db;

  RecordRepository(this._db);

  Future<void> insertRecords(List<RecordsCompanion> records) =>
      _db.recordsDao.insertRecords(records);

  Future<List<Record>> getRecords(int sectionId) =>
      _db.recordsDao.getRecordsBySectionId(sectionId);

  Stream<List<Record>> watchRecords(int sectionId) =>
      _db.recordsDao.watchRecordsBySectionId(sectionId);

  Future<Record?> getRecord(int id) => _db.recordsDao.getRecordById(id);

  Map<String, String> getRecordData(Record record) {
    final decoded = jsonDecode(record.data);
    return Map<String, String>.from(decoded);
  }
}
