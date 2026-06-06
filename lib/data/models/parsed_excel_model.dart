import '../../core/utils/excel_column_namer.dart';

class ParsedExcelModel {
  final String originalFileName;
  final List<String> columnNames;
  final bool hadNoHeader;
  final List<Map<String, String>> rows;
  final int totalRows;
  final int totalColumns;
  final List<Map<String, String>> sampleRows;
  final List<String> warnings;

  ParsedExcelModel({
    required this.originalFileName,
    required this.columnNames,
    required this.hadNoHeader,
    required this.rows,
    required this.totalRows,
    required this.totalColumns,
    required this.sampleRows,
    required this.warnings,
  });

  ParsedExcelModel copyWithForceNoHeader() {
    if (hadNoHeader) return this;
    final newCols =
        ExcelColumnNamer.autoGenerate(totalColumns);

    final headerAsRow = <String, String>{};
    for (var i = 0; i < columnNames.length; i++) {
      headerAsRow[newCols[i]] = columnNames[i];
    }

    final rekeyedRows = <Map<String, String>>[];
    for (final row in rows) {
      final newRow = <String, String>{};
      for (var i = 0; i < columnNames.length; i++) {
        newRow[newCols[i]] = row[columnNames[i]] ?? '';
      }
      rekeyedRows.add(newRow);
    }

    return ParsedExcelModel(
      originalFileName: originalFileName,
      columnNames: newCols,
      hadNoHeader: true,
      rows: [headerAsRow, ...rekeyedRows],
      totalRows: totalRows + 1,
      totalColumns: totalColumns,
      sampleRows: [headerAsRow, ...rekeyedRows.take(3)],
      warnings: [
        ...warnings,
        'First row treated as data. Column names auto-generated.',
      ],
    );
  }
}
