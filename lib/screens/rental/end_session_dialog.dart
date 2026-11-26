import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/payment_model.dart';
import '../../providers/payment_provider.dart';
import '../../providers/session_provider.dart';
import '../../services/console_service.dart';

import '../../utils/app_dialog.dart';
import '../../widgets/payment_method_selector.dart';
class EndSessionDialog extends StatefulWidget {
  final String sessionId;
  final String consoleId;
  final String consoleName;
  final String consoleType;
  final String? customerName;
  final Duration elapsed;
  final int pendingMinutes;
  final double pricePerHour;
  /// true = tombol "Simpan Waktu" (akhiri sesi + simpan sisa 24 jam).
  final bool saveMode;
  /// Member memakai Bank Waktu; note simpan waktu non-member tidak ditampilkan.
  final bool isMember;
  /// Sisa menit saat dialog dibuka (untuk informasi simpan waktu).
  final int remainingMinutes;
  /// Durasi berbayar; sesi gratis tidak menampilkan info simpan waktu.
  final int paidDurationMinutes;
  /// Paket: masa simpan 7 hari; reguler: 24 jam.
  final bool isPackage;

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
    this.saveMode = false,
    this.isMember = false,
    this.remainingMinutes = 0,
    this.paidDurationMinutes = 0,
    this.isPackage = false,
  });

  @override
  State<EndSessionDialog> createState() => _EndSessionDialogState();
}

class _EndSessionDialogState extends State<EndSessionDialog> {
  bool _isLoading = false;
  bool _isCheckingPayment = true;
  // Semua payment yang masih pending untuk sesi ini (bisa > 1 kalau sesi
  // pernah di-extend beberapa kali tanpa dibayar langsung).
  List<PaymentModel> _pendingPayments = [];
  double _totalPending = 0;
  // true hanya jika data pending didapat dari estimasi fallback (endpoint
  // agregat gagal dipanggil) — bukan dari payment record yang sebenarnya.
  bool _isEstimate = false;
  final _cashCtrl = TextEditingController();
  String? _paymentError;
  // Metode pembayaran pelunasan: cash (default) atau qris.
  String _paymentMethod = PaymentMethodSelector.cash;
  bool get _isCash => _paymentMethod == PaymentMethodSelector.cash;

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
    // 1. Sumber kebenaran: ringkasan SEMUA payment sesi ini (base + semua
    //    perpanjangan). Jangan pernah hitung total sendiri di frontend —
    //    lihat docs/FRONTEND_SESSION_PAYMENT_FIX_GUIDE.md.
    final summary = await context.read<PaymentProvider>().getAllBySession(widget.sessionId);
    if (summary != null) {
      if (!mounted) return;
      setState(() {
        _pendingPayments = summary.pendingPayments;
        // Dibulatkan ke rupiah utuh — mencegah selisih fraksional yang
        // membuat validasi "uang kurang" salah meski cash sama dengan total
        // yang ditampilkan (lihat juga fix di stored procedure pricing).
        _totalPending = summary.totalPending.roundToDouble();
        _isEstimate = false;
        _isCheckingPayment = false;
      });
      return;
    }

    // 2. Fallback (mis. endpoint belum tersedia / gagal jaringan): estimasi
    //    kasar dari pendingMinutes lokal. Ini TIDAK akurat untuk sesi dengan
    //    lebih dari 1 payment pending — hanya dipakai sebagai jaring pengaman.
    double pendingAmount = 0;
    if (widget.pendingMinutes > 0) {
      try {
        final pricePreview = await ConsoleService().getPrice(
          widget.consoleId,
          durationMinutes: widget.pendingMinutes,
        );
        pendingAmount = pricePreview.baseAmount;
      } catch (_) {
        pendingAmount = widget.pendingMinutes / 60.0 * widget.pricePerHour;
      }
      pendingAmount = pendingAmount.roundToDouble();
    }

