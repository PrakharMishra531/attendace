part of '../app_database.dart';

@DriftAccessor(tables: [Sections, Records, Sessions, Attendance])
class SectionsDao extends DatabaseAccessor<AppDatabase>
    with _$SectionsDaoMixin {
  SectionsDao(super.attachedDatabase);

  Future<int> insertSection(SectionsCompanion section) =>
      into(sections).insert(section);

  Future<List<Section>> getAllSections() => select(sections).get();

  Future<Section?> getSectionById(int id) =>
      (select(sections)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<void> updateSection(SectionsCompanion section) =>
      update(sections).replace(section);

  Future<void> deleteSection(int id) async {
    final recordIds = await (select(records)
          ..where((t) => t.sectionId.equals(id)))
        .map((r) => r.id)
        .get();

    if (recordIds.isNotEmpty) {
      await (delete(attendance)
            ..where((t) => t.recordId.isIn(recordIds)))
          .go();
    }

    await (delete(sessions)..where((t) => t.sectionId.equals(id))).go();
    await (delete(records)..where((t) => t.sectionId.equals(id))).go();
    await (delete(sections)..where((t) => t.id.equals(id))).go();
  }

  Future<void> updateSectionTimestamp(int id) =>
      (update(sections)..where((t) => t.id.equals(id)))
          .write(SectionsCompanion(updatedAt: Value(DateTime.now())));

  Stream<List<Section>> watchAllSections() {
    return (select(sections)
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .watch();
  }
}
