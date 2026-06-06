import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' hide Column;
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import 'package:go_router/go_router.dart';
import '../../core/errors/app_exceptions.dart';
import '../../data/database/app_database.dart';
import '../providers.dart';
import '../shared/confirmation_dialog.dart';
import '../shared/error_dialog.dart';
import '../shared/loading_overlay.dart';
import 'widgets/record_card.dart';
import 'widgets/session_history_card.dart';

class SectionScreen extends ConsumerStatefulWidget {
  final int sectionId;

  const SectionScreen({super.key, required this.sectionId});

  @override
  ConsumerState<SectionScreen> createState() => _SectionScreenState();
}

class _SectionScreenState extends ConsumerState<SectionScreen> {
  int _selectedTab = 0;
  final _searchController = TextEditingController();
  final _sectionNameController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    _sectionNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sectionAsync = ref.watch(sectionProvider(widget.sectionId));

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(
          sectionAsync.valueOrNull?.name ?? 'Section',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () => _exportSection(),
              child: const Icon(CupertinoIcons.share, size: 22),
            ),
            const SizedBox(width: 16),
            GestureDetector(
              onTap: () => _showMoreMenu(),
              child: const Icon(CupertinoIcons.ellipsis, size: 22),
            ),
          ],
        ),
      ),
      child: SafeArea(
        child: sectionAsync.when(
          data: (section) {
            if (section == null) {
              return const Center(child: Text('Section not found'));
            }
            return _buildContent(section);
          },
          loading: () => const Center(child: CupertinoActivityIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ),
    );
  }

  Widget _buildContent(Section section) {
    final columnNames =
        List<String>.from(jsonDecode(section.columnNames) as List);
    final primaryCol = columnNames[section.primaryColumnIndex];
    final secondaryCol = section.secondaryColumnIndex != null &&
            section.secondaryColumnIndex! < columnNames.length
        ? columnNames[section.secondaryColumnIndex!]
        : null;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.paddingM,
            vertical: AppDimensions.paddingS,
          ),
          child: CupertinoSlidingSegmentedControl<int>(
            groupValue: _selectedTab,
            children: const {
              0: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                child: Text('Records', style: TextStyle(fontSize: 14)),
              ),
              1: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                child: Text('Sessions', style: TextStyle(fontSize: 14)),
              ),
            },
            onValueChanged: (v) => setState(() => _selectedTab = v ?? 0),
          ),
        ),
        Expanded(
          child: _selectedTab == 0
              ? _buildRecordsTab(columnNames, primaryCol, secondaryCol)
              : _buildSessionsTab(),
        ),
      ],
    );
  }

  Widget _buildRecordsTab(
      List<String> columnNames, String primaryCol, String? secondaryCol) {
    final query = ref.watch(searchQueryProvider(widget.sectionId));
    final records = ref.watch(filteredRecordsProvider(widget.sectionId));
    final allRecords = ref.watch(recordsProvider(widget.sectionId));

    _searchController.text = query;
    _searchController.selection = TextSelection.fromPosition(
      TextPosition(offset: _searchController.text.length),
    );

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.paddingM,
            vertical: AppDimensions.paddingS,
          ),
          child: CupertinoTextField(
            controller: _searchController,
            placeholder: 'Search by $primaryCol...',
            prefix: const Padding(
              padding: EdgeInsets.only(left: 10),
              child: Icon(CupertinoIcons.search,
                  size: 18, color: AppColors.textMuted),
            ),
            suffix: query.isNotEmpty
                ? Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: GestureDetector(
                      onTap: () {
                        _searchController.clear();
                        ref
                            .read(searchQueryProvider(widget.sectionId)
                                .notifier)
                            .state = '';
                      },
                      child: const Icon(CupertinoIcons.clear_circled_solid,
                          size: 18, color: AppColors.textMuted),
                    ),
                  )
                : null,
            onChanged: (v) {
              ref
                  .read(searchQueryProvider(widget.sectionId).notifier)
                  .state = v;
            },
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: CupertinoColors.white,
              borderRadius:
                  BorderRadius.circular(AppDimensions.buttonRadius),
              border: Border.all(color: AppColors.border),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.paddingM),
          child: Row(
            children: [
              Text(
                'Showing ${records.length} of ${allRecords.valueOrNull?.length ?? 0} records',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: records.isEmpty
              ? const Center(
                  child: Text(
                    'No matching records',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.paddingM),
                  itemCount: records.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(
                          bottom: AppDimensions.paddingS),
                      child: RecordCard(
                        record: records[index],
                        primaryColumn: primaryCol,
                        secondaryColumn: secondaryCol,
                        allColumns: columnNames,
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
              onPressed: () => _startNewSession(),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(CupertinoIcons.add, size: 20),
                  SizedBox(width: 6),
                  Text('New Session'),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSessionsTab() {
    final sessionsAsync = ref.watch(sessionsProvider(widget.sectionId));

    return sessionsAsync.when(
      data: (sessions) {
        if (sessions.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'No sessions yet',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  "Tap 'New Session' to begin.",
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.paddingM,
              vertical: AppDimensions.paddingS),
          itemCount: sessions.length,
          itemBuilder: (context, index) {
            final session = sessions[index];
            return Padding(
              padding:
                  const EdgeInsets.only(bottom: AppDimensions.paddingS),
              child: SessionHistoryCard(
                session: session,
                onTap: () {},
                onEdit: () => _editSession(session),
                onDelete: () => _deleteSession(session),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CupertinoActivityIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  void _showMoreMenu() {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('Section Options'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(ctx).pop();
              _renameSection();
            },
            child: const Text('Rename Section'),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.of(ctx).pop();
              _deleteSection();
            },
            child: const Text('Delete Section'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  Future<void> _renameSection() async {
    final section =
        ref.read(sectionProvider(widget.sectionId)).valueOrNull;
    if (section == null) return;

    _sectionNameController.text = section.name;
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
              controller: _sectionNameController,
              placeholder: 'Section name',
              autofocus: true,
            ),
            const SizedBox(height: 16),
            CupertinoButton.filled(
              onPressed: () async {
                final newName =
                    _sectionNameController.text.trim();
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
                ref.invalidate(
                    sectionProvider(widget.sectionId));
                ref.invalidate(sectionsProvider);
                if (ctx.mounted) Navigator.of(ctx).pop();
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Future<void> _deleteSection() async {
    final section =
        ref.read(sectionProvider(widget.sectionId)).valueOrNull;
    if (section == null) return;

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
          ErrorDialog.show(context, message: e.toString());
        }
      },
    );

    if (confirmed == true) {
      await ref
          .read(sectionRepositoryProvider)
          .deleteSection(section.id);
      ref.invalidate(sectionsProvider);
      if (mounted) context.pop();
    }
  }

  Future<void> _exportSection() async {
    final section =
        ref.read(sectionProvider(widget.sectionId)).valueOrNull;
    if (section == null) return;

    try {
      LoadingOverlay.show(context);
      final filename = await ref
          .read(excelExporterProvider)
          .exportSection(section);
      LoadingOverlay.hide(context);
      if (!mounted) return;
      showCupertinoDialog(
        context: context,
        builder: (_) => CupertinoAlertDialog(
          title: const Text('Exported'),
          content: Text('Saved to Downloads/$filename'),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } on ExportException catch (e) {
      LoadingOverlay.hide(context);
      if (!mounted) return;
      showCupertinoDialog(
        context: context,
        builder: (_) => CupertinoAlertDialog(
          title: const Text('Export'),
          content: Text(e.message),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      LoadingOverlay.hide(context);
      if (!mounted) return;
      ErrorDialog.show(context, message: e.toString());
    }
  }

  Future<void> _startNewSession() async {
    final draftSession = await ref
        .read(sessionRepositoryProvider)
        .getDraftSession(widget.sectionId);

    if (draftSession != null) {
      final resume = await ConfirmationDialog.show(
        context,
        title: 'Resume Draft',
        message:
            'You have an unfinished attendance session from '
            '${draftSession.sessionDate.day}/${draftSession.sessionDate.month}/${draftSession.sessionDate.year}. '
            'Would you like to resume it?',
        confirmLabel: 'Resume',
        cancelLabel: 'Discard & Start New',
          onConfirm: () {
            context.push(
              '/section/${widget.sectionId}/session/${draftSession.id}',
            );
          },
      );

      if (resume == true) return;
      await ref
          .read(sessionRepositoryProvider)
          .deleteSession(draftSession.id);
    }

    _showNewSessionDialog();
  }

  void _showNewSessionDialog() {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => _NewSessionSheet(
        onCreate: (date, tag) {
          _createSession(date, tag);
        },
      ),
    );
  }

  Future<void> _createSession(DateTime date, String tag) async {
    final db = ref.read(appDatabaseProvider);
    final records =
        ref.read(recordsProvider(widget.sectionId)).valueOrNull;

    if (records == null) return;

    try {
      LoadingOverlay.show(context);

      final sessionId = await db.transaction(() async {
        final now = DateTime.now();
        final sessionDate =
            DateTime(date.year, date.month, date.day);

        final id = await db.sessionsDao.insertSession(
          SessionsCompanion(
            sectionId: Value(widget.sectionId),
            tag: tag.isEmpty ? const Value.absent() : Value(tag),
            sessionDate: Value(sessionDate),
            status: const Value('draft'),
            presentCount: Value(records.length),
            absentCount: const Value(0),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );

        final recordIds = records.map((r) => r.id).toList();
        await db.attendanceDao
            .initializeAttendanceForSession(id, recordIds);

        return id;
      });

      LoadingOverlay.hide(context);
      ref.invalidate(sessionsProvider(widget.sectionId));

      if (!mounted) return;
      context.push(
        '/section/${widget.sectionId}/session/$sessionId',
      );
    } catch (e) {
      LoadingOverlay.hide(context);
      if (!mounted) return;
      ErrorDialog.show(
          context, message: 'Failed to create session: $e');
    }
  }

  void _openSession(Session session) {
    context.push(
      '/section/${widget.sectionId}/session/${session.id}',
    );
  }

  void _editSession(Session session) {
    if (session.status == 'draft') {
      context.push(
        '/section/${widget.sectionId}/session/${session.id}',
      );
    } else {
      context.push(
        '/section/${widget.sectionId}/session/${session.id}/edit',
      );
    }
  }

  Future<void> _deleteSession(Session session) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Delete Session',
      message:
          'Delete this attendance session? This cannot be undone.',
      confirmLabel: 'Delete',
      isDestructive: true,
    );

    if (confirmed == true) {
      await ref
          .read(sessionRepositoryProvider)
          .deleteSession(session.id);
      ref.invalidate(sessionsProvider(widget.sectionId));
    }
  }
}

class _NewSessionSheet extends StatefulWidget {
  final void Function(DateTime date, String tag) onCreate;

  const _NewSessionSheet({required this.onCreate});

  @override
  State<_NewSessionSheet> createState() => _NewSessionSheetState();
}

class _NewSessionSheetState extends State<_NewSessionSheet> {
  late DateTime _selectedDate;
  final _tagController = TextEditingController();
  bool _showingPicker = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
  }

  @override
  void dispose() {
    _tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
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
              'New Attendance Session',
              style: TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w600),
            ),
            if (_showingPicker) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 200,
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  maximumDate: DateTime.now(),
                  initialDateTime: _selectedDate,
                  onDateTimeChanged: (date) =>
                      _selectedDate = date,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CupertinoButton(
                    onPressed: () =>
                        setState(() => _showingPicker = false),
                    child: const Text('Cancel'),
                  ),
                  CupertinoButton(
                    onPressed: () =>
                        setState(() => _showingPicker = false),
                    child: const Text('Done'),
                  ),
                ],
              ),
            ] else ...[
              const SizedBox(height: 20),
              const Text(
                'Date',
                style: TextStyle(
                    fontSize: 13, color: AppColors.textMuted),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () =>
                    setState(() => _showingPicker = true),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: CupertinoColors.white,
                    borderRadius: BorderRadius.circular(
                        AppDimensions.buttonRadius),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(CupertinoIcons.calendar,
                          size: 18,
                          color: AppColors.textSecondary),
                      const SizedBox(width: 10),
                      Text(
                        '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Session Tag (optional)',
                style: TextStyle(
                    fontSize: 13, color: AppColors.textMuted),
              ),
              const SizedBox(height: 8),
              CupertinoTextField(
                controller: _tagController,
                placeholder: "e.g. 'Morning'",
                maxLength: 50,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: CupertinoColors.white,
                  borderRadius: BorderRadius.circular(
                      AppDimensions.buttonRadius),
                  border: Border.all(color: AppColors.border),
                ),
              ),
              const SizedBox(height: 20),
              CupertinoButton.filled(
                onPressed: () {
                  Navigator.of(context).pop();
                  widget.onCreate(
                      _selectedDate,
                      _tagController.text.trim());
                },
                child: const Text('Start Session'),
              ),
              const SizedBox(height: 8),
              CupertinoButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
