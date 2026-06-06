import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:drift/drift.dart' hide Column;
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../data/models/parsed_excel_model.dart';
import '../../data/database/app_database.dart';
import '../providers.dart';
import '../shared/loading_overlay.dart';
import '../shared/error_dialog.dart';

class ColumnSelectionScreen extends ConsumerStatefulWidget {
  final ParsedExcelModel parsedExcel;

  const ColumnSelectionScreen({super.key, required this.parsedExcel});

  @override
  ConsumerState<ColumnSelectionScreen> createState() =>
      _ColumnSelectionScreenState();
}

class _ColumnSelectionScreenState
    extends ConsumerState<ColumnSelectionScreen> {
  int? _primaryIndex;
  int? _secondaryIndex;
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    final baseName = widget.parsedExcel.originalFileName
        .replaceAll('.xlsx', '')
        .replaceAll('.XLSX', '');
    _nameController = TextEditingController(text: baseName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  bool get _canCreate =>
      _primaryIndex != null && _nameController.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final columns = widget.parsedExcel.columnNames;

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Select Display Columns'),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppDimensions.paddingM),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Primary Column *',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'This is the main identifier shown on each record card (e.g. Student Name)',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...List.generate(columns.length, (i) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _primaryIndex = i);
                            if (_secondaryIndex == i) {
                              setState(() => _secondaryIndex = null);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: _primaryIndex == i
                                  ? AppColors.navy
                                  : CupertinoColors.white,
                              borderRadius:
                                  BorderRadius.circular(AppDimensions.buttonRadius),
                              border: Border.all(
                                color: _primaryIndex == i
                                    ? AppColors.navy
                                    : AppColors.border,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _primaryIndex == i
                                      ? CupertinoIcons.checkmark_circle_fill
                                      : CupertinoIcons.circle,
                                  size: 20,
                                  color: _primaryIndex == i
                                      ? CupertinoColors.white
                                      : AppColors.textMuted,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    columns[i],
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: _primaryIndex == i
                                          ? CupertinoColors.white
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 28),
                    const Text(
                      'Secondary Column (optional)',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Shown as a subtitle on each record card',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () => setState(() => _secondaryIndex = null),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: _secondaryIndex == null
                              ? AppColors.navy
                              : CupertinoColors.white,
                          borderRadius:
                              BorderRadius.circular(AppDimensions.buttonRadius),
                          border: Border.all(
                            color: _secondaryIndex == null
                                ? AppColors.navy
                                : AppColors.border,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _secondaryIndex == null
                                  ? CupertinoIcons.checkmark_circle_fill
                                  : CupertinoIcons.circle,
                              size: 20,
                              color: _secondaryIndex == null
                                  ? CupertinoColors.white
                                  : AppColors.textMuted,
                            ),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text(
                                'None',
                                style: TextStyle(fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    ...List.generate(columns.length, (i) {
                      if (_primaryIndex == i) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: GestureDetector(
                          onTap: () => setState(() => _secondaryIndex = i),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: _secondaryIndex == i
                                  ? AppColors.navy
                                  : CupertinoColors.white,
                              borderRadius: BorderRadius.circular(
                                  AppDimensions.buttonRadius),
                              border: Border.all(
                                color: _secondaryIndex == i
                                    ? AppColors.navy
                                    : AppColors.border,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _secondaryIndex == i
                                      ? CupertinoIcons.checkmark_circle_fill
                                      : CupertinoIcons.circle,
                                  size: 20,
                                  color: _secondaryIndex == i
                                      ? CupertinoColors.white
                                      : AppColors.textMuted,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    columns[i],
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: _secondaryIndex == i
                                          ? CupertinoColors.white
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 28),
                    const Text(
                      'Section Name',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    CupertinoTextField(
                      controller: _nameController,
                      placeholder: 'Enter section name',
                      maxLength: 255,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: CupertinoColors.white,
                        borderRadius:
                            BorderRadius.circular(AppDimensions.buttonRadius),
                        border: Border.all(color: AppColors.border),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(AppDimensions.paddingM),
              decoration: const BoxDecoration(
                color: CupertinoColors.systemBackground,
                border: Border(
                  top: BorderSide(color: AppColors.border),
                ),
              ),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: CupertinoButton.filled(
                    onPressed: _canCreate ? () => _createSection() : null,
                    child: const Text('Create Section'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createSection() async {
    final name = _nameController.text.trim();
    if (name.isEmpty || _primaryIndex == null) return;

    LoadingOverlay.show(context);

    try {
      final db = ref.read(appDatabaseProvider);

      final sectionId = await db.transaction<int>(() async {
        final now = DateTime.now();
        final effectiveCols = widget.parsedExcel.columnNames;
        final effectiveRows = widget.parsedExcel.rows;
        final id = await db.sectionsDao.insertSection(
          SectionsCompanion(
            name: Value(name),
            fileName: Value(widget.parsedExcel.originalFileName),
            columnNames: Value(jsonEncode(effectiveCols)),
            primaryColumnIndex: Value(_primaryIndex!),
            secondaryColumnIndex: Value(_secondaryIndex),
            totalRecords: Value(widget.parsedExcel.totalRows),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );

        final recordCompanions = <RecordsCompanion>[];
        for (var i = 0; i < effectiveRows.length; i++) {
          recordCompanions.add(
            RecordsCompanion(
              sectionId: Value(id),
              rowIndex: Value(i),
              data: Value(jsonEncode(effectiveRows[i])),
              createdAt: Value(now),
            ),
          );
        }

        await db.recordsDao.insertRecords(recordCompanions);
        return id;
      });

      LoadingOverlay.hide(context);

      if (!mounted) return;

      ref.invalidate(sectionsProvider);
      context.go('/');
      context.push('/section/$sectionId');
    } catch (e) {
      LoadingOverlay.hide(context);
      if (!mounted) return;
      ErrorDialog.show(
        context,
        message: 'Failed to create section: $e',
      );
    }
  }
}
