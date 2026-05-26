import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/session_model.dart';
import '../../providers/session_provider.dart';
import '../../providers/payment_provider.dart';

class EndSessionDialog extends StatefulWidget {
  final SessionModel session;
  final Duration elapsed;
  final double estimatedCost;

  const EndSessionDialog({
    super.key,
    required this.session,
    required this.elapsed,
    required this.estimatedCost,
  });

  @override
  State<EndSessionDialog> createState() => _EndSessionDialogState();
}

class _EndSessionDialogState extends State<EndSessionDialog> {
  final _cashCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _cashCtrl.dispose();
    super.dispose();
  }

  double get _cashReceived => double.tryParse(_cashCtrl.text.replaceAll('.', '')) ?? 0;
  double get _change => (_cashReceived - widget.estimatedCost).clamp(0, double.infinity);
  bool get _canPay => _cashReceived >= widget.estimatedCost;

  Future<void> _finish() async {
    if (_cashCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan jumlah uang yang diterima'), backgroundColor: kErrorColor),
      );
      return;
    }
    if (!_canPay) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Uang yang diterima kurang dari total tagihan'), backgroundColor: kErrorColor),
      );
      return;
    }
    setState(() => _isLoading = true);

    // End the session first
    final sessionProvider = context.read<SessionProvider>();
    final paymentProvider = context.read<PaymentProvider>();
    final endedSession = await sessionProvider.end(widget.session.id);
    if (endedSession == null && mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(sessionProvider.error ?? 'Gagal mengakhiri sesi'),
        backgroundColor: kErrorColor,
      ));
      return;
    }

    // Create payment
    final payment = await paymentProvider.createCash(
          sessionId: widget.session.id,
          cashReceived: _cashReceived,
        );

    setState(() => _isLoading = false);
    if (mounted) {
      Navigator.pop(context);
      if (payment != null) {
        _showReceipt(payment.amount, payment.cashReceived, payment.changeAmount);
      } else {
        // Session ended but payment recording failed — still show receipt
        _showReceipt(widget.estimatedCost, _cashReceived, _change);
      }
    }
  }

  void _showReceipt(double amount, double cash, double change) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.receipt_long, color: kSuccessColor),
            SizedBox(width: 8),
            Text('Struk Pembayaran'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ReceiptRow('Konsol', widget.session.consoleName.isNotEmpty
                ? widget.session.consoleName
                : widget.session.consoleType),
            _ReceiptRow('Pelanggan', widget.session.customerName ?? 'Umum'),
            _ReceiptRow('Durasi', '${widget.elapsed.inMinutes} menit'),
            const Divider(),
            _ReceiptRow('Total Tagihan',
                'Rp ${NumberFormat('#,###', 'id').format(amount.toInt())}'),
            _ReceiptRow('Uang Diterima',
                'Rp ${NumberFormat('#,###', 'id').format(cash.toInt())}'),
            const Divider(),
            _ReceiptRow(
              'Kembalian',
              'Rp ${NumberFormat('#,###', 'id').format(change.toInt())}',
              isBold: true,
              color: kHighlightColor,
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final h = widget.elapsed.inHours;
    final m = widget.elapsed.inMinutes % 60;
    final s = widget.elapsed.inSeconds % 60;

    return AlertDialog(
      title: const Text('Selesaikan Sesi'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Info box
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: kDeepBlack,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: kBorderColor),
              ),
              child: Column(
                children: [
                  _InfoRow('Konsol', widget.session.consoleName.isNotEmpty
                      ? widget.session.consoleName
                      : widget.session.consoleType),
                  const SizedBox(height: 6),
                  _InfoRow('Durasi',
                      '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}',
                      valueColor: kHighlightColor),
                  const SizedBox(height: 6),
                  _InfoRow('Total Tagihan',
                      'Rp ${NumberFormat('#,###', 'id').format(widget.estimatedCost.toInt())}',
                      valueColor: kTextPrimary),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Cash input
            TextField(
              controller: _cashCtrl,
              decoration: const InputDecoration(
                labelText: 'Uang Diterima (Rp)',
                prefixIcon: Icon(Icons.payments_outlined),
              ),
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
            ),
            if (_cashCtrl.text.isNotEmpty && _cashReceived >= widget.estimatedCost) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: kSuccessColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: kSuccessColor.withAlpha(80)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('KEMBALIAN', style: TextStyle(color: kTextPrimary, fontWeight: FontWeight.bold)),
                    Text(
                      'Rp ${NumberFormat('#,###', 'id').format(_change.toInt())}',
                      style: const TextStyle(color: kSuccessColor, fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
        ElevatedButton.icon(
          onPressed: _isLoading ? null : _finish,
          icon: const Icon(Icons.check_circle_outline),
          label: _isLoading
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Bayar'),
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
        Text(value, style: TextStyle(color: valueColor ?? kTextPrimary, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;
  final Color? color;
  const _ReceiptRow(this.label, this.value, {this.isBold = false, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: kTextSecondary, fontSize: 13)),
          Text(value,
              style: TextStyle(
                color: color ?? kTextPrimary,
                fontSize: 13,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              )),
        ],
      ),
    );
  }
}
