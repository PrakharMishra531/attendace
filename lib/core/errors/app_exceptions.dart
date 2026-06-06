class ExcelParseException implements Exception {
  final String message;
  final String? detail;
  ExcelParseException(this.message, {this.detail});

  @override
  String toString() => 'ExcelParseException: $message${detail != null ? ' - $detail' : ''}';
}

class DatabaseException implements Exception {
  final String message;
  final Object? cause;
  DatabaseException(this.message, {this.cause});

  @override
  String toString() => 'DatabaseException: $message';
}

class ExportException implements Exception {
  final String message;
  ExportException(this.message);

  @override
  String toString() => 'ExportException: $message';
}

class StoragePermissionException implements Exception {
  @override
  String toString() => 'StoragePermissionException';
}
