import 'package:flutter/cupertino.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../data/models/parsed_excel_model.dart';

class ImportSummaryDialog extends StatefulWidget {
  final ParsedExcelModel parsed;

  const ImportSummaryDialog({super.key, required this.parsed});

  static Future<ParsedExcelModel?> show(
      BuildContext context, ParsedExcelModel parsed) {
    return showCupertinoDialog<ParsedExcelModel>(
      context: context,
      builder: (context) => ImportSummaryDialog(parsed: parsed),
    );
  }

  @override
  State<ImportSummaryDialog> createState() => _ImportSummaryDialogState();
}

class _ImportSummaryDialogState extends State<ImportSummaryDialog> {
  bool _forceNoHeader = false;

  ParsedExcelModel get _displayModel => _forceNoHeader
      ? widget.parsed.copyWithForceNoHeader()
      : widget.parsed;

  @override
  Widget build(BuildContext context) {
    final model = _displayModel;

    return CupertinoAlertDialog(
      title: const Text('Import Summary'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                model.originalFileName,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _statBox('Rows', '${model.totalRows}'),
                  const SizedBox(width: 12),
                  _statBox('Columns', '${model.totalColumns}'),
                ],
              ),
              if (model.warnings.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.warningLight,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: AppColors.warning
                            .withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(CupertinoIcons
                              .exclamationmark_triangle_fill,
                              size: 16,
                              color: AppColors.warning),
                          SizedBox(width: 6),
                          Text(
                            'Warnings',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.warning,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...model.warnings.map((w) => Padding(
                            padding:
                                const EdgeInsets.only(bottom: 4),
                            child: Text(
                              '• $w',
                              style: const TextStyle(
                                  fontSize: 12,
                                  color:
                                      AppColors.textSecondary),
                            ),
                          )),
                    ],
                  ),
                ),
              ],
              if (!widget.parsed.hadNoHeader) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'First row is data (no header)',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                      CupertinoSwitch(
                        value: _forceNoHeader,
                        onChanged: (v) =>
                            setState(() => _forceNoHeader = v),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              const Text(
                'Columns Detected',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: model.columnNames
                    .map((c) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(
                                AppDimensions.chipRadius),
                          ),
                          child: Text(
                            c,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 16),
              const Text(
                'Preview (first rows)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 120,
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: _buildPreviewTable(
                        model.columnNames, model.sampleRows),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Cancel'),
        ),
        CupertinoDialogAction(
          onPressed: () =>
              Navigator.of(context).pop(_displayModel),
          child: const Text('Continue'),
        ),
      ],
    );
  }

  Widget _statBox(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewTable(
      List<String> columns, List<Map<String, String>> samples) {
    if (samples.isEmpty) return const SizedBox.shrink();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: columns
                .map((c) => SizedBox(
                      width: 100,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        child: Text(
                          c,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ))
                .toList(),
          ),
          Container(height: 1, color: AppColors.border),
          ...samples.map((row) {
            return Row(
              children: columns
                  .map((c) => SizedBox(
                        width: 100,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          child: Text(
                            row[c] ?? '',
                            style:
                                const TextStyle(fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ))
                  .toList(),
            );
          }),
        ],
      ),
    );
  }
}
