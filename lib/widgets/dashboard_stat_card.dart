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
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        // Tanpa scale transform — transform memicu layout ulang semua
        // sibling di Wrap saat resize, menyebabkan OpenGL frame timeout
        // di GTK compositor Linux.
        decoration: BoxDecoration(
          color: const Color(0xFF111321),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _hovered
                ? widget.borderColor.withAlpha(200)
                : widget.borderColor.withAlpha(100),
            width: _hovered ? 1.2 : 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color: widget.borderColor.withAlpha(_hovered ? 70 : 30),
              blurRadius: _hovered ? 28 : 14,
              spreadRadius: _hovered ? 3 : 0,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Stack(
          children: [
            // ── Glassmorphism overlay ──
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: LinearGradient(
                  colors: [
                    widget.gradient.first.withAlpha(14),
                    widget.gradient.last.withAlpha(4),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            // ── Illustration icon (kanan bawah, compact) ──
            Positioned(
              right: -6,
              bottom: -8,
              child: Icon(
                widget.illustrationIcon,
                size: 40,
                color: widget.borderColor.withAlpha(35),
              ),
            ),
            // ── Content ──
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Icon circle ──
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: widget.gradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: widget.borderColor
                              .withAlpha(_hovered ? 120 : 60),
                          blurRadius: _hovered ? 12 : 6,
                          spreadRadius: 0,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(widget.icon, color: Colors.white, size: 13),
                  ),
                  const SizedBox(height: 6),
                  // ── Title ──
                  Text(
                    widget.title,
                    style: TextStyle(
                      color: Colors.white.withAlpha(180),
                      fontSize: 8.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  // ── Value ──
                  Text(
                    widget.value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                      letterSpacing: -0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  // ── Subtitle ──
                  Text(
                    widget.subtitle,
                    style: TextStyle(
                      color: Colors.white.withAlpha(100),
                      fontSize: 8,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
