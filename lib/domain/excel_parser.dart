import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive.dart' as archive;
import 'package:xml/xml.dart';
import '../core/errors/app_exceptions.dart';
import '../core/utils/excel_column_namer.dart';
import '../data/models/parsed_excel_model.dart';

class ExcelParser {
  static final _numericRegex = RegExp(r'^-?\d+(\.\d+)?$');

  ParsedExcelModel parse(File file) {
    final fileName = file.path.split('/').last.split('\\').last;
    if (!fileName.toLowerCase().endsWith('.xlsx')) {
      throw ExcelParseException('Only .xlsx files are supported.');
    }
    final fileSize = file.lengthSync();
    if (fileSize > 10 * 1024 * 1024) {
      throw ExcelParseException('File size exceeds 10MB limit.');
    }
    return parseBytes(file.readAsBytesSync(), fileName);
  }

  ParsedExcelModel parseBytes(Uint8List bytes, String fileName) {
    if (bytes.length > 10 * 1024 * 1024) {
      throw ExcelParseException('File size exceeds 10MB limit.');
    }
    return _parseFromZip(bytes, fileName);
  }

  ParsedExcelModel _parseFromZip(Uint8List bytes, String fileName) {
    final warnings = <String>[];

    final zip = archive.ZipDecoder().decodeBytes(bytes);

    final sharedStrings = _readSharedStrings(zip);
    final sheetInfo = _readWorkbookSheets(zip);

    if (sheetInfo.isEmpty) {
      throw ExcelParseException('No sheets found in file.');
    }
    if (sheetInfo.length > 1) {
      throw ExcelParseException(
        'File has ${sheetInfo.length} sheets. '
        'Please provide a file with exactly one sheet.',
      );
    }

    final sheetName = sheetInfo.first;
    final rows = _readSheetRows(zip, sheetName, sharedStrings);

    if (rows.isEmpty) {
      throw ExcelParseException('The sheet is empty.');
    }

    final maxCols = rows.fold<int>(0, (m, r) => r.length > m ? r.length : m);

    final firstRowCells = List.generate(maxCols, (i) {
      if (i < rows[0].length) return rows[0][i];
      return '';
    });

    final allNumericOrEmpty = firstRowCells.every((cell) {
      if (cell.isEmpty) return true;
      return _numericRegex.hasMatch(cell);
    });

    List<String> columnNames;
    bool hadNoHeader;
    int dataStartRow;

    if (allNumericOrEmpty) {
      columnNames = ExcelColumnNamer.autoGenerate(maxCols);
      hadNoHeader = true;
      dataStartRow = 0;
      warnings.add(
        "No header row detected. Column names were auto-generated "
        "as 'Column 1', 'Column 2', etc.",
      );
    } else {
      for (var i = 0; i < maxCols; i++) {
        if (firstRowCells[i].isEmpty) {
          firstRowCells[i] = 'Column ${i + 1}';
          warnings.add('Column ${i + 1} was empty and auto-named.');
        }
      }
      columnNames = ExcelColumnNamer.deduplicate(firstRowCells);
      for (var i = 0; i < columnNames.length; i++) {
        if (columnNames[i] != firstRowCells[i] && firstRowCells[i].isNotEmpty) {
          warnings.add(
            'Column "${columnNames[i]}" was renamed to avoid duplication.',
          );
        }
      }
      hadNoHeader = false;
      dataStartRow = 1;
    }

    for (var i = 0; i < columnNames.length; i++) {
      columnNames[i] = columnNames[i].trim();
    }

    final parsedRows = <Map<String, String>>[];
    for (var r = dataStartRow; r < rows.length; r++) {
      final rowData = <String, String>{};
      for (var c = 0; c < maxCols; c++) {
        final colName = columnNames[c];
        rowData[colName] = c < rows[r].length ? rows[r][c] : '';
      }

      final allEmpty = rowData.values.every((v) => v.isEmpty);
      if (!allEmpty) {
        parsedRows.add(rowData);
      }
    }

    if (parsedRows.isEmpty) {
      throw ExcelParseException('No data rows found after the header row.');
    }

    final sampleRows = parsedRows.take(3).toList();

    return ParsedExcelModel(
      originalFileName: fileName,
      columnNames: columnNames,
      hadNoHeader: hadNoHeader,
      rows: parsedRows,
      totalRows: parsedRows.length,
      totalColumns: maxCols,
      sampleRows: sampleRows,
      warnings: warnings,
    );
  }

