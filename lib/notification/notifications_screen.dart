import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/config/constants.dart';
import 'package:flutter_application_1/core/models/paginated_response.dart';
import 'package:flutter_application_1/core/models/user/user_model.dart';
import 'package:flutter_application_1/core/utils/app_snackbar.dart';
import 'package:flutter_application_1/notification/model/notification_model.dart';
import 'package:flutter_application_1/notification/notification_service.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  static const Color _primary = Color(AppColors.primaryColor);
  static const Color _textSecondary = Color(AppColors.textSecondaryColor);

  final NotificationService _service = NotificationService();
  final ScrollController _scrollController = ScrollController();

  final List<AppNotification> _items = [];
  int _page = 1;
  bool _initialLoading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  String? _error;

  static const int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadInitial();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_hasMore || _loadingMore || _initialLoading) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 240) {
      _loadMore();
    }
  }

  Future<void> _loadInitial() async {
    setState(() {
      _initialLoading = true;
      _error = null;
    });
    try {
      final result = await _service.list(page: 1, limit: _pageSize);
      if (!mounted) return;
      final page = result ?? EmptyPaginatedResponse<AppNotification>();
      setState(() {
        _items
          ..clear()
          ..addAll(page.data);
        _page = page.page;
        _hasMore = page.hasNextPage;
        _initialLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _initialLoading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (!_hasMore || _loadingMore) return;
    setState(() => _loadingMore = true);
    try {
      final nextPage = _page + 1;
      final result =
          await _service.list(page: nextPage, limit: _pageSize);
      if (!mounted) return;
      final page = result ?? EmptyPaginatedResponse<AppNotification>();
      setState(() {
        _items.addAll(page.data);
        _page = page.page;
        _hasMore = page.hasNextPage;
        _loadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingMore = false);
    }
  }

  Future<void> _onRefresh() async {
    await _loadInitial();
  }

  Future<void> _onTap(AppNotification n) async {
    if (n.isRead) return;
    final updated = await _service.markRead(n.id);
    if (!mounted) return;
    if (updated != null) {
      final i = _items.indexWhere((e) => e.id == n.id);
      if (i != -1) {
        setState(() => _items[i] = updated);
      }
    }
  }

  Future<void> _markAllRead() async {
    final res = await _service.markAllRead();
    if (!mounted) return;
    if (res != null) {
      await _loadInitial();
      AppSnackbar.success(
        title: 'Notifications',
        message: 'Marked ${res.updatedCount} as read.',
      );
    } else {
      AppSnackbar.error(
        title: 'Notifications',
        message: 'Could not mark all as read.',
      );
    }
  }

  String _moduleLabel(NotificationModule m) {
    return switch (m) {
      NotificationModule.turfBooking => 'Turf booking',
      NotificationModule.matchmaking => 'Matchmaking',
    };
  }

  String? _formatTime(AppNotification n) {
    final dt = n.createdAtDate ?? n.updatedAtDate;
    if (dt == null) return null;
    return DateFormat('MMM d, y • h:mm a').format(dt.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(AppColors.backgroundColor),
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_items.any((e) => !e.isRead))
            TextButton(
              onPressed: _markAllRead,
              child: const Text(
                'Mark all read',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_initialLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(_primary),
        ),
      );
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: _textSecondary),
              const SizedBox(height: 16),
              Text(
                'Could not load notifications',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                style: const TextStyle(color: _textSecondary, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _loadInitial,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    if (_items.isEmpty) {
      return RefreshIndicator(
        color: _primary,
        onRefresh: _onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 120),
            Icon(
              Icons.notifications_none_rounded,
              size: 64,
              color: _textSecondary,
            ),
            SizedBox(height: 16),
            Center(
              child: Text(
                'No notifications yet',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(AppColors.textColor),
                ),
              ),
            ),
            SizedBox(height: 8),
            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  'When something needs your attention, it will show up here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: _textSecondary, fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      color: _primary,
      onRefresh: _onRefresh,
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _items.length + (_loadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _items.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          }
          final n = _items[index];
          final timeStr = _formatTime(n);
          return Material(
            color: n.isRead
                ? Colors.transparent
                : _primary.withValues(alpha: 0.06),
            child: InkWell(
              onTap: () => _onTap(n),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!n.isRead)
                      Padding(
                        padding: const EdgeInsets.only(top: 6, right: 10),
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: _primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      )
                    else
                      const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _moduleLabel(n.module),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            n.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight:
                                  n.isRead ? FontWeight.w500 : FontWeight.w700,
                              color: const Color(AppColors.textColor),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            n.body,
                            style: const TextStyle(
                              fontSize: 14,
                              height: 1.35,
                              color: _textSecondary,
                            ),
                          ),
                          if (timeStr != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              timeStr,
                              style: const TextStyle(
                                fontSize: 12,
                                color: _textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