    if (!mounted) return;
    setState(() {
      _isCheckingPayment = false;
      _pendingPayments = [];
      _totalPending = pendingAmount;
      _isEstimate = pendingAmount > 0;
    });
  }

  Future<void> _payPending() async {
    // Validasi uang tunai hanya untuk metode Tunai. QRIS tidak perlu uang tunai.
    double cash = 0;
    if (_isCash) {
      final cashText = _cashCtrl.text.trim();
      if (cashText.isEmpty) {
        setState(() => _paymentError = 'Masukkan jumlah uang tunai');
        return;
      }
      cash = double.tryParse(cashText) ?? 0;
      if (cash <= 0) {
        setState(() => _paymentError = 'Jumlah tidak valid');
        return;
      }
      final minAmount = _totalPending > 0 ? _totalPending : 1.0;
      if (cash < minAmount) {
        setState(() => _paymentError = 'Uang kurang — minimal Rp ${NumberFormat('#,###', 'id').format(minAmount.toInt())}');
        return;
      }
    }

    setState(() {
      _isLoading = true;
      _paymentError = null;
    });

    final paymentProvider = context.read<PaymentProvider>();
    bool success = true;
    double changeAmount = 0;

    if (_pendingPayments.isNotEmpty) {
      // Ada payment record pending yang valid (dari GET /sessions/{id}/payments)
      // — konfirmasi SEMUA satu per satu, bukan hanya yang pertama/terakhir.
      double remainingCash = cash;
      for (var i = 0; i < _pendingPayments.length; i++) {
        final p = _pendingPayments[i];
        final isLast = i == _pendingPayments.length - 1;
        final cashForThis = isLast ? remainingCash : p.amount;
        final confirmed = await paymentProvider.confirmPayment(
          paymentId: p.id,
          cashReceived: _isCash ? cashForThis : null,
          paymentMethod: _paymentMethod,
        );
        if (confirmed == null) {
          success = false;
          break;
        }
        remainingCash -= p.amount;
        if (isLast) changeAmount = confirmed.changeAmount;
      }
    } else if (_totalPending > 0) {
      // Fallback: tidak ada payment id yang valid (estimasi) — buat payment baru
      final confirmed = await paymentProvider.createCash(
        sessionId: widget.sessionId,
        cashReceived: _isCash ? cash : _totalPending,
        paymentMethod: _paymentMethod,
      );
      if (confirmed == null) {
        success = false;
      } else {
        changeAmount = confirmed.changeAmount;
      }
    }

    if (!mounted) return;

    if (success) {
      setState(() {
        _pendingPayments = [];
        _totalPending = 0;
        _isLoading = false;
        _cashCtrl.clear();
      });
      showSuccessDialog(_isCash
          ? 'Pembayaran berhasil — Kembalian: Rp ${NumberFormat('#,###', 'id').format(changeAmount.toInt())}'
          : 'Pembayaran ${_paymentMethod == PaymentMethodSelector.qris ? 'QRIS' : 'non-tunai'} berhasil');
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
    final endedSession = widget.saveMode
        ? await sessionProvider.saveTime(widget.sessionId)
        : await sessionProvider.end(widget.sessionId);
    setState(() => _isLoading = false);
    if (!mounted) return;
    if (endedSession == null) {
      showErrorDialog(sessionProvider.error ??
          (widget.saveMode ? 'Gagal menyimpan waktu' : 'Gagal mengakhiri sesi'));
      return;
    }

    final savedRecovery = endedSession.remainingRecoveryMinutes;
    final savedBank = endedSession.timeBankEarnedMinutes;
    final expires = endedSession.savedTimeExpiresAt;
    final expiryText = expires != null
        ? ' Berlaku sampai ${DateFormat('dd/MM/yyyy HH:mm').format(expires.toLocal())}.'
        : '';

    Navigator.pop(context);

    if (widget.saveMode && savedRecovery > 0) {
      showSuccessDialog(
        'Sisa waktu berhasil disimpan.\n\n'
        '$savedRecovery menit.$expiryText',
        title: 'Waktu Disimpan',
      );
    } else if (savedRecovery > 0) {
      showSuccessDialog(
        'Sesi diakhiri.\n\n'
        '$savedRecovery menit sisa disimpan otomatis.$expiryText',
        title: 'Sesi Diakhiri',
      );
    } else if (savedBank > 0) {
      showSuccessDialog(
        'Sesi berhasil diakhiri.\n\n'
        '$savedBank menit sisa disimpan ke Bank Waktu member.',
        title: 'Sesi Diakhiri',
      );
    } else {
      showSuccessDialog('Sesi berhasil diakhiri.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final h = widget.elapsed.inHours;
    final m = widget.elapsed.inMinutes % 60;
    final s = widget.elapsed.inSeconds % 60;
    final saveableMinutes = widget.paidDurationMinutes > 0
        ? (widget.paidDurationMinutes - widget.elapsed.inMinutes)
            .clamp(0, widget.paidDurationMinutes)
        : 0;
    final saveWindowText = widget.isPackage ? '7 hari' : '24 jam';

    return AlertDialog(
      title: Text(widget.saveMode ? 'Simpan Waktu' : 'Akhiri Sesi'),
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
                    if (!widget.isMember &&
                        saveableMinutes > 0) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: kSuccessColor.withAlpha(18),
                          borderRadius: BorderRadius.circular(8),
                          border:
                              Border.all(color: kSuccessColor.withAlpha(80)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.schedule_rounded,
                                color: kSuccessColor, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                widget.saveMode
                                    ? 'Sesi akan diakhiri dan sisa ±$saveableMinutes menit berbayar disimpan selama $saveWindowText.'
                                    : 'Sisa ±$saveableMinutes menit berbayar akan otomatis disimpan selama $saveWindowText (non-member).',
                                style: const TextStyle(
                                  color: kTextSecondary,
                                  fontSize: 11,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),

                    // ── Pembayaran Pending ──
                    if (_totalPending > 0) ...[
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
        if (_totalPending > 0)
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
                : Text(widget.saveMode ? 'Bayar & Simpan' : 'Bayar & Akhiri'),
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
                : Text(widget.saveMode ? 'Simpan Waktu' : 'Akhiri Sesi'),
          ),
      ],
    );
  }

  Widget _buildPendingPayment() {
    final fmt = NumberFormat('#,###', 'id');
    final hasAmount = _totalPending > 0;
    final count = _pendingPayments.length;

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
              Expanded(
                child: Text(
                  count > 1 ? 'PEMBAYARAN TERTUNDA ($count TAGIHAN)' : 'PEMBAYARAN TERTUNDA',
                  style: const TextStyle(
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
                const Text('Total Tagihan',
                    style: TextStyle(color: kTextSecondary, fontSize: 13)),
                Text(
                  'Rp ${fmt.format(_totalPending.toInt())}',
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
          if (_isEstimate) ...[
            const SizedBox(height: 6),
            const Text(
              '(Estimasi — data pembayaran pasti tidak berhasil diambil dari server)',
              style: TextStyle(color: kTextSecondary, fontSize: 11, fontStyle: FontStyle.italic),
            ),
          ],
          const SizedBox(height: 14),
          // ── Metode Pembayaran ──
          PaymentMethodSelector(
            value: _paymentMethod,
            onChanged: (v) => setState(() {
              _paymentMethod = v;
              _paymentError = null;
            }),
          ),
          const SizedBox(height: 12),
          // Cash input — hanya untuk metode Tunai
          if (_isCash)
            TextField(
              controller: _cashCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(color: kTextPrimary, fontSize: 15),
              decoration: InputDecoration(
                labelText: 'Uang Tunai (Rp)',
                hintText: hasAmount ? 'Minimal Rp ${fmt.format(_totalPending.toInt())}' : 'Masukkan jumlah',
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
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: kAccentPurple.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: kAccentPurple.withAlpha(60)),
              ),
              child: const Row(children: [
                Icon(Icons.qr_code_2_rounded, size: 16, color: kAccentPurple),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Pembayaran via QRIS — tidak perlu uang tunai.',
                    style: TextStyle(color: kAccentPurple, fontSize: 12),
                  ),
                ),
              ]),
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
    if (_totalPending > 0) {
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
