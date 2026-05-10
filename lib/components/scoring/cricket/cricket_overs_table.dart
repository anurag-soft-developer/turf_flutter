import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/config/constants.dart';
import '../../../core/models/user_field_instance.dart';
import '../../../scoring/model/cricket_ball_event_model.dart';
import '../../../scoring/scoring_controller.dart';

/// Table that lists every recorded over with a small per-row summary.
///
/// Observes [ScoringController.cricketOvers] and
/// [ScoringController.isFetchingOvers] so the parent does not need to wrap
/// it with its own [Obx].
class CricketOversTable extends StatelessWidget {
  const CricketOversTable({super.key, required this.controller});

  final ScoringController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final loading = controller.isFetchingOvers.value;
      final overs = controller.cricketOvers;

      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(AppColors.dividerColor)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
              child: Row(
                children: [
                  Icon(
                    Icons.format_list_numbered_rounded,
                    size: 20,
                    color: const Color(
                      AppColors.primaryColor,
                    ).withValues(alpha: 0.85),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Overs',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: Color(AppColors.textColor),
                    ),
                  ),
                  const Spacer(),
                  if (loading)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
            ),
            if (overs.isEmpty && !loading)
              const Padding(
                padding: EdgeInsets.fromLTRB(14, 0, 14, 14),
                child: Text(
                  'No overs recorded yet.',
                  style: TextStyle(
                    color: Color(AppColors.textSecondaryColor),
                    fontSize: 13,
                  ),
                ),
              ),
            if (overs.isNotEmpty)
              LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minWidth: constraints.maxWidth,
                      ),
                      child: Table(
                        border: TableBorder.symmetric(
                          inside: BorderSide(
                            color: const Color(
                              AppColors.dividerColor,
                            ).withValues(alpha: 0.7),
                          ),
                          outside: BorderSide.none,
                        ),
                        columnWidths: const {
                          0: FlexColumnWidth(0.45),
                          1: FlexColumnWidth(0.35),
                          2: FlexColumnWidth(0.5),
                          3: FlexColumnWidth(0.45),
                          4: FlexColumnWidth(0.4),
                          5: FlexColumnWidth(0.45),
                          6: FlexColumnWidth(0.55),
                        },
                        children: [
                          TableRow(
                            decoration: BoxDecoration(
                              color: const Color(
                                AppColors.backgroundColor,
                              ).withValues(alpha: 0.6),
                            ),
                            children: const [
                              _OverTableCell('Seq', header: true),
                              _OverTableCell('Balls', header: true),
                              _OverTableCell('Runs', header: true),
                              _OverTableCell('Legal', header: true),
                              _OverTableCell('Bowler', header: true),
                            ],
                          ),
                          ...overs.map(
                            (o) => TableRow(
                              children: [
                                _OverTableCell('${o.sequence}'),
                                _OverTableCell('${o.ballEvents.length}'),
                                _OverTableCell('${_totalRunsInOver(o)}'),
                                _OverTableCell(
                                  '${o.ballEvents.where((b) => b.isLegalDelivery).length}',
                                ),
                                _OverTableCell(_bowlerCellLabel(o.bowlerUserId)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            const SizedBox(height: 4),
          ],
        ),
      );
    });
  }
}

int _totalRunsInOver(CricketOverEvent o) {
  var sum = 0;
  for (final b in o.ballEvents) {
    sum += b.totalRunsOnDelivery;
  }
  return sum;
}

String _bowlerCellLabel(dynamic bowlerRef) {
  final h = UserFieldInstance(bowlerRef);
  final name = h.getName();
  if (name != null && name.isNotEmpty) return name;
  final id = h.getId();
  if (id == null || id.isEmpty) return '—';
  if (id.length <= 8) return id;
  return '…${id.substring(id.length - 6)}';
}

class _OverTableCell extends StatelessWidget {
  const _OverTableCell(this.text, {this.header = false});

  final String text;
  final bool header;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontWeight: header ? FontWeight.w700 : FontWeight.w500,
          fontSize: header ? 11 : 13,
          color: header
              ? const Color(AppColors.textSecondaryColor)
              : const Color(AppColors.textColor),
        ),
      ),
    );
  }
}
