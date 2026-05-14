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
      final currentOver = _currentOver(overs, controller.cricketMatch.value?.cricketState?.currentInnings);
      final tableOvers = _oversForTable(overs, currentOver);

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
                  final breakdownWidth = _breakdownColumnWidth(
                    currentOver,
                    tableOvers,
                  );

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
                        columnWidths: {
                          0: const FixedColumnWidth(52),
                          1: const FixedColumnWidth(56),
                          2: const FixedColumnWidth(56),
                          3: const FixedColumnWidth(56),
                          4: const FixedColumnWidth(120),
                          5: FixedColumnWidth(breakdownWidth),
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
                              _OverTableCell('Breakdown', header: true),
                            ],
                          ),
                          if (currentOver != null)
                            _overTableRow(currentOver, isCurrent: true),
                          ...tableOvers.map((o) => _overTableRow(o)),
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

TableRow _overTableRow(CricketOverEvent over, {bool isCurrent = false}) {
  return TableRow(
    decoration: isCurrent
        ? BoxDecoration(
            color: const Color(AppColors.primaryColor).withValues(alpha: 0.08),
          )
        : null,
    children: [
      _OverTableCell(
        isCurrent ? '${over.sequence} ·' : '${over.sequence}',
        emphasized: isCurrent,
      ),
      _OverTableCell('${over.ballEvents.length}', emphasized: isCurrent),
      _OverTableCell('${_totalRunsInOver(over)}', emphasized: isCurrent),
      _OverTableCell(
        '${over.ballEvents.where((b) => b.isLegalDelivery).length}',
        emphasized: isCurrent,
      ),
      _OverTableCell(_bowlerCellLabel(over.bowlerUserId), emphasized: isCurrent),
      _BallsBreakdownCell(over.ballEvents, emphasized: isCurrent),
    ],
  );
}

CricketOverEvent? _currentOver(List<CricketOverEvent> overs, int? currentInnings) {
  if (currentInnings == null || currentInnings < 1) return null;

  CricketOverEvent? latest;
  for (final over in overs) {
    if (over.innings != currentInnings) continue;
    if (latest == null ||
        over.overAfter > latest.overAfter ||
        (over.overAfter == latest.overAfter && over.sequence > latest.sequence)) {
      latest = over;
    }
  }
  return latest;
}

List<CricketOverEvent> _oversForTable(
  List<CricketOverEvent> overs,
  CricketOverEvent? currentOver,
) {
  final sorted = List<CricketOverEvent>.from(overs)
    ..sort((a, b) {
      final bySequence = b.sequence.compareTo(a.sequence);
      if (bySequence != 0) return bySequence;
      return b.overAfter.compareTo(a.overAfter);
    });

  if (currentOver == null) return sorted;

  return sorted
      .where(
        (over) =>
            over.innings != currentOver.innings ||
            over.overAfter != currentOver.overAfter ||
            over.sequence != currentOver.sequence,
      )
      .toList();
}

double _breakdownColumnWidth(
  CricketOverEvent? currentOver,
  List<CricketOverEvent> tableOvers,
) {
  var maxBalls = 0;
  for (final over in tableOvers) {
    if (over.ballEvents.length > maxBalls) {
      maxBalls = over.ballEvents.length;
    }
  }
  if (currentOver != null && currentOver.ballEvents.length > maxBalls) {
    maxBalls = currentOver.ballEvents.length;
  }
  return (maxBalls * 34.0 + 24).clamp(180.0, 420.0);
}

int _totalRunsInOver(CricketOverEvent over) {
  var sum = 0;
  for (final ball in over.ballEvents) {
    sum += ball.totalRunsOnDelivery;
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

String _ballDeliveryLabel(CricketBallEvent ball) {
  if (ball.isWicket) return 'W';
  if (ball.extrasNoBall) {
    return ball.runsOffBat > 0 ? '${ball.runsOffBat}Nb' : 'Nb';
  }
  if (ball.extrasWide > 0) {
    return ball.totalRunsOnDelivery > 1
        ? '${ball.totalRunsOnDelivery}Wd'
        : 'Wd';
  }
  if (ball.extrasBye > 0) {
    return '${ball.extrasBye}B';
  }
  if (ball.extrasLegBye > 0) {
    return '${ball.extrasLegBye}Lb';
  }
  if (ball.runsOffBat == 0 && ball.totalRunsOnDelivery == 0) {
    return '·';
  }
  return '${ball.runsOffBat}';
}

class _OverTableCell extends StatelessWidget {
  const _OverTableCell(
    this.text, {
    this.header = false,
    this.emphasized = false,
  });

  final String text;
  final bool header;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontWeight: header || emphasized ? FontWeight.w700 : FontWeight.w500,
          fontSize: header ? 11 : 13,
          color: header
              ? const Color(AppColors.textSecondaryColor)
              : const Color(AppColors.textColor),
        ),
      ),
    );
  }
}

class _BallsBreakdownCell extends StatelessWidget {
  const _BallsBreakdownCell(this.balls, {this.emphasized = false});

  final List<CricketBallEvent> balls;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    if (balls.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Text(
          '—',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: emphasized ? FontWeight.w600 : FontWeight.w500,
            color: const Color(AppColors.textSecondaryColor),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Wrap(
          spacing: 4,
          runSpacing: 4,
          children: [
            for (final ball in balls)
              _BallChip(
                label: _ballDeliveryLabel(ball),
                isWicket: ball.isWicket,
                isExtra: !ball.isLegalDelivery,
                emphasized: emphasized,
              ),
          ],
        ),
      ),
    );
  }
}

class _BallChip extends StatelessWidget {
  const _BallChip({
    required this.label,
    required this.isWicket,
    required this.isExtra,
    this.emphasized = false,
  });

  final String label;
  final bool isWicket;
  final bool isExtra;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final Color background;
    final Color foreground;
    if (isWicket) {
      background = const Color(0xFFFFE8E8);
      foreground = const Color(0xFFB42318);
    } else if (isExtra) {
      background = const Color(0xFFFFF4E5);
      foreground = const Color(0xFFB54708);
    } else {
      background = const Color(AppColors.backgroundColor);
      foreground = const Color(AppColors.textColor);
    }

    return Container(
      constraints: const BoxConstraints(minWidth: 28),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: foreground.withValues(alpha: emphasized ? 0.35 : 0.2),
        ),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 11,
          fontWeight: emphasized ? FontWeight.w700 : FontWeight.w600,
          color: foreground,
        ),
      ),
    );
  }
}
