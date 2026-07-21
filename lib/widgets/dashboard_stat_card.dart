import 'package:flutter/material.dart';

/// Premium cyber gaming stat card — reusable, animated, glassmorphism.
///
/// Usage:
/// ```dart
/// DashboardStatCard(
///   title: 'SESI AKTIF',
///   value: '24',
///   subtitle: 'Realtime',
///   icon: Icons.play_circle,
///   illustrationIcon: Icons.show_chart,
///   gradient: const [Color(0xFF00B8FF), Color(0xFF2962FF)],
///   borderColor: const Color(0xFF00B8FF),
/// )
/// ```
class DashboardStatCard extends StatefulWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final IconData illustrationIcon;
  final List<Color> gradient;
  final Color borderColor;

  const DashboardStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.illustrationIcon,
    required this.gradient,
    required this.borderColor,
  });

  @override
  State<DashboardStatCard> createState() => _DashboardStatCardState();
}

class _DashboardStatCardState extends State<DashboardStatCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        transform: _hovered
            ? (Matrix4.identity()..scale(1.03))
            : Matrix4.identity(),
        decoration: BoxDecoration(
          color: const Color(0xFF111321),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _hovered
                ? widget.borderColor.withAlpha(200)
                : widget.borderColor.withAlpha(90),
            width: _hovered ? 1.2 : 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color: widget.borderColor.withAlpha(_hovered ? 55 : 25),
              blurRadius: _hovered ? 36 : 24,
              spreadRadius: _hovered ? 4 : 1,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: widget.borderColor.withAlpha(_hovered ? 20 : 8),
              blurRadius: _hovered ? 60 : 40,
              spreadRadius: _hovered ? 8 : 0,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            // ── Glassmorphism overlay ──
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [
                    widget.gradient.first.withAlpha(16),
                    widget.gradient.last.withAlpha(6),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            // ── Illustration icon (kanan bawah, large, low opacity) ──
            Positioned(
              right: -8,
              bottom: -10,
              child: Icon(
                widget.illustrationIcon,
                size: 72,
                color: widget.borderColor.withAlpha(55),
              ),
            ),
            // ── Content ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                  // ── Icon circle ──
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: widget.gradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: widget.borderColor.withAlpha(_hovered ? 120 : 60),
                          blurRadius: _hovered ? 18 : 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Icon(widget.icon, color: Colors.white, size: 18),
                  ),
                  const SizedBox(height: 12),
                  // ── Title ──
                  Text(
                    widget.title,
                    style: TextStyle(
                      color: Colors.white.withAlpha(230),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // ── Value ──
                  Text(
                    widget.value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      height: 1.0,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // ── Subtitle ──
                  Text(
                    widget.subtitle,
                    style: TextStyle(
                      color: Colors.white.withAlpha(120),
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
