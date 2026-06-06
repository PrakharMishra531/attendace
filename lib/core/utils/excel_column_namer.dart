class ExcelColumnNamer {
  static List<String> autoGenerate(int count) {
    return List.generate(count, (i) => 'Column ${i + 1}');
  }

  static List<String> deduplicate(List<String> names) {
    final seen = <String, int>{};
    final result = <String>[];
    for (final name in names) {
      if (seen.containsKey(name)) {
        seen[name] = seen[name]! + 1;
        result.add('${name}_${seen[name]}');
      } else {
        seen[name] = 0;
        result.add(name);
      }
    }
    return result;
  }
}
