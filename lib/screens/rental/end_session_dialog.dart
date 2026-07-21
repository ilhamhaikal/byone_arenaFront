import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/payment_model.dart';
import '../../providers/payment_provider.dart';
import '../../providers/session_provider.dart';
import '../../services/console_service.dart';

class EndSessionDialog extends StatefulWidget {
  final String sessionId;
  final String consoleId;
  final String consoleName;
  final String consoleType;
  final String? customerName;
  final Duration elapsed;
  final int pendingMinutes;
  final double pricePerHour;

  const EndSessionDialog({
    super.key,
    required this.sessionId,
    required this.consoleId,
    required this.consoleName,
    required this.consoleType,
    this.customerName,
    required this.elapsed,
    this.pendingMinutes = 0,
    this.pricePerHour = 0,
  });

  @override
  State<EndSessionDialog> createState() => _EndSessionDialogState();
}

class _EndSessionDialogState extends State<EndSessionDialog> {
  bool _isLoading = false;
  bool _isCheckingPayment = true;
  PaymentModel? _pendingPayment;
  final _cashCtrl = TextEditingController();
  String? _paymentError;

  @override
  void initState() {
    super.initState();
    // Defer API call agar tidak trigger notifyListeners saat build phase
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _checkPendingPayment();
    });
  }

  @override
  void dispose() {
    _cashCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkPendingPayment() async {
    PaymentModel? apiPayment;
    double pendingAmount = 0;

    // 1. Coba fetch payment dari API
    try {
      apiPayment = await context.read<PaymentProvider>().getBySession(widget.sessionId);
    } catch (_) {}

    // 2. Jika ada pendingMinutes, hitung harga asli dari API price preview
    if (widget.pendingMinutes > 0) {
      try {
        final pricePreview = await ConsoleService().getPrice(
          widget.consoleId,
          durationMinutes: widget.pendingMinutes,
        );
        pendingAmount = pricePreview.baseAmount;
      } catch (_) {
        // Fallback: estimasi kasar
        pendingAmount = widget.pendingMinutes / 60.0 * widget.pricePerHour;
      }
    }

    if (!mounted) return;

    setState(() {
      _isCheckingPayment = false;

      // Prioritaskan payment pending dari API
      if (apiPayment != null && apiPayment.isPending) {
        _pendingPayment = apiPayment;
        return;
      }

      // Jika ada pendingMinutes, buat placeholder dengan amount asli
      if (widget.pendingMinutes > 0 && pendingAmount > 0) {
        _pendingPayment = PaymentModel(
          id: '', // selalu buat payment baru, hindari salah konfirmasi
          sessionId: widget.sessionId,
          amount: pendingAmount,
          cashReceived: 0,
          changeAmount: 0,
          paymentMethod: 'cash',
          paymentStatus: 'pending',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }
    });
  }

  Future<void> _payPending() async {
    if (_pendingPayment == null) return;
    final cashText = _cashCtrl.text.trim();
    if (cashText.isEmpty) {
      setState(() => _paymentError = 'Masukkan jumlah uang tunai');
      return;
    }
    final cash = double.tryParse(cashText);
    if (cash == null || cash <= 0) {
      setState(() => _paymentError = 'Jumlah tidak valid');
      return;
    }
    final minAmount = _pendingPayment!.amount > 0 ? _pendingPayment!.amount : 1.0;
    if (cash < minAmount) {
      setState(() => _paymentError = 'Uang kurang — minimal Rp ${NumberFormat('#,###', 'id').format(minAmount.toInt())}');
      return;
    }

    setState(() {
      _isLoading = true;
      _paymentError = null;
    });

    final paymentProvider = context.read<PaymentProvider>();
    PaymentModel? confirmed;

    if (_pendingPayment!.id.isNotEmpty) {
      // Konfirmasi pembayaran pending yang sudah ada
      confirmed = await paymentProvider.confirmPayment(
        paymentId: _pendingPayment!.id,
        cashReceived: cash,
      );
    } else {
      // Buat pembayaran baru (pending payment tidak ditemukan via API)
      confirmed = await paymentProvider.createCash(
        sessionId: widget.sessionId,
        cashReceived: cash,
      );
    }

    if (!mounted) return;

    if (confirmed != null) {
      setState(() {
        _pendingPayment = null;
        _isLoading = false;
        _cashCtrl.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Pembayaran berhasil — Kembalian: Rp ${NumberFormat('#,###', 'id').format(confirmed.changeAmount.toInt())}',
          ),
          backgroundColor: kSuccessColor,
        ),
      );
      // Lanjut akhiri sesi
      await _finish();
    } else {
      setState(() {
        _isLoading = false;
        _paymentError = paymentProvider.error ?? 'Gagal konfirmasi pembayaran';
      });
    }
  }

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
        width: 380,
        child: _isCheckingPayment
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(color: kPrimaryBlue, strokeWidth: 3),
                ),
              )
            : SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Info sesi ──
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

                    // ── Pembayaran Pending ──
                    if (_pendingPayment != null) ...[
                      _buildPendingPayment(),
                      const SizedBox(height: 16),
                    ],

                    // ── Status pembayaran ──
                    _buildPaymentStatus(),
                  ],
                ),
              ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        if (_pendingPayment != null)
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: kPrimaryBlue),
            onPressed: _isLoading ? null : _payPending,
            icon: const Icon(Icons.payment_rounded, size: 18),
            label: _isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Text('Bayar & Akhiri'),
          )
        else
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

  Widget _buildPendingPayment() {
    final p = _pendingPayment!;
    final fmt = NumberFormat('#,###', 'id');
    final hasAmount = p.amount > 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kWarningColor.withAlpha(18),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kWarningColor.withAlpha(80), width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: kWarningColor, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'PEMBAYARAN TERTUNDA',
                  style: TextStyle(
                    color: kWarningColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Amount
          if (hasAmount)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Jumlah Tagihan',
                    style: TextStyle(color: kTextSecondary, fontSize: 13)),
                Text(
                  'Rp ${fmt.format(p.amount.toInt())}',
                  style: const TextStyle(
                    color: kTextPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            )
          else
            const Text(
              'Jumlah pending tidak diketahui. Silakan input jumlah manual.',
              style: TextStyle(color: kTextSecondary, fontSize: 12),
            ),
          const SizedBox(height: 14),
          // Cash input
          TextField(
            controller: _cashCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(color: kTextPrimary, fontSize: 15),
            decoration: InputDecoration(
              labelText: 'Uang Tunai (Rp)',
              hintText: hasAmount ? 'Minimal Rp ${fmt.format(p.amount.toInt())}' : 'Masukkan jumlah',
              labelStyle: const TextStyle(color: kTextSecondary, fontSize: 13),
              hintStyle: TextStyle(color: kTextSecondary.withAlpha(100), fontSize: 12),
              filled: true,
              fillColor: kDeepBlack,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: kBorderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: kBorderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: kWarningColor),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              suffixIcon: _cashCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 16),
                      onPressed: () {
                        _cashCtrl.clear();
                        setState(() => _paymentError = null);
                      },
                    )
                  : null,
            ),
            onChanged: (_) {
              setState(() => _paymentError = null);
            },
          ),
          if (_paymentError != null) ...[
            const SizedBox(height: 8),
            Text(
              _paymentError!,
              style: const TextStyle(color: kErrorColor, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentStatus() {
    // Kalau ada pending payment, jangan tampilkan "sudah dilakukan"
    if (_pendingPayment != null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
