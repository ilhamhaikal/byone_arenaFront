import 'package:flutter/material.dart';
import '../../config/app_theme.dart';

/// Premium activity timeline with glowing icons and modern layout.
class ActivityTimeline extends StatelessWidget {
  final List<ActivityEvent> events;

  const ActivityTimeline({super.key, required this.events});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF13131F),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withAlpha(10), width: 0.6),
        boxShadow: [
          BoxShadow(
            color: kAccentPurple.withAlpha(8),
            blurRadius: 24,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [kAccentPurple, kNeonPink],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                        color: kAccentPurple.withAlpha(50), blurRadius: 8),
                  ],
                ),
                child: const Icon(Icons.timeline_rounded,
                    color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('AKTIVITAS TERBARU',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700)),
                    Text('Real-time updates',
                        style: TextStyle(
                            color: kTextSecondary, fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.separated(
              itemCount: events.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: 2),
              itemBuilder: (ctx, i) => _TimelineItem(event: events[i]),
            ),
          ),
        ],
      ),
    );
  }
}

class ActivityEvent {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final String time;

  const ActivityEvent({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.time,
  });
}

class _TimelineItem extends StatelessWidget {
  final ActivityEvent event;
  const _TimelineItem({required this.event});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          // Glowing dot + line
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: event.color,
                    boxShadow: [
                      BoxShadow(
                        color: event.color.withAlpha(80),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: event.color.withAlpha(10),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: event.color.withAlpha(25),
                  width: 0.5,
                ),
              ),
              child: Row(
                children: [
                  Icon(event.icon, color: event.color, size: 16),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(event.title,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 1),
                        Text(event.subtitle,
                            style: const TextStyle(
                                color: kTextSecondary,
                                fontSize: 10)),
                      ],
                    ),
                  ),
                  Text(event.time,
                      style: const TextStyle(
                          color: kTextSecondary, fontSize: 10)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
