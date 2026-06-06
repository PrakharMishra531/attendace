import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:drift/drift.dart' hide Column;
import 'dart:io';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/errors/app_exceptions.dart';
import '../../data/database/app_database.dart';
import '../providers.dart';
import '../shared/error_dialog.dart';
import '../shared/confirmation_dialog.dart';
import '../shared/loading_overlay.dart';
import '../import/import_summary_dialog.dart';
import 'widgets/section_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sectionsAsync = ref.watch(sectionsProvider);

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('AttendAce'),
        backgroundColor: CupertinoColors.systemBackground,
      ),
      child: SafeArea(
        child: sectionsAsync.when(
          data: (sections) {
            if (sections.isEmpty) {
              return _buildEmptyState(context, ref);
            }
            return _buildSectionList(context, ref, sections);
          },
          loading: () => const Center(
            child: CupertinoActivityIndicator(),
          ),
          error: (error, stack) => Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(CupertinoIcons.exclamationmark_circle,
                      size: 48, color: AppColors.error),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load sections',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  CupertinoButton.filled(
                    onPressed: () => ref.invalidate(sectionsProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(40),
              ),
              child: const Icon(
                CupertinoIcons.doc_text,
                size: 36,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No sections yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tap + to import your first sheet',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 32),
            CupertinoButton.filled(
              onPressed: () => _importFile(context, ref),
              child: const Text('Import Excel File'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionList(
      BuildContext context, WidgetRef ref, List<Section> sections) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.paddingM,
              vertical: AppDimensions.paddingS,
            ),
            itemCount: sections.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: AppDimensions.paddingS),
                child: SectionCard(
                  section: sections[index],
                  onTap: () => _openSection(context, sections[index]),
                  onRename: () => _renameSection(context, ref, sections[index]),
                  onDelete: () =>
                      _deleteSection(context, ref, sections[index]),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(
            right: AppDimensions.paddingM,
            bottom: AppDimensions.paddingM,
          ),
          child: Align(
            alignment: Alignment.bottomRight,
            child: CupertinoButton.filled(
              onPressed: () => _importFile(context, ref),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(CupertinoIcons.add, size: 20),
                  SizedBox(width: 6),
                  Text('New Section'),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _openSection(BuildContext context, Section section) {
    context.push('/section/${section.id}');
  }

  Future<void> _importFile(BuildContext context, WidgetRef ref) async {
    try {
      debugPrint('[IMPORT] Starting file picker...');
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );

      if (result == null || result.files.isEmpty) {
        debugPrint('[IMPORT] No file picked');
        return;
      }

      final filePath = result.files.single.path;
      debugPrint('[IMPORT] File path: $filePath, size: ${result.files.single.size}, name: ${result.files.single.name}');

      final parser = ref.read(excelParserProvider);
      debugPrint('[IMPORT] Parser obtained, starting parse...');

      final parsed;
      if (filePath != null) {
        debugPrint('[IMPORT] Parsing from file path...');
        parsed = parser.parse(File(filePath));
      } else {
        final bytes = result.files.single.bytes;
        debugPrint('[IMPORT] Parsing from bytes, byteCount: ${bytes?.length}');
        if (bytes == null) return;
        parsed = parser.parseBytes(bytes, result.files.single.name);
      }

      debugPrint('[IMPORT] Parse success: ${parsed.totalRows} rows, ${parsed.totalColumns} cols');

      if (!context.mounted) return;

      debugPrint('[IMPORT] Showing summary dialog...');
      final parsedResult = await ImportSummaryDialog.show(context, parsed);
      debugPrint('[IMPORT] Summary dialog result: $parsedResult');
      if (parsedResult == null || !context.mounted) return;

      debugPrint('[IMPORT] Navigating to column selection...');
      context.push('/import/columns', extra: parsedResult);
    } on ExcelParseException catch (e) {
      debugPrint('[IMPORT] ExcelParseException: ${e.message}');
      if (!context.mounted) return;
      ErrorDialog.show(
        context,
        message: e.message,
        buttonLabel: 'Try Another File',
      );
    } catch (e, stack) {
      debugPrint('[IMPORT] UNEXPECTED ERROR: $e');
      debugPrint('[IMPORT] STACK: $stack');
      if (!context.mounted) return;
      ErrorDialog.show(
        context,
        message: 'Error: $e',
      );
    }
  }

  Future<void> _renameSection(
      BuildContext context, WidgetRef ref, Section section) async {
    final controller = TextEditingController(text: section.name);
    await showCupertinoModalPopup(
      context: context,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: CupertinoColors.systemBackground,
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Rename Section',
                style: TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              CupertinoTextField(
                controller: controller,
                placeholder: 'Section name',
                autofocus: true,
                maxLength: 255,
              ),
              const SizedBox(height: 16),
              CupertinoButton.filled(
                onPressed: () async {
                  final newName = controller.text.trim();
                  if (newName.isEmpty) return;
                  await ref
                      .read(sectionRepositoryProvider)
                      .updateSection(
                        SectionsCompanion(
                          id: Value(section.id),
                          name: Value(newName),
                          fileName: Value(section.fileName),
                          columnNames:
                              Value(section.columnNames),
                          primaryColumnIndex:
                              Value(section.primaryColumnIndex),
                          secondaryColumnIndex: Value(
                              section.secondaryColumnIndex),
                          totalRecords:
                              Value(section.totalRecords),
                          createdAt: Value(section.createdAt),
                          updatedAt: Value(DateTime.now()),
                        ),
                      );
                  ref.invalidate(sectionsProvider);
                  if (ctx.mounted) Navigator.of(ctx).pop();
                },
                child: const Text('Save'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );

  }

  Future<void> _deleteSection(
      BuildContext context, WidgetRef ref, Section section) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Delete Section',
      message:
          "Delete '${section.name}'? This will permanently delete all "
          '${section.totalRecords} records and attendance sessions. '
          'This cannot be undone.',
      confirmLabel: 'Delete',
      isDestructive: true,
      secondaryLabel: 'Export First',
      onSecondary: () async {
        try {
          LoadingOverlay.show(context);
          await ref
              .read(excelExporterProvider)
              .exportSection(section);
          LoadingOverlay.hide(context);
          if (!context.mounted) return;
          showCupertinoDialog(
            context: context,
            builder: (_) => CupertinoAlertDialog(
              title: const Text('Exported'),
              content: const Text(
                  'File saved to Downloads folder.'),
              actions: [
                CupertinoDialogAction(
                  onPressed: () =>
                      Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        } on Exception catch (e) {
          LoadingOverlay.hide(context);
          if (!context.mounted) return;
          ErrorDialog.show(context,
              message: e.toString());
        }
      },
    );

    if (confirmed == true) {
      await ref
          .read(sectionRepositoryProvider)
          .deleteSection(section.id);
      ref.invalidate(sectionsProvider);
    }
  }
}
