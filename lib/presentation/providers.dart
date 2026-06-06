import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../data/database/app_database.dart';
import '../data/repositories/section_repository.dart';
import '../data/repositories/record_repository.dart';
import '../data/repositories/session_repository.dart';
import '../domain/excel_exporter.dart';
import '../domain/excel_parser.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final sectionRepositoryProvider = Provider<SectionRepository>((ref) {
  return SectionRepository(ref.watch(appDatabaseProvider));
});

final recordRepositoryProvider = Provider<RecordRepository>((ref) {
  return RecordRepository(ref.watch(appDatabaseProvider));
});

final sessionRepositoryProvider = Provider<SessionRepository>((ref) {
  return SessionRepository(ref.watch(appDatabaseProvider));
});

final excelParserProvider = Provider<ExcelParser>((ref) {
  return ExcelParser();
});

final excelExporterProvider = Provider<ExcelExporter>((ref) {
  return ExcelExporter(ref.watch(appDatabaseProvider));
});

final sectionsProvider = StreamProvider<List<Section>>((ref) {
  return ref.watch(sectionRepositoryProvider).watchAllSections();
});

final searchQueryProvider =
    StateProvider.family<String, int>((ref, sectionId) => '');

final sectionProvider =
    FutureProvider.family<Section?, int>((ref, sectionId) {
  return ref.watch(sectionRepositoryProvider).getSection(sectionId);
});

final recordsProvider =
    StreamProvider.family<List<Record>, int>((ref, sectionId) {
  return ref.watch(recordRepositoryProvider).watchRecords(sectionId);
});

final filteredRecordsProvider =
    Provider.family<List<Record>, int>((ref, sectionId) {
  final records = ref.watch(recordsProvider(sectionId)).valueOrNull ?? [];
  final query = ref.watch(searchQueryProvider(sectionId));
  final section = ref.watch(sectionProvider(sectionId)).valueOrNull;
  if (query.isEmpty || section == null) return records;

  final columnNames = List<String>.from(
      jsonDecode(section.columnNames) as List);
  final primaryCol = columnNames[section.primaryColumnIndex];

  return records.where((r) {
    final data = jsonDecode(r.data) as Map<String, dynamic>;
    final value = (data[primaryCol] ?? '').toString().toLowerCase();
    return value.contains(query.toLowerCase());
  }).toList();
});

final sessionProvider =
    FutureProvider.family<Session?, int>((ref, sessionId) {
  return ref.watch(sessionRepositoryProvider).getSession(sessionId);
});

final sessionsProvider =
    StreamProvider.family<List<Session>, int>((ref, sectionId) {
  return ref.watch(sessionRepositoryProvider).watchSessions(sectionId);
});

class SessionAttendanceNotifier
    extends StateNotifier<Map<int, bool>> {
  final int sessionId;
  final Ref _ref;

  SessionAttendanceNotifier(this.sessionId, this._ref) : super({}) {
    _loadInitialState();
  }

  Future<void> _loadInitialState() async {
    final map = await _ref
        .read(sessionRepositoryProvider)
        .getAttendanceMap(sessionId);
    state = map;
  }

  Future<void> toggle(int recordId) async {
    final current = state[recordId] ?? true;
    final newValue = !current;
    state = {...state, recordId: newValue};
    try {
      await _ref.read(sessionRepositoryProvider).upsertAttendance(
            AttendanceCompanion(
              sessionId: Value(sessionId),
              recordId: Value(recordId),
              isPresent: Value(newValue),
              markedAt: Value(DateTime.now()),
            ),
          );
    } catch (e) {
      state = {...state, recordId: current};
      rethrow;
    }
  }

  int get presentCount => state.values.where((v) => v).length;
  int get absentCount => state.values.where((v) => !v).length;
}

final sessionAttendanceProvider = StateNotifierProvider.family<
    SessionAttendanceNotifier, Map<int, bool>, int>(
  (ref, sessionId) => SessionAttendanceNotifier(sessionId, ref),
);
