import 'package:flutter/cupertino.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/utils/date_formatter.dart';

class SessionHistoryCard extends StatelessWidget {
  final dynamic session;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const SessionHistoryCard({
    super.key,
    required this.session,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isConfirmed = session.status == 'confirmed';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: CupertinoColors.white,
          borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
          border: Border.all(color: AppColors.border),
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(
                width: AppDimensions.cardAccentWidth,
                decoration: BoxDecoration(
                  color: isConfirmed ? AppColors.present : AppColors.draft,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(AppDimensions.cardRadius),
                    bottomLeft: Radius.circular(AppDimensions.cardRadius),
                  ),
                ),
              ),
              const SizedBox(width: 2),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppDimensions.paddingM),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              DateFormatter.formatDate(session.sessionDate),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isConfirmed
                                  ? AppColors.presentLight
                                  : AppColors.warningLight,
                              borderRadius:
                                  BorderRadius.circular(AppDimensions.chipRadius),
                            ),
                            child: Text(
                              isConfirmed ? 'Confirmed' : 'Draft',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isConfirmed
                                    ? AppColors.present
                                    : AppColors.draft,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (session.tag != null && session.tag!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius:
                                  BorderRadius.circular(AppDimensions.chipRadius),
                            ),
                            child: Text(
                              session.tag!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 4),
                      Text(
                        'Present: ${session.presentCount}  Absent: ${session.absentCount}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: AppDimensions.paddingM),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: onEdit,
                      child: const Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Text(
                          'Edit',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.navy,
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: onDelete,
                      child: const Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Text(
                          'Delete',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.absent,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
