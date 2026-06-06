import 'dart:convert';
import '../database/app_database.dart';

class SectionRepository {
  final AppDatabase _db;

  SectionRepository(this._db);

  Future<int> createSection(SectionsCompanion section) =>
      _db.sectionsDao.insertSection(section);

  Future<List<Section>> getAllSections() => _db.sectionsDao.getAllSections();

  Stream<List<Section>> watchAllSections() => _db.sectionsDao.watchAllSections();

  Future<Section?> getSection(int id) => _db.sectionsDao.getSectionById(id);

  Future<void> updateSection(SectionsCompanion section) =>
      _db.sectionsDao.updateSection(section);

  Future<void> deleteSection(int id) => _db.sectionsDao.deleteSection(id);

  Future<void> updateSectionTimestamp(int id) =>
      _db.sectionsDao.updateSectionTimestamp(id);

  List<String> getColumnNames(Section section) {
    final decoded = jsonDecode(section.columnNames);
    return List<String>.from(decoded);
  }
}
