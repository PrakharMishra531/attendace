import 'dart:io';
import 'package:excel/excel.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import '../core/errors/app_exceptions.dart';
import '../core/utils/date_formatter.dart';
import '../data/database/app_database.dart';

class ExcelExporter {
  final AppDatabase _db;

  ExcelExporter(this._db);

  Future<String> exportSection(Section section) async {
    final records = await _db.recordsDao.getRecordsBySectionId(section.id);

    final allSessions =
        await _db.sessionsDao.getSessionsBySectionId(section.id);
    final confirmedSessions =
        allSessions.where((s) => s.status == 'confirmed').toList();

    if (confirmedSessions.isEmpty) {
      throw ExportException('No confirmed sessions to export yet.');
    }

    confirmedSessions.sort((a, b) => a.sessionDate.compareTo(b.sessionDate));

    final columnNames =
        List<String>.from(jsonDecode(section.columnNames) as List);

    final sessionDateGroups = <String, List<Session>>{};
    for (final session in confirmedSessions) {
      final dateKey = DateFormatter.formatDateShort(session.sessionDate);
      sessionDateGroups.putIfAbsent(dateKey, () => []).add(session);
    }

    final sessionHeaders = <String>[];
    final sessionOrder = <Session>[];
    final dateSessionCounters = <String, int>{};
    for (final session in confirmedSessions) {
      final dateKey = DateFormatter.formatDateShort(session.sessionDate);
      final sessionsOnSameDate = sessionDateGroups[dateKey]!;
      String header;
      if (sessionsOnSameDate.length == 1) {
        header = dateKey;
      } else {
        dateSessionCounters[dateKey] =
            (dateSessionCounters[dateKey] ?? 0) + 1;
        final counter = dateSessionCounters[dateKey]!;
        if (session.tag != null && session.tag!.isNotEmpty) {
          header = '$dateKey (${session.tag})';
        } else {
          header = '$dateKey (Session $counter)';
        }
      }
      sessionHeaders.add(header);
      sessionOrder.add(session);
    }

    final excel = Excel.createExcel();
    final sheet = excel['Attendance'];

    final headerStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('FF0D1B2A'),
      fontColorHex: ExcelColor.white,
      horizontalAlign: HorizontalAlign.Center,
    );

    for (var i = 0; i < columnNames.length; i++) {
      final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = TextCellValue(columnNames[i]);
      cell.cellStyle = headerStyle;
    }

    for (var j = 0; j < sessionOrder.length; j++) {
      final col = columnNames.length + j;
      final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0));
      cell.value = TextCellValue(sessionHeaders[j]);
      cell.cellStyle = headerStyle;
    }

    final attendanceMaps = <int, Map<int, bool>>{};
    for (final session in sessionOrder) {
      attendanceMaps[session.id] =
          await _db.attendanceDao.getAttendanceMapForSession(session.id);
    }

    for (var rowIdx = 0; rowIdx < records.length; rowIdx++) {
      final record = records[rowIdx];
      final recordData = Map<String, String>.from(jsonDecode(record.data));

      for (var i = 0; i < columnNames.length; i++) {
        final cell = sheet.cell(
            CellIndex.indexByColumnRow(columnIndex: i, rowIndex: rowIdx + 1));
        cell.value = TextCellValue(recordData[columnNames[i]] ?? '');
      }

      for (var j = 0; j < sessionOrder.length; j++) {
        final session = sessionOrder[j];
        final col = columnNames.length + j;
        final cell = sheet.cell(
            CellIndex.indexByColumnRow(columnIndex: col, rowIndex: rowIdx + 1));
        final attMap = attendanceMaps[session.id]!;
        final isPresent = attMap[record.id];

        if (isPresent == null) {
          cell.value = TextCellValue('-');
        } else if (isPresent) {
          cell.value = TextCellValue('P');
          cell.cellStyle = CellStyle(
            backgroundColorHex: ExcelColor.fromHexString('FF2E7D32'),
            fontColorHex: ExcelColor.white,
            horizontalAlign: HorizontalAlign.Center,
          );
        } else {
          cell.value = TextCellValue('A');
          cell.cellStyle = CellStyle(
            backgroundColorHex: ExcelColor.fromHexString('FFC62828'),
            fontColorHex: ExcelColor.white,
            horizontalAlign: HorizontalAlign.Center,
          );
        }
      }
    }

    final sanitizedName = section.name
        .replaceAll(' ', '_')
        .replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '');
    final dateStr = DateFormatter.formatDateForExport(DateTime.now());
    final filename = 'export_${sanitizedName}_$dateStr.xlsx';

    final fileBytes = excel.encode()!;

    if (Platform.isAndroid) {
      final dir = Directory('/storage/emulated/0/Download');
      if (!await dir.exists()) {
        throw ExportException('Downloads directory not accessible.');
      }
      final file = File('${dir.path}/$filename');
      await file.writeAsBytes(fileBytes);
    } else {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$filename');
      await file.writeAsBytes(fileBytes);
      await Share.shareXFiles([XFile(file.path)], text: 'Attendance Export');
    }

    return filename;
  }
}
