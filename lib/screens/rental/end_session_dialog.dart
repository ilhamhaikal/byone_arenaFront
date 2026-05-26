import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../providers/session_provider.dart';

class EndSessionDialog extends StatefulWidget {
  final String sessionId;
  final String consoleName;
  final String consoleType;
  final String? customerName;
  final Duration elapsed;

  const EndSessionDialog({
    super.key,
    required this.sessionId,
    required this.consoleName,
    required this.consoleType,
    this.customerName,
    required this.elapsed,
  });

  @override
  State<EndSessionDialog> createState() => _EndSessionDialogState();
}

class _EndSessionDialogState extends State<EndSessionDialog> {
  bool _isLoading = false;

  Future<void> _finish() async {
    setState(() => _isLoading = true);
    final sessionProvider = context.read<SessionProvider>();
    final endedSession = await sessionProvider.end(widget.sessionId);
    setState(() => _isLoading = false);
    if (mounted) {
      if (endedSession != null) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sesi berhasil diakhiri.'),
            backgroundColor: kSuccessColor,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(sessionProvider.error ?? 'Gagal mengakhiri sesi'),
          backgroundColor: kErrorColor,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final h = widget.elapsed.inHours;
    final m = widget.elapsed.inMinutes % 60;
    final s = widget.elapsed.inSeconds % 60;

    return AlertDialog(
      title: const Text('Akhiri Sesi'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: kDeepBlack,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: kBorderColor),
              ),
              child: Column(
                children: [
                  _InfoRow(
                    'Konsol',
                    widget.consoleName.isNotEmpty
                        ? widget.consoleName
                        : widget.consoleType,
                  ),
                  const SizedBox(height: 6),
                  _InfoRow('Pelanggan', widget.customerName ?? 'Umum'),
                  const SizedBox(height: 6),
                  _InfoRow(
                    'Waktu Berjalan',
                    '${h.toString().padLeft(2, '0')}:'
                        '${m.toString().padLeft(2, '0')}:'
                        '${s.toString().padLeft(2, '0')}',
                    valueColor: kPrimaryBlue,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: kSuccessColor.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: kSuccessColor.withAlpha(60)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle, color: kSuccessColor, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Pembayaran sudah dilakukan di awal sesi.',
                      style: TextStyle(color: kTextPrimary, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(backgroundColor: kErrorColor),
          onPressed: _isLoading ? null : _finish,
          icon: const Icon(Icons.stop_circle_outlined),
          label: _isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Text('Akhiri Sesi'),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _InfoRow(this.label, this.value, {this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: kTextSecondary)),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? kTextPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
