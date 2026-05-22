import 'package:flutter/material.dart';

import '../../../../components/shared/app_segmented_tabs/app_segmented_tabs.dart';
import '../../../../core/config/constants.dart';
import '../../../../match_up/model/team_match_model.dart';
import '../../../../scoring/cricket/cricket_scoring_api_service.dart';
import '../../../../scoring/cricket/model/cricket_ball_event_model.dart';
import '../../../../scoring/football/football_scoring_api_service.dart';
import '../../../../scoring/football/model/football_match_event_model.dart';
import '../../../../scoring/football/widgets/football_scorecard.dart';
import '../../../../team/model/team_model.dart';
import 'cricket_scorecard.dart';

class MatchScorecardTab extends StatefulWidget {
  const MatchScorecardTab({
    super.key,
    required this.match,
    this.parentTabController,
  });

  final TeamMatchModel match;
  final TabController? parentTabController;

  @override
  State<MatchScorecardTab> createState() => _MatchScorecardTabState();
}

class _MatchScorecardTabState extends State<MatchScorecardTab> {
  final CricketScoringApiService _cricketApi = CricketScoringApiService();
  final FootballScoringApiService _footballApi = FootballScoringApiService();

  TeamMatchModel? _match;
  List<CricketOverEvent> _overs = const [];
  List<FootballMatchEvent> _footballEvents = const [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _match = widget.match;
    _loadScorecard();
  }

  @override
  void didUpdateWidget(covariant MatchScorecardTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.match.id != widget.match.id ||
        oldWidget.match.updatedAt != widget.match.updatedAt) {
      _match = widget.match;
      _loadScorecard();
    }
  }

  Future<void> _loadScorecard() async {
    if (widget.match.sportType == TeamSportType.cricket) {
      await _loadCricketScorecard();
    } else if (widget.match.sportType == TeamSportType.football) {
      await _loadFootballScorecard();
    }
  }

  Future<void> _loadCricketScorecard() async {
    final matchId = widget.match.id;
    if (matchId == null || matchId.isEmpty) {
      setState(() {
        _errorMessage = 'Missing match id.';
        _overs = const [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final match = await _cricketApi.getCricketSession(matchId);
      final overs = await _cricketApi.listCricketOvers(teamMatchId: matchId);
      if (!mounted) return;
      setState(() {
        _match = match ?? widget.match;
        _overs = List<CricketOverEvent>.from(overs)
          ..sort((a, b) => a.sequence.compareTo(b.sequence));
        _isLoading = false;
        if (match == null) {
          _errorMessage = 'Could not load scorecard.';
        }
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = error.toString();
      });
    }
  }

  Future<void> _loadFootballScorecard() async {
    final matchId = widget.match.id;
    if (matchId == null || matchId.isEmpty) {
      setState(() {
        _errorMessage = 'Missing match id.';
        _footballEvents = const [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final match = await _footballApi.getFootballSession(matchId);
      final events = await _footballApi.listFootballEvents(teamMatchId: matchId);
      if (!mounted) return;
      setState(() {
        _match = match ?? widget.match;
        _footballEvents = List<FootballMatchEvent>.from(events)
          ..sort((a, b) => a.sequence.compareTo(b.sequence));
        _isLoading = false;
        if (match == null) {
          _errorMessage = 'Could not load scorecard.';
        }
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = error.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.match.sportType == TeamSportType.football) {
      if (_errorMessage != null && _match?.footballState == null) {
        return _wrapParentSwipe(
          _ErrorState(message: _errorMessage!, onRetry: _loadFootballScorecard),
        );
      }
      return FootballScorecard(
        match: _match ?? widget.match,
        events: _footballEvents,
        parentTabController: widget.parentTabController,
        isLoading: _isLoading,
        onRetry: _loadFootballScorecard,
      );
    }

    if (widget.match.sportType != TeamSportType.cricket) {
      return _wrapParentSwipe(const _SportPlaceholder());
    }

    if (_errorMessage != null && _match?.cricketState == null) {
      return _wrapParentSwipe(
        _ErrorState(
          message: _errorMessage!,
          onRetry: _loadCricketScorecard,
        ),
      );
    }

    return CricketScorecard(
      match: _match ?? widget.match,
      overs: _overs,
      parentTabController: widget.parentTabController,
      isLoading: _isLoading,
      onRetry: _loadCricketScorecard,
    );
  }

  Widget _wrapParentSwipe(Widget child) {
    final parent = widget.parentTabController;
    if (parent == null) return child;
    return ParentLinkedHorizontalSwipe(
      parentController: parent,
      child: child,
    );
  }
}

class _SportPlaceholder extends StatelessWidget {
  const _SportPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(AppColors.surfaceColor),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Text(
        'coming soon for this sport',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Color(AppColors.textSecondaryColor),
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(AppColors.surfaceColor),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            message,
            style: const TextStyle(
              color: Color(AppColors.textSecondaryColor),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
