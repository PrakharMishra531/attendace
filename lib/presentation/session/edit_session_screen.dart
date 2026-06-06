import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' hide Column;
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/database/app_database.dart';
import '../providers.dart';
import '../shared/error_dialog.dart';
import '../shared/loading_overlay.dart';
import '../section/widgets/record_card.dart';

class EditSessionScreen extends ConsumerStatefulWidget {
  final int sectionId;
  final int sessionId;

  const EditSessionScreen({
    super.key,
    required this.sectionId,
    required this.sessionId,
  });

  @override
  ConsumerState<EditSessionScreen> createState() => _EditSessionScreenState();
}

class _EditSessionScreenState extends ConsumerState<EditSessionScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sessionAsync = ref.watch(sessionProvider(widget.sessionId));
    final sectionAsync = ref.watch(sectionProvider(widget.sectionId));

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: sessionAsync.when(
          data: (session) {
            if (session == null) return const Text('Edit Session');
            final dateStr = DateFormatter.formatDate(session.sessionDate);
            return Text('Edit — $dateStr');
          },
          loading: () => const Text('Loading...'),
          error: (_, __) => const Text('Error'),
        ),
        trailing: GestureDetector(
          onTap: () => _saveChanges(),
          child: const Text(
            'Save',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: AppColors.navy,
            ),
          ),
        ),
      ),
      child: SafeArea(
        child: sessionAsync.when(
          data: (session) {
            if (session == null) {
              return const Center(child: Text('Session not found'));
            }
            return _buildContent(session, sectionAsync.valueOrNull);
          },
          loading: () =>
              const Center(child: CupertinoActivityIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
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
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.paddingM),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.presentLight,
                  borderRadius: BorderRadius.circular(
                      AppDimensions.chipRadius),
                ),
                child: Text(
                  'Present: ${attendance.values.where((v) => v).length}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.present,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.absentLight,
                  borderRadius: BorderRadius.circular(
                      AppDimensions.chipRadius),
                ),
                child: Text(
                  'Absent: ${attendance.values.where((v) => !v).length}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.absent,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
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
      ],
    );
  }

  Future<void> _saveChanges() async {
    try {
      LoadingOverlay.show(context);

      final attendance = ref.read(
          sessionAttendanceProvider(widget.sessionId));
      final presentCount = attendance.values.where((v) => v).length;
      final absentCount = attendance.values.where((v) => !v).length;

      await ref.read(sessionRepositoryProvider).updateSessionCounts(
            widget.sessionId, presentCount, absentCount);

      await ref
          .read(sectionRepositoryProvider)
          .updateSectionTimestamp(widget.sectionId);

      LoadingOverlay.hide(context);
      ref.invalidate(sessionsProvider(widget.sectionId));
      ref.invalidate(sectionProvider(widget.sectionId));
      ref.invalidate(sectionsProvider);

      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      LoadingOverlay.hide(context);
      if (!mounted) return;
      ErrorDialog.show(context, message: 'Failed to save: $e');
    }
  }
}
