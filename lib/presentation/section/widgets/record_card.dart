import 'dart:convert';
import 'package:flutter/cupertino.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';

class RecordCard extends StatefulWidget {
  final dynamic record;
  final String primaryColumn;
  final String? secondaryColumn;
  final List<String> allColumns;
  final bool showToggle;
  final bool isPresent;
  final VoidCallback? onToggle;

  const RecordCard({
    super.key,
    required this.record,
    required this.primaryColumn,
    this.secondaryColumn,
    required this.allColumns,
    this.showToggle = false,
    this.isPresent = true,
    this.onToggle,
  });

  @override
  State<RecordCard> createState() => _RecordCardState();
}

class _RecordCardState extends State<RecordCard>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;

  Map<String, String> get _data {
    try {
      final decoded = jsonDecode(widget.record.data);
      return Map<String, String>.from(decoded);
    } catch (_) {
      return {};
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryValue = _data[widget.primaryColumn] ?? '';
    final secondaryValue = widget.secondaryColumn != null
        ? _data[widget.secondaryColumn!] ?? ''
        : '';

    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
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
                  color: widget.showToggle
                      ? (widget.isPresent
                          ? AppColors.present
                          : AppColors.absent)
                      : AppColors.navy,
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
                              primaryValue,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (_expanded)
                            const Icon(
                              CupertinoIcons.chevron_up,
                              size: 16,
                              color: AppColors.textMuted,
                            )
                          else
                            const Icon(
                              CupertinoIcons.chevron_down,
                              size: 16,
                              color: AppColors.textMuted,
                            ),
                        ],
                      ),
                      if (secondaryValue.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            secondaryValue,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      if (_expanded) ...[
                        const SizedBox(height: 10),
                        Container(height: 1, color: AppColors.border),
                        const SizedBox(height: 10),
                        ...widget.allColumns.map((col) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 100,
                                  child: Text(
                                    col.toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textMuted,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    _data[col] ?? '',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ],
                  ),
                ),
              ),
              if (widget.showToggle)
                Padding(
                  padding:
                      const EdgeInsets.only(right: AppDimensions.paddingM),
                  child: GestureDetector(
                    onTap: widget.onToggle,
                    child: Container(
                      width: 80,
                      height: 32,
                      decoration: BoxDecoration(
                        color: widget.isPresent
                            ? AppColors.present
                            : AppColors.absent,
                        borderRadius:
                            BorderRadius.circular(AppDimensions.chipRadius),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        widget.isPresent ? 'Present' : 'Absent',
                        style: const TextStyle(
                          color: CupertinoColors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
