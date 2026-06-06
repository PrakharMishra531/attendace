import '../database/app_database.dart';

class SessionRepository {
  final AppDatabase _db;

  SessionRepository(this._db);

  Future<int> createSession(SessionsCompanion session) =>
      _db.sessionsDao.insertSession(session);

  Future<List<Session>> getSessions(int sectionId) =>
      _db.sessionsDao.getSessionsBySectionId(sectionId);

  Stream<List<Session>> watchSessions(int sectionId) =>
      _db.sessionsDao.watchSessionsBySectionId(sectionId);

  Future<Session?> getSession(int id) => _db.sessionsDao.getSessionById(id);

  Future<Session?> getDraftSession(int sectionId) =>
      _db.sessionsDao.getDraftSessionBySectionId(sectionId);

  Future<void> updateSession(SessionsCompanion session) =>
      _db.sessionsDao.updateSession(session);

  Future<void> deleteSession(int id) => _db.sessionsDao.deleteSession(id);

  Future<void> confirmSession(int id, int presentCount, int absentCount) =>
      _db.sessionsDao.confirmSession(id, presentCount, absentCount);

  Future<void> updateSessionCounts(
          int id, int presentCount, int absentCount) =>
      _db.sessionsDao.updateSessionCounts(id, presentCount, absentCount);

  Future<void> initializeAttendance(int sessionId, List<int> recordIds) =>
      _db.attendanceDao.initializeAttendanceForSession(sessionId, recordIds);

  Future<void> upsertAttendance(AttendanceCompanion entry) =>
      _db.attendanceDao.upsertAttendance(entry);

  Future<Map<int, bool>> getAttendanceMap(int sessionId) =>
      _db.attendanceDao.getAttendanceMapForSession(sessionId);

  Future<List<AttendanceData>> getAttendance(int sessionId) =>
      _db.attendanceDao.getAttendanceBySessionId(sessionId);
}
