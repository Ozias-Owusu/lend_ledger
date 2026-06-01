import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lend_ledger/core/network/api_exception.dart';
import 'package:lend_ledger/core/notifications/notification_channels.dart';
import 'package:lend_ledger/core/service_locator.dart';
import 'package:lend_ledger/models/notification_models.dart';
import 'package:lend_ledger/state/app_state.dart';
import 'package:lend_ledger/theme/theme.dart';
import 'package:lend_ledger/utils/snackbar_utils.dart';
import 'package:lend_ledger/widgets/auth/auth_animated_background.dart';
import 'package:provider/provider.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key, this.focusNotificationId});

  /// When opened from a system notification tap, highlight this item.
  final String? focusNotificationId;

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  bool _loading = true;
  bool _markingAll = false;
  bool _unreadOnly = false;
  String? _error;
  NotificationListResult? _result;

  int get _unreadBadge =>
      _result?.unreadCount ??
      ServiceLocator.notificationSync.unreadCount.value;

  @override
  void initState() {
    super.initState();
    ServiceLocator.notificationSync.latestItems.addListener(_onInboxUpdated);
    ServiceLocator.notificationSync.unreadCount.addListener(_onInboxUpdated);
    _load();
  }

  @override
  void dispose() {
    ServiceLocator.notificationSync.latestItems.removeListener(_onInboxUpdated);
    ServiceLocator.notificationSync.unreadCount.removeListener(_onInboxUpdated);
    super.dispose();
  }

  void _onInboxUpdated() {
    if (!mounted || _loading) return;
    final synced = ServiceLocator.notificationSync.latestItems.value;
    if (synced.isEmpty) return;
    final items = _unreadOnly
        ? synced.where((n) => !n.isRead).toList()
        : synced;
    setState(() {
      _result = NotificationListResult(
        items: items,
        page: _result?.page ?? 1,
        pageSize: _result?.pageSize ?? 50,
        totalCount: _result?.totalCount ?? items.length,
        unreadCount: ServiceLocator.notificationSync.unreadCount.value,
      );
    });
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final appState = context.read<AppState>();
    try {
      await appState.fetchUnreadNotificationCount();
      final result = await appState.fetchNotifications(
        pageSize: 50,
        unreadOnly: _unreadOnly,
      );
      if (!mounted) return;
      setState(() {
        _result = result;
        _loading = false;
      });
      await _openFocusedIfNeeded(result.items);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _openFocusedIfNeeded(List<AppNotification> items) async {
    final focusId = widget.focusNotificationId;
    if (focusId == null || focusId.isEmpty || !mounted) return;
    final match = items.where((n) => n.id == focusId).firstOrNull;
    if (match == null) return;
    if (!match.isRead) {
      await _markOneRead(match);
    }
    if (!mounted) return;
    _openDetail(match.copyWith(isRead: true));
  }

  Future<void> _markAllRead() async {
    if (_unreadBadge == 0) return;
    setState(() => _markingAll = true);
    final appState = context.read<AppState>();
    try {
      await appState.markAllNotificationsRead();
      if (!mounted) return;
      SnackbarUtils.showSuccess(context, 'All notifications marked as read.');
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      SnackbarUtils.showError(context, e);
    } catch (e) {
      if (!mounted) return;
      SnackbarUtils.showError(context, e);
    } finally {
      if (mounted) setState(() => _markingAll = false);
    }
  }

  Future<void> _markOneRead(AppNotification notification) async {
    if (notification.isRead) return;
    final appState = context.read<AppState>();
    try {
      await appState.markNotificationRead(notification.id);
      if (!mounted) return;
      setState(() {
        final items = _result?.items;
        if (items == null) return;
        final index = items.indexWhere((n) => n.id == notification.id);
        if (index < 0) return;
        final updated = List<AppNotification>.from(items);
        updated[index] = notification.copyWith(isRead: true);
        _result = NotificationListResult(
          items: _unreadOnly
              ? updated.where((n) => !n.isRead).toList()
              : updated,
          page: _result!.page,
          pageSize: _result!.pageSize,
          totalCount: _result!.totalCount,
          unreadCount: ServiceLocator.notificationSync.unreadCount.value,
        );
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      SnackbarUtils.showError(context, e);
    }
  }

  Future<void> _enableNotifications() async {
    final appState = context.read<AppState>();
    final granted = await appState.requestNotificationPermission();
    if (!mounted) return;
    if (granted) {
      await appState.startNotificationPolling();
      if (!mounted) return;
      SnackbarUtils.showSuccess(context, 'Notifications enabled.');
      await _load();
    } else {
      SnackbarUtils.showError(
        context,
        'Notification permission was denied. Enable it in system settings.',
      );
    }
  }

  void _openDetail(AppNotification notification) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          notification.title,
          style: AppTheme.body(
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        content: Text(notification.message, style: AppTheme.body()),
        actions: [
          if (!notification.isRead)
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await _markOneRead(notification);
              },
              child: const Text('Mark as read'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Scaffold(
      body: AuthAnimatedBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    Expanded(
                      child: Text(
                        'Notifications',
                        style: AppTheme.display(fontSize: 28),
                      ),
                    ),
                    if (_unreadBadge > 0)
                      TextButton(
                        onPressed: _markingAll || _loading ? null : _markAllRead,
                        child: _markingAll
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppTheme.softRose,
                                ),
                              )
                            : const Text('Mark all read'),
                      ),
                    if (!appState.notificationPermissionGranted)
                      TextButton(
                        onPressed: _enableNotifications,
                        child: const Text('Enable'),
                      ),
                  ],
                ),
              ),
              if (!appState.notificationPermissionGranted)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: Material(
                    color: AppTheme.peach.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: _enableNotifications,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.notifications_active_outlined,
                              color: AppTheme.softRose.withValues(alpha: 0.9),
                              size: 22,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Enable alerts for loan activity while you use the app.',
                                style: AppTheme.body(fontSize: 12),
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text('All'),
                      selected: !_unreadOnly,
                      onSelected: (_) {
                        if (!_unreadOnly) return;
                        setState(() => _unreadOnly = false);
                        _load();
                      },
                      selectedColor: AppTheme.softRose.withValues(alpha: 0.25),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: Text('Unread ($_unreadBadge)'),
                      selected: _unreadOnly,
                      onSelected: (_) {
                        if (_unreadOnly) return;
                        setState(() => _unreadOnly = true);
                        _load();
                      },
                      selectedColor: AppTheme.softRose.withValues(alpha: 0.25),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: _loading ? null : _load,
                      icon: const Icon(Icons.refresh_rounded),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.softRose),
      );
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    final items = _result?.items ?? const [];
    if (items.isEmpty) {
      return Center(
        child: Text(
          _unreadOnly ? 'No unread notifications.' : 'No notifications yet.',
          style: AppTheme.body(),
        ),
      );
    }

    return RefreshIndicator(
      color: AppTheme.softRose,
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) => _NotificationTile(
          notification: items[index],
          highlighted: items[index].id == widget.focusNotificationId,
          onTap: () async {
            final item = items[index];
            if (!item.isRead) {
              await _markOneRead(item);
            }
            if (!mounted) return;
            _openDetail(item.copyWith(isRead: true));
          },
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.notification,
    required this.onTap,
    this.highlighted = false,
  });

  final AppNotification notification;
  final VoidCallback onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final channel = NotificationChannels.forType(notification.type);
    final time =
        DateFormat('MMM d · h:mm a').format(notification.createdAt.toLocal());

    return Material(
      color: highlighted
          ? AppTheme.softRose.withValues(alpha: 0.12)
          : Colors.white.withValues(alpha: 0.82),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          decoration: highlighted
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.softRose.withValues(alpha: 0.55),
                    width: 1.5,
                  ),
                )
              : null,
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.only(top: 6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: notification.isRead
                      ? Colors.transparent
                      : AppTheme.softRose,
                  border: notification.isRead
                      ? Border.all(color: AppTheme.mintGray)
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: AppTheme.body(
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.peach.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            channel.name,
                            style: AppTheme.body(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.message,
                      style: AppTheme.body(fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      time,
                      style: AppTheme.body(
                        fontSize: 11,
                        color: AppTheme.textMuted,
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
