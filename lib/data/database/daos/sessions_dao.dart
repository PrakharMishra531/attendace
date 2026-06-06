part of '../app_database.dart';

@DriftAccessor(tables: [Sessions, Attendance])
class SessionsDao extends DatabaseAccessor<AppDatabase>
    with _$SessionsDaoMixin {
  SessionsDao(super.attachedDatabase);

  Future<int> insertSession(SessionsCompanion session) =>
      into(sessions).insert(session);

  Future<List<Session>> getSessionsBySectionId(int sectionId) =>
      (select(sessions)
            ..where((t) => t.sectionId.equals(sectionId))
            ..orderBy([(t) => OrderingTerm.desc(t.sessionDate)]))
          .get();

  Future<Session?> getSessionById(int id) =>
      (select(sessions)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<Session?> getDraftSessionBySectionId(int sectionId) =>
      (select(sessions)
            ..where((t) =>
                t.sectionId.equals(sectionId) & t.status.equals('draft'))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .getSingleOrNull();

  Future<void> updateSession(SessionsCompanion session) =>
      update(sessions).replace(session);

  Future<void> deleteSession(int id) async {
    await (delete(attendance)..where((t) => t.sessionId.equals(id))).go();
    await (delete(sessions)..where((t) => t.id.equals(id))).go();
  }

  Future<void> confirmSession(
      int id, int presentCount, int absentCount) async {
    await (update(sessions)..where((t) => t.id.equals(id))).write(
      SessionsCompanion(
        status: const Value('confirmed'),
        presentCount: Value(presentCount),
        absentCount: Value(absentCount),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> updateSessionCounts(
      int id, int presentCount, int absentCount) async {
    await (update(sessions)..where((t) => t.id.equals(id))).write(
      SessionsCompanion(
        presentCount: Value(presentCount),
        absentCount: Value(absentCount),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Stream<List<Session>> watchSessionsBySectionId(int sectionId) {
    return (select(sessions)
          ..where((t) => t.sectionId.equals(sectionId))
          ..orderBy([(t) => OrderingTerm.desc(t.sessionDate)]))
        .watch();
  }
}
