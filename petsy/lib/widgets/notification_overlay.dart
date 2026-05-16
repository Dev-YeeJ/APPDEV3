import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NotificationOverlay {
  static OverlayEntry? _currentEntry;
  static final List<_NotificationItem> _queue = [];
  static bool _isShowing = false;

  static void show({
    required BuildContext context,
    required String title,
    required String message,
    required NotificationType type,
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onTap,
  }) {
    _queue.add(
      _NotificationItem(
        title: title,
        message: message,
        type: type,
        duration: duration,
        onTap: onTap,
      ),
    );

    if (!_isShowing) {
      _showNext(context);
    }
  }

  static void _showNext(BuildContext context) {
    if (_queue.isEmpty) {
      _isShowing = false;
      return;
    }

    _isShowing = true;
    final notification = _queue.removeAt(0);

    _currentEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 16,
        left: 16,
        right: 16,
        child: _NotificationWidget(
          title: notification.title,
          message: notification.message,
          type: notification.type,
          onTap: notification.onTap,
          onDismiss: () {
            _currentEntry?.remove();
            _currentEntry = null;
            Future.delayed(const Duration(milliseconds: 300), () {
              _showNext(context);
            });
          },
        ),
      ),
    );

    Overlay.of(context).insert(_currentEntry!);

    Future.delayed(notification.duration, () {
      if (_currentEntry != null) {
        _currentEntry!.remove();
        _currentEntry = null;
        _showNext(context);
      }
    });
  }

  static void dismiss() {
    _currentEntry?.remove();
    _currentEntry = null;
    _isShowing = false;
  }

  static void clearQueue() {
    _queue.clear();
    dismiss();
  }
}

enum NotificationType {
  success,
  error,
  warning,
  info,
  chat,
  order,
  transaction,
}

class _NotificationItem {
  final String title;
  final String message;
  final NotificationType type;
  final Duration duration;
  final VoidCallback? onTap;

  _NotificationItem({
    required this.title,
    required this.message,
    required this.type,
    required this.duration,
    this.onTap,
  });
}

class _NotificationWidget extends StatefulWidget {
  final String title;
  final String message;
  final NotificationType type;
  final VoidCallback? onTap;
  final VoidCallback onDismiss;

  const _NotificationWidget({
    required this.title,
    required this.message,
    required this.type,
    this.onTap,
    required this.onDismiss,
  });

  @override
  State<_NotificationWidget> createState() => _NotificationWidgetState();
}

class _NotificationWidgetState extends State<_NotificationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getBackgroundColor() {
    switch (widget.type) {
      case NotificationType.success:
        return const Color(0xFF2B8C61);
      case NotificationType.error:
        return const Color(0xFFD32F2F);
      case NotificationType.warning:
        return const Color(0xFFF57C00);
      case NotificationType.info:
        return const Color(0xFF1976D2);
      case NotificationType.chat:
        return const Color(0xFF003466);
      case NotificationType.order:
        return const Color(0xFF2B8C61);
      case NotificationType.transaction:
        return const Color(0xFF1976D2);
    }
  }

  String _getIcon() {
    switch (widget.type) {
      case NotificationType.success:
        return '✅';
      case NotificationType.error:
        return '❌';
      case NotificationType.warning:
        return '⚠️';
      case NotificationType.info:
        return 'ℹ️';
      case NotificationType.chat:
        return '💬';
      case NotificationType.order:
        return '📦';
      case NotificationType.transaction:
        return '💰';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: GestureDetector(
          onTap: () {
            widget.onTap?.call();
            widget.onDismiss();
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getBackgroundColor(),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Text(_getIcon(), style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.title,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.message,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: widget.onDismiss,
                  child: Icon(Icons.close, color: Colors.white, size: 20),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
