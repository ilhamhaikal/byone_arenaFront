import 'package:flutter/material.dart';
import '../models/activity_item.dart';
import '../widgets/activity_timeline.dart';

/// Convert ActivityItem (API model) to ActivityEvent (UI model).
ActivityEvent activityItemToEvent(ActivityItem item) {
  return ActivityEvent(
    icon: _iconForType(item.type),
    title: item.title,
    subtitle: item.detail,
    amount: item.amount,
    color: _colorForType(item.type),
    time: _formatTime(item.timestamp),
  );
}

IconData _iconForType(String type) {
  switch (type) {
    case 'payment': return Icons.payment_rounded;
    case 'session': return Icons.play_circle_rounded;
    case 'member':
    case 'membership': return Icons.person_add_rounded;
    case 'voucher': return Icons.confirmation_number_rounded;
    case 'console': return Icons.sports_esports_rounded;
    case 'rental':
    case 'daily_rental': return Icons.home_rounded;
    case 'food_order': return Icons.restaurant_rounded;
    case 'setting': return Icons.settings_rounded;
    default: return Icons.notifications_rounded;
  }
}

Color _colorForType(String type) {
  switch (type) {
    case 'payment': return const Color(0xFF10B981);
    case 'session': return const Color(0xFF1E88FF);
    case 'member':
    case 'membership': return const Color(0xFF7C3AED);
    case 'voucher': return const Color(0xFFEC4899);
    case 'console': return const Color(0xFFF59E0B);
    case 'rental':
    case 'daily_rental': return const Color(0xFF00B8FF);
    case 'food_order': return const Color(0xFFF97316);
    case 'setting': return const Color(0xFF64748B);
    default: return const Color(0xFF64748B);
  }
}

String _formatTime(DateTime dt) {
  final now = DateTime.now();
  final diff = now.difference(dt);
  if (diff.inMinutes < 1) return 'Baru saja';
  if (diff.inMinutes < 60) return '${diff.inMinutes} mnt lalu';
  if (diff.inHours < 24) return '${diff.inHours} jam lalu';
  return '${diff.inDays} hari lalu';
}
