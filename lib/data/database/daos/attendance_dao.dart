part of '../app_database.dart';

@DriftAccessor(tables: [Attendance])
class AttendanceDao extends DatabaseAccessor<AppDatabase>
    with _$AttendanceDaoMixin {
  AttendanceDao(super.attachedDatabase);

  Future<void> upsertAttendance(AttendanceCompanion entry) {
    return into(attendance).insert(
      entry,
      onConflict: DoUpdate(
        (old) => AttendanceCompanion(
          isPresent: Value(entry.isPresent.value),
          markedAt: Value(DateTime.now()),
        ),
        target: [attendance.sessionId, attendance.recordId],
      ),
    );
  }

  Future<List<AttendanceData>> getAttendanceBySessionId(int sessionId) =>
      (select(attendance)..where((t) => t.sessionId.equals(sessionId))).get();

  Future<void> deleteAttendanceBySessionId(int sessionId) =>
      (delete(attendance)..where((t) => t.sessionId.equals(sessionId))).go();

  Future<Map<int, bool>> getAttendanceMapForSession(int sessionId) async {
    final rows = await (select(attendance)
          ..where((t) => t.sessionId.equals(sessionId)))
        .get();
    return {for (final r in rows) r.recordId: r.isPresent};
  }

  Future<void> initializeAttendanceForSession(
      int sessionId, List<int> recordIds) async {
    final now = DateTime.now();
    await batch((batch) {
      for (final recordId in recordIds) {
        batch.insert(
          attendance,
          AttendanceCompanion(
            sessionId: Value(sessionId),
            recordId: Value(recordId),
            isPresent: const Value(true),
            markedAt: Value(now),
          ),
        );
      }
    });
  }
}
