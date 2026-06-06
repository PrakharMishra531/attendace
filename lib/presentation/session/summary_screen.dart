import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/utils/date_formatter.dart';
import 'package:go_router/go_router.dart';
import '../../data/database/app_database.dart';
import '../providers.dart';
import '../shared/loading_overlay.dart';
import '../shared/error_dialog.dart';
import '../section/widgets/record_card.dart';

class SummaryScreen extends ConsumerWidget {
  final int sectionId;
  final int sessionId;

  const SummaryScreen({
    super.key,
    required this.sectionId,
    required this.sessionId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionAsync = ref.watch(sessionProvider(sessionId));
    final sectionAsync = ref.watch(sectionProvider(sectionId));
    final attendance =
        ref.watch(sessionAttendanceProvider(sessionId));
    final records =
        ref.watch(recordsProvider(sectionId)).valueOrNull ?? [];

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Attendance Summary'),
      ),
      child: SafeArea(
        child: sessionAsync.when(
          data: (session) {
            if (session == null) {
              return const Center(child: Text('Session not found'));
            }
            return _buildContent(
                context, ref, session, sectionAsync.valueOrNull,
                attendance, records);
          },
          loading: () => const Center(child: CupertinoActivityIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    Session session,
    Section? section,
    Map<int, bool> attendance,
    List<Record> records,
  ) {
    final presentRecordIds =
        attendance.entries.where((e) => e.value).map((e) => e.key).toSet();
    final absentRecordIds =
        attendance.entries.where((e) => !e.value).map((e) => e.key).toSet();

    final presentRecords = records
        .where((r) => presentRecordIds.contains(r.id))
        .toList();
    final absentRecords = records
        .where((r) => absentRecordIds.contains(r.id))
        .toList();

    final columnNames = section != null
        ? List<String>.from(jsonDecode(section.columnNames) as List)
        : <String>[];
    final primaryCol = section != null
        ? columnNames[section.primaryColumnIndex]
        : '';
    final secondaryCol = section != null &&
            section.secondaryColumnIndex != null &&
            section.secondaryColumnIndex! < columnNames.length
        ? columnNames[section.secondaryColumnIndex!]
        : null;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimensions.paddingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: CupertinoColors.white,
                    borderRadius:
                        BorderRadius.circular(AppDimensions.cardRadius),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormatter.formatDate(session.sessionDate),
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (session.tag != null &&
                          session.tag!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          session.tag!,
                          style: const TextStyle(
                              color: AppColors.textSecondary),
                        ),
                      ],
                      if (section != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          section.name,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.presentLight,
                          borderRadius:
                              BorderRadius.circular(AppDimensions.cardRadius),
                        ),
                        child: Column(
                          children: [
                            const Icon(CupertinoIcons.checkmark_alt,
                                size: 28, color: AppColors.present),
                            const SizedBox(height: 8),
                            Text(
                              '${presentRecords.length}',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w700,
                                color: AppColors.present,
                              ),
                            ),
                            const Text(
                              'Present',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppColors.present,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.absentLight,
                          borderRadius:
                              BorderRadius.circular(AppDimensions.cardRadius),
                        ),
                        child: Column(
                          children: [
                            const Icon(CupertinoIcons.xmark,
                                size: 28, color: AppColors.absent),
                            const SizedBox(height: 8),
                            Text(
                              '${absentRecords.length}',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w700,
                                color: AppColors.absent,
                              ),
                            ),
                            const Text(
                              'Absent',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppColors.absent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildExpandableSection(
                  title: 'Present (${presentRecords.length})',
                  icon: CupertinoIcons.checkmark_alt,
                  color: AppColors.present,
                  records: presentRecords,
                  primaryCol: primaryCol,
                  secondaryCol: secondaryCol,
                  columnNames: columnNames,
                ),
                const SizedBox(height: 12),
                _buildExpandableSection(
                  title: 'Absent (${absentRecords.length})',
                  icon: CupertinoIcons.xmark,
                  color: AppColors.absent,
                  records: absentRecords,
                  primaryCol: primaryCol,
                  secondaryCol: secondaryCol,
                  columnNames: columnNames,
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
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: CupertinoButton(
                      onPressed: () => Navigator.of(context).pop(),
                      color: CupertinoColors.white,
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: AppColors.navy),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: CupertinoButton.filled(
                      onPressed: () =>
                          _confirmAndSave(context, ref, session),
                      child: const Text('Confirm & Save'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExpandableSection({
    required String title,
    required IconData icon,
    required Color color,
    required List<Record> records,
    required String primaryCol,
    required String? secondaryCol,
    required List<String> columnNames,
  }) {
    return _ExpandableSection(
      title: title,
      icon: icon,
      color: color,
      children: records.isEmpty
          ? [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('No records in this category.',
                    style: TextStyle(color: AppColors.textSecondary)),
              ),
            ]
          : records.map((r) {
              return Padding(
                padding: const EdgeInsets.only(bottom: AppDimensions.paddingS),
                child: RecordCard(
                  record: r,
                  primaryColumn: primaryCol,
                  secondaryColumn: secondaryCol,
                  allColumns: columnNames,
                ),
              );
            }).toList(),
    );
  }

  Future<void> _confirmAndSave(
      BuildContext context, WidgetRef ref, Session session) async {
    final attendance =
        ref.read(sessionAttendanceProvider(sessionId));

    LoadingOverlay.show(context);

    try {
      final presentCount = attendance.values.where((v) => v).length;
      final absentCount = attendance.values.where((v) => !v).length;

      await ref.read(sessionRepositoryProvider).confirmSession(
            session.id,
            presentCount,
            absentCount,
          );

      await ref.read(sectionRepositoryProvider).updateSectionTimestamp(
            sectionId,
          );

      LoadingOverlay.hide(context);
      ref.invalidate(sessionsProvider(sectionId));
      ref.invalidate(sectionProvider(sectionId));
      ref.invalidate(sectionsProvider);

      if (!context.mounted) return;
      context.go('/');
      context.push('/section/$sectionId');
    } catch (e) {
      LoadingOverlay.hide(context);
      if (!context.mounted) return;
      ErrorDialog.show(context, message: 'Failed to save: $e');
    }
  }
}

class _ExpandableSection extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<Widget> children;

  const _ExpandableSection({
    required this.title,
    required this.icon,
    required this.color,
    required this.children,
  });

  @override
  State<_ExpandableSection> createState() => _ExpandableSectionState();
}

class _ExpandableSectionState extends State<_ExpandableSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingM),
              child: Row(
                children: [
                  Icon(widget.icon, size: 18, color: widget.color),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(
                    _expanded
                        ? CupertinoIcons.chevron_up
                        : CupertinoIcons.chevron_down,
                    size: 16,
                    color: AppColors.textMuted,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            Container(height: 1, color: AppColors.border),
            Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingM),
              child: Column(children: widget.children),
            ),
          ],
        ],
      ),
    );
  }
}
