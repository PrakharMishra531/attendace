import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' hide Column;
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import 'package:go_router/go_router.dart';
import '../../core/utils/date_formatter.dart';
import '../providers.dart';
import '../../data/database/app_database.dart';
import '../section/widgets/record_card.dart';

class SessionScreen extends ConsumerStatefulWidget {
  final int sectionId;
  final int sessionId;

  const SessionScreen({
    super.key,
    required this.sectionId,
    required this.sessionId,
  });

  @override
  ConsumerState<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends ConsumerState<SessionScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sessionAsync =
        ref.watch(sessionProvider(widget.sessionId));
    final sectionAsync =
        ref.watch(sectionProvider(widget.sectionId));

    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBackPress();
      },
      child: CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: sessionAsync.when(
            data: (session) {
              if (session == null) return const Text('Session');
              final dateStr =
                  DateFormatter.formatDate(session.sessionDate);
              return Column(
                children: [
                  Text(dateStr,
                      style: const TextStyle(fontSize: 16)),
                  if (session.tag != null &&
                      session.tag!.isNotEmpty)
                    Text(
                      session.tag!,
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary),
                    ),
                ],
              );
            },
            loading: () => const Text('Loading...'),
            error: (_, __) => const Text('Error'),
          ),
        ),
        child: SafeArea(
          child: sessionAsync.when(
            data: (session) {
              if (session == null) {
                return const Center(
                    child: Text('Session not found'));
              }
              return _buildContent(session, sectionAsync.valueOrNull);
            },
            loading: () =>
                const Center(child: CupertinoActivityIndicator()),
            error: (e, _) =>
                Center(child: Text('Error: $e')),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(Session session, Section? section) {
    if (section == null) {
      return const Center(child: Text('Section not found'));
    }

    final columnNames =
        List<String>.from(jsonDecode(section.columnNames) as List);
    final primaryCol = columnNames[section.primaryColumnIndex];
    final secondaryCol = section.secondaryColumnIndex != null &&
            section.secondaryColumnIndex! < columnNames.length
        ? columnNames[section.secondaryColumnIndex!]
        : null;

    final attendance =
        ref.watch(sessionAttendanceProvider(widget.sessionId));
    final records =
        ref.watch(recordsProvider(widget.sectionId)).valueOrNull ?? [];
    final query = ref.watch(searchQueryProvider(widget.sectionId));

    final presentCount = attendance.values.where((v) => v).length;
    final absentCount = attendance.values.where((v) => !v).length;

    final filteredRecords = records.where((r) {
      if (query.isNotEmpty) {
        final data = jsonDecode(r.data) as Map<String, dynamic>;
        final value =
            (data[primaryCol] ?? '').toString().toLowerCase();
        if (!value.contains(query.toLowerCase())) return false;
      }
      return attendance.containsKey(r.id);
    }).toList();

    _searchController.text = query;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppDimensions.paddingM,
              AppDimensions.paddingS,
              AppDimensions.paddingM,
              0),
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: CupertinoColors.white,
              borderRadius:
                  BorderRadius.circular(AppDimensions.buttonRadius),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Center(
                    child: Text(
                      'Present: $presentCount',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.present,
                      ),
                    ),
                  ),
                ),
                Container(
                    width: 1, height: 24, color: AppColors.border),
                Expanded(
                  child: Center(
                    child: Text(
                      'Absent: $absentCount',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.absent,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
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
                            .read(searchQueryProvider(
                                    widget.sectionId)
                                .notifier)
                            .state = '';
                      },
                      child: const Icon(
                          CupertinoIcons.clear_circled_solid,
                          size: 18,
                          color: AppColors.textMuted),
                    ),
                  )
                : null,
            onChanged: (v) {
              ref
                  .read(
                      searchQueryProvider(widget.sectionId).notifier)
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
        Expanded(
          child: filteredRecords.isEmpty
              ? const Center(
                  child: Text('No matching records',
                      style:
                          TextStyle(color: AppColors.textSecondary)),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.paddingM),
                  itemCount: filteredRecords.length,
                  itemBuilder: (context, index) {
                    final record = filteredRecords[index];
                    final isPresent =
                        attendance[record.id] ?? true;
                    return Padding(
                      padding: const EdgeInsets.only(
                          bottom: AppDimensions.paddingS),
                      child: RecordCard(
                        record: record,
                        primaryColumn: primaryCol,
                        secondaryColumn: secondaryCol,
                        allColumns: columnNames,
                        showToggle: true,
                        isPresent: isPresent,
                        onToggle: () => ref
                            .read(sessionAttendanceProvider(
                                    widget.sessionId)
                                .notifier)
                            .toggle(record.id),
                      ),
                    );
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingM),
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: CupertinoButton.filled(
              onPressed: () => _submitSession(session),
              child: const Text('Submit'),
            ),
          ),
        ),
      ],
    );
  }

  void _handleBackPress() {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Leave Session?'),
        content: const Text(
          'Your current session progress will be saved as a draft '
          'and resumed next time.',
        ),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.of(ctx).pop();
              ref
                  .read(sessionRepositoryProvider)
                  .getSession(widget.sessionId);
              if (mounted) Navigator.of(context).pop();
            },
            child: const Text('Discard Session'),
          ),
          CupertinoDialogAction(
            onPressed: () {
              Navigator.of(ctx).pop();
              if (mounted) Navigator.of(context).pop();
            },
            child: const Text('Save as Draft'),
          ),
        ],
      ),
    );
  }

  void _submitSession(Session session) {
    context.push(
      '/section/${widget.sectionId}/session/${widget.sessionId}/summary',
    );
  }
}