  List<String> _readSharedStrings(archive.Archive zip) {
    final ssFile = zip.findFile('xl/sharedStrings.xml');
    if (ssFile == null) return [];

    final content = utf8.decode(ssFile.content as List<int>);
    final doc = XmlDocument.parse(content);
    final strings = <String>[];
    for (final si in doc.findAllElements('si')) {
      final t = si.findAllElements('t').firstOrNull;
      if (t != null) {
        strings.add(t.innerText);
      } else {
        final rEls = si.findAllElements('r');
        final buf = StringBuffer();
        for (final r in rEls) {
          final rt = r.findAllElements('t').firstOrNull;
          if (rt != null) buf.write(rt.innerText);
        }
        strings.add(buf.toString());
      }
    }
    return strings;
  }

  List<String> _readWorkbookSheets(archive.Archive zip) {
    final wbFile = zip.findFile('xl/workbook.xml');
    if (wbFile == null) return [];

    final content = utf8.decode(wbFile.content as List<int>);
    final doc = XmlDocument.parse(content);
    final sheetNames = <String>[];
    for (final sheet in doc.findAllElements('sheet')) {
      final name = sheet.getAttribute('name');
      if (name != null) sheetNames.add(name);
    }
    return sheetNames;
  }

  List<List<String>> _readSheetRows(
    archive.Archive zip,
    String sheetName,
    List<String> sharedStrings,
  ) {
    final sheetFile = zip.findFile('xl/worksheets/sheet1.xml');
    if (sheetFile == null) return [];

    final content = utf8.decode(sheetFile.content as List<int>);
    final doc = XmlDocument.parse(content);

    final rows = <List<String>>[];
    for (final rowEl in doc.findAllElements('row')) {
      final rowData = <String>[];

      for (final cell in rowEl.findAllElements('c')) {
        final ref = cell.getAttribute('r') ?? '';
        final col = _columnLetterToIndex(ref);
        final type = cell.getAttribute('t');

        while (rowData.length <= col) {
          rowData.add('');
        }

        if (type == 's') {
          final v = cell.findAllElements('v').firstOrNull;
          if (v != null) {
            final idx = int.tryParse(v.innerText) ?? -1;
            if (idx >= 0 && idx < sharedStrings.length) {
              rowData[col] = sharedStrings[idx];
            }
          }
        } else if (type == 'b') {
          final v = cell.findAllElements('v').firstOrNull;
          rowData[col] = (v != null && v.innerText == '1') ? 'true' : 'false';
        } else if (type == 'inlineStr') {
          final isEl = cell.findAllElements('is').firstOrNull;
          if (isEl != null) {
            final t = isEl.findAllElements('t').firstOrNull;
            rowData[col] = t?.innerText ?? '';
          }
        } else if (type == 'str') {
          final v = cell.findAllElements('v').firstOrNull;
          rowData[col] = v?.innerText ?? '';
        } else {
          final v = cell.findAllElements('v').firstOrNull;
          rowData[col] = v?.innerText ?? '';
        }
      }

      if (rowData.any((c) => c.isNotEmpty)) {
        rows.add(rowData);
      }
    }

    if (rows.isEmpty) return [];

    final maxCols = rows.fold<int>(0, (m, r) => r.length > m ? r.length : m);
    for (final row in rows) {
      while (row.length < maxCols) {
        row.add('');
      }
    }

    return rows;
  }

  int _columnLetterToIndex(String ref) {
    final letters = ref.replaceAll(RegExp(r'[0-9]'), '');
    var col = 0;
    for (var i = 0; i < letters.length; i++) {
      col = col * 26 + (letters.codeUnitAt(i) - 'A'.codeUnitAt(0) + 1);
    }
    return col - 1;
  }
}
