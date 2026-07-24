import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/console_model.dart';
import '../../models/console_overview_model.dart';
import '../../models/customer_model.dart';
import '../../models/price_preview_model.dart';
import '../../providers/console_provider.dart';
import '../../providers/customer_provider.dart';
import '../../providers/session_provider.dart';
import '../../providers/voucher_provider.dart';
import '../../services/console_service.dart';
import '../../models/voucher_model.dart';

class StartSessionDialog extends StatefulWidget {
  /// Jika diisi, konsol sudah terpilih dari panel (skip dropdown)
  final ConsoleOverviewModel? preselectedConsole;

  const StartSessionDialog({super.key, this.preselectedConsole});

  @override
  State<StartSessionDialog> createState() => _StartSessionDialogState();
}

class _StartSessionDialogState extends State<StartSessionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _customerSearchCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _cashCtrl = TextEditingController();
  final _voucherCodeCtrl = TextEditingController();
  final _hoursCtrl = TextEditingController(text: '0');
  final _minutesCtrl = TextEditingController(text: '0');

  ConsoleModel? _selectedConsole;
  CustomerModel? _selectedCustomer;
  bool _isLoading = false;
  bool _loadingConsoles = false;
  bool _isValidatingVoucher = false;
  List<ConsoleModel> _availableConsoles = [];
  VoucherModel? _voucher;
  String? _voucherError;

  // ── Price preview dari backend ──
  final ConsoleService _consoleService = ConsoleService();
  PricePreviewModel? _pricePreview;
  bool _loadingPrice = false;

  bool get _hasPreselected => widget.preselectedConsole != null;

  /// Durasi dalam menit dari input jam & menit
  int get _bookedDurationMinutes {
    final h = int.tryParse(_hoursCtrl.text) ?? 0;
    final m = int.tryParse(_minutesCtrl.text) ?? 0;
    return (h * 60 + m).clamp(1, 10080); // min 1 menit, max 7 hari
  }

  /// Label durasi untuk tampilan
  String get _durationLabel {
    final m = _bookedDurationMinutes;
    if (m < 60) return '$m menit';
    final h = m ~/ 60;
    final rem = m % 60;
    return rem > 0 ? '$h jam $rem menit' : '$h jam';
  }

  double get _pricePerHour => _hasPreselected
      ? widget.preselectedConsole!.pricePerHour
      : (_selectedConsole?.pricePerHour ?? 0);

  /// Gunakan harga dari backend (tier-aware), fallback ke kalkulasi manual
  double get _baseAmount => _pricePreview?.baseAmount ?? _subtotal;

  /// Subtotal manual (flat rate) — hanya fallback
  double get _subtotal => _pricePerHour * (_bookedDurationMinutes / 60);

  /// Hitung diskon dari voucher (jika valid dan memenuhi minPurchase)
  double get _discountAmount {
    if (_voucher == null) return 0;
    final base = _baseAmount;
    if (_voucher!.minPurchase != null && base < _voucher!.minPurchase!) return 0;
    switch (_voucher!.discountType) {
      case 'fixed_amount':
        return _voucher!.discountValue;
      case 'percentage':
        final d = base * _voucher!.discountValue / 100;
        if (_voucher!.maxDiscount != null &&
            _voucher!.maxDiscount! > 0 &&
            d > _voucher!.maxDiscount!) {
          return _voucher!.maxDiscount!;
        }
        return d;
      default:
        return 0;
    }
  }

  double get _finalPrice => (_baseAmount - _discountAmount).clamp(0, double.infinity);
  double get _cashReceivedAmt =>
      double.tryParse(_cashCtrl.text.replaceAll(',', '')) ?? 0;
  double get _change => (_cashReceivedAmt - _finalPrice).clamp(0, double.infinity);
  bool get _isEnough => _finalPrice > 0 && _cashReceivedAmt >= _finalPrice;

  @override
  void initState() {
    super.initState();
    if (!_hasPreselected) _loadAvailableConsoles();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchPricePreview());
  }

  @override
  void dispose() {
    _customerSearchCtrl.dispose();
    _notesCtrl.dispose();
    _cashCtrl.dispose();
    _voucherCodeCtrl.dispose();
    _hoursCtrl.dispose();
    _minutesCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAvailableConsoles() async {
    setState(() => _loadingConsoles = true);
    try {
      final provider = context.read<ConsoleProvider>();
      await provider.loadAvailable();
      setState(() => _availableConsoles = provider.available);
    } catch (_) {
      setState(() => _availableConsoles = []);
    } finally {
      setState(() => _loadingConsoles = false);
    }
  }

  /// Panggil GET /api/v1/consoles/{id}/price untuk kalkulasi tier-aware
  Future<void> _fetchPricePreview() async {
    final consoleId = _hasPreselected
        ? widget.preselectedConsole!.id
        : _selectedConsole?.id;
    if (consoleId == null || _bookedDurationMinutes < 1) return;

    setState(() => _loadingPrice = true);
    try {
      final preview = await _consoleService.getPrice(
        consoleId,
        durationMinutes: _bookedDurationMinutes,
        voucherCode: _voucherCodeCtrl.text.trim().isNotEmpty
            ? _voucherCodeCtrl.text.trim()
            : null,
        customerId: _selectedCustomer?.id,
      );
      if (mounted) setState(() => _pricePreview = preview);
    } catch (_) {
      _pricePreview = null; // fallback ke kalkulasi manual
    } finally {
      if (mounted) setState(() => _loadingPrice = false);
    }
  }

  Future<void> _validateVoucher() async {
    final code = _voucherCodeCtrl.text.trim();
    if (code.isEmpty) {
      setState(() {
        _voucher = null;
        _voucherError = null;
      });
      return;
    }
    setState(() => _isValidatingVoucher = true);
    final voucher = await context.read<VoucherProvider>().validateVoucherByCode(code);
    if (!mounted) return;
    setState(() {
      _isValidatingVoucher = false;
      if (voucher != null && voucher.isAvailable) {
        _voucher = voucher;
        _voucherError = null;
      } else {
        _voucher = null;
        _voucherError = 'Voucher tidak valid atau sudah tidak aktif';
      }
    });
  }

  Future<void> _start() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_hasPreselected && _selectedConsole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Pilih konsol terlebih dahulu'),
            backgroundColor: kErrorColor),
      );
      return;
    }
    // Validate cash amount
    if (_cashCtrl.text.trim().isEmpty || _cashReceivedAmt <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Masukkan jumlah uang yang diterima'),
        backgroundColor: kErrorColor,
      ));
      return;
    }
    if (!_isEnough) {
      final fmt = NumberFormat('#,###', 'id');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            'Uang kurang! Total: Rp ${fmt.format(_finalPrice.toInt())}'),
        backgroundColor: kErrorColor,
      ));
      return;
    }

    setState(() => _isLoading = true);

    final consoleId = _hasPreselected
        ? widget.preselectedConsole!.id
        : _selectedConsole!.id;

    final session = await context.read<SessionProvider>().start(
          consoleId: consoleId,
          bookedDurationMinutes: _bookedDurationMinutes,
          cashReceived: _cashReceivedAmt,
          customerId: _selectedCustomer?.id,
          notes:
              _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
          voucherCode: _voucherCodeCtrl.text.trim().isEmpty
              ? null
              : _voucherCodeCtrl.text.trim(),
        );

    setState(() => _isLoading = false);
    if (mounted) {
      if (session != null) {
        final fmt = NumberFormat('#,###', 'id');
        final kembalian = _change;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              'Sesi dimulai! Kembalian: Rp ${fmt.format(kembalian.toInt())}'),
          backgroundColor: kSuccessColor,
          duration: const Duration(seconds: 5),
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              context.read<SessionProvider>().error ?? 'Gagal memulai sesi'),
          backgroundColor: kErrorColor,
        ));
      }
    }
  }

  LinearGradient _typeGrad(String type) {
    switch (type) {
      case 'PS5':
        return kGradientPurple;
      case 'PS3':
      case 'Switch':
        return kGradientPink;
      case 'AndroidTV':
        return kGradientGreen;
      default:
        return kGradientBlue;
    }
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'PS5':
        return kAccentPurple;
      case 'PS3':
      case 'Switch':
        return kNeonPink;
      case 'AndroidTV':
        return kSuccessColor;
      default:
        return kPrimaryBlue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(
        locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return AlertDialog(
      title: const Text('Mulai Sesi Baru'),
      content: SizedBox(
        width: 440,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Pilih Konsol ─────────────────────────────────────────
                const Text('Konsol',
                    style: TextStyle(color: kTextSecondary, fontSize: 12)),
                const SizedBox(height: 8),
                if (_hasPreselected)
                  _buildPreselectedConsole(fmt)
                else
                  _buildConsoleDropdown(),

                const SizedBox(height: 16),
                const Divider(color: kBorderColor),

                // ── Durasi Sewa ───────────────────────────────────────────
                const Text('Durasi Sewa',
                    style: TextStyle(color: kTextSecondary, fontSize: 12)),
                const SizedBox(height: 8),
                _buildDurationInput(fmt),

                const SizedBox(height: 16),
                const Divider(color: kBorderColor),

                // ── Pelanggan (opsional) ──────────────────────────────────
                const Text('Pelanggan (Opsional)',
                    style: TextStyle(color: kTextSecondary, fontSize: 12)),
                const SizedBox(height: 8),
                if (_selectedCustomer != null) _buildSelectedCustomer(),
                _buildCustomerSearch(),

                const SizedBox(height: 12),
                // ── Catatan ───────────────────────────────────────────────
                TextField(
                  controller: _notesCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Catatan (opsional)',
                    prefixIcon: Icon(Icons.notes_outlined),
                  ),
                  maxLines: 2,
                ),

                const SizedBox(height: 16),
                const Divider(color: kBorderColor),

                // ── Ringkasan Biaya ───────────────────────────────────────
                const Text('Ringkasan Biaya',
                    style: TextStyle(color: kTextSecondary, fontSize: 12)),
                const SizedBox(height: 8),
                _buildCostSummary(fmt),

                const SizedBox(height: 16),
                const Divider(color: kBorderColor),

                // ── Pembayaran Tunai ──────────────────────────────────────
                const Text('Pembayaran Tunai',
                    style: TextStyle(color: kTextSecondary, fontSize: 12)),
                const SizedBox(height: 8),
                StatefulBuilder(
                  builder: (ctx, setSt) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _cashCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Uang Diterima *',
                          prefixIcon: Icon(Icons.payments_outlined),
                          hintText: '0',
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Jumlah uang wajib diisi';
                          }
                          if (_cashReceivedAmt < _finalPrice) {
                            return 'Uang kurang dari total';
                          }
                          return null;
                        },
                        onChanged: (_) => setSt(() {}),
                      ),
                      if (_cashReceivedAmt > 0 && _finalPrice > 0) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: _isEnough
                                ? kSuccessColor.withAlpha(25)
                                : kErrorColor.withAlpha(25),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _isEnough
                                  ? kSuccessColor.withAlpha(80)
                                  : kErrorColor.withAlpha(80),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _isEnough ? 'Kembalian' : 'Kurang',
                                style: TextStyle(
                                  color: _isEnough
                                      ? kSuccessColor
                                      : kErrorColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                'Rp ${fmt.format(_isEnough ? _change.toInt() : (_finalPrice - _cashReceivedAmt).toInt())}',
                                style: TextStyle(
                                  color: _isEnough
                                      ? kSuccessColor
                                      : kErrorColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),
                      // Voucher field with validation
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _voucherCodeCtrl,
                              decoration: InputDecoration(
                                labelText: 'Kode Voucher (opsional)',
                                prefixIcon: _isValidatingVoucher
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: Padding(
                                          padding: EdgeInsets.all(12),
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        ),
                                      )
                                    : const Icon(Icons.discount_outlined),
                                suffixIcon: _voucher != null
                                    ? const Icon(Icons.check_circle, color: kSuccessColor, size: 18)
                                    : _voucherError != null
                                        ? const Icon(Icons.error, color: kErrorColor, size: 18)
                                        : null,
                                hintText: 'DISKON10',
                              ),
                              textCapitalization: TextCapitalization.characters,
                              onChanged: (_) {
                                // Debounce: validate after 500ms of no typing
                                setState(() {
                                  _voucher = null;
                                  _voucherError = null;
                                });
                              },
                              onSubmitted: (_) => _validateVoucher(),
                            ),
                          ),
                          if (_voucherCodeCtrl.text.trim().isNotEmpty) ...[
                            const SizedBox(width: 6),
                            InkWell(
                              onTap: () {
                                _voucherCodeCtrl.clear();
                                setState(() {
                                  _voucher = null;
                                  _voucherError = null;
                                });
                                context.read<VoucherProvider>().clearValidation();
                              },
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: kDeepBlack,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: kBorderColor),
                                ),
                                child: const Icon(Icons.close, size: 16, color: kTextSecondary),
                              ),
                            ),
                            const SizedBox(width: 6),
                            OutlinedButton(
                              onPressed: _isValidatingVoucher ? null : _validateVoucher,
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                minimumSize: Size.zero,
                              ),
                              child: const Text('Cek', style: TextStyle(fontSize: 12)),
                            ),
                          ],
                        ],
                      ),
                      if (_voucher != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          '✓ ${_voucher!.name} — ${_voucher!.displayValue}',
                          style: const TextStyle(color: kSuccessColor, fontSize: 11),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal')),
        ElevatedButton.icon(
          onPressed: _isLoading ? null : _start,
          icon: const Icon(Icons.play_circle_outline_rounded, size: 18),
          label: _isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Text('Mulai Sesi'),
        ),
      ],
    );
  }

  Widget _buildSpinnerArrow({
    required IconData icon,
    required VoidCallback? onTap,
    bool enabled = true,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width: 60,
          height: 28,
          decoration: BoxDecoration(
            color: enabled ? kPrimaryBlue.withAlpha(30) : Colors.white.withAlpha(8),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: enabled ? kPrimaryBlue.withAlpha(60) : Colors.white.withAlpha(12),
            ),
          ),
          child: Icon(
            icon,
            size: 20,
            color: enabled ? kPrimaryBlue : kTextSecondary.withAlpha(60),
          ),
        ),
      ),
    );
  }

  Widget _buildCostSummary(NumberFormat fmt) {
    final preview = _pricePreview;
    final discount = _discountAmount;
    final finalPrice = _finalPrice;

    // Jika ada data tier dari backend, tampilkan breakdown
    if (preview != null && preview.breakdown.isNotEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: kDeepBlack,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: kBorderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.calculate_rounded, size: 14, color: kAccentPurple),
                const SizedBox(width: 6),
                const Text('Rincian Tarif Bertingkat',
                    style: TextStyle(fontSize: 11, color: kTextSecondary)),
                const Spacer(),
                if (_loadingPrice)
                  const SizedBox(width: 12, height: 12,
                      child: CircularProgressIndicator(strokeWidth: 2, color: kAccentPurple)),
              ],
            ),
            const SizedBox(height: 6),
            // Breakdown items
            ...preview.breakdown.map((b) => Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Row(
                    children: [
                      Icon(b.fallback ? Icons.warning_amber_rounded : Icons.check_rounded,
                          size: 12,
                          color: b.fallback ? kWarningColor : kSuccessColor),
                      const SizedBox(width: 6),
                      Text(
                          '${b.minutes} mnt × ${fmt.format(b.pricePerHour.toInt())}/jam',
                          style: const TextStyle(color: kTextSecondary, fontSize: 11)),
                      const Spacer(),
                      Text(fmt.format(b.subtotal.toInt()),
                          style: const TextStyle(color: kTextPrimary, fontSize: 11)),
                    ],
                  ),
                )),
            if (discount > 0) ...[
              const Divider(color: kBorderColor, height: 12),
              _SummaryRow('Diskon Voucher', '-${fmt.format(discount.toInt())}',
                  color: kSuccessColor),
            ],
            const Divider(color: kBorderColor, height: 12),
            _SummaryRow('Total', fmt.format(finalPrice.toInt()),
                isBold: true, color: kPrimaryBlue),
          ],
        ),
      );
    }

    // Fallback: tampilan flat rate
    final price = _pricePerHour;
    final subtotal = _subtotal;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kDeepBlack,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: kBorderColor),
      ),
      child: Column(
        children: [
          if (_loadingPrice) ...[
            const Row(children: [
              SizedBox(width: 12, height: 12,
                  child: CircularProgressIndicator(strokeWidth: 2, color: kAccentPurple)),
              SizedBox(width: 8),
              Text('Menghitung tarif...', style: TextStyle(fontSize: 11, color: kTextSecondary)),
            ]),
            const SizedBox(height: 8),
          ],
          _SummaryRow(
              '${fmt.format(price)}/jam × $_durationLabel', fmt.format(subtotal.toInt())),
          if (discount > 0) ...[
            const SizedBox(height: 4),
            _SummaryRow(
              'Diskon Voucher',
              '-${fmt.format(discount.toInt())}',
              color: kSuccessColor,
            ),
          ],
          const Divider(color: kBorderColor, height: 16),
          _SummaryRow('Total', fmt.format(finalPrice.toInt()),
              isBold: true, color: kPrimaryBlue),
          if (_voucherError != null) ...[
            const SizedBox(height: 6),
            Text(_voucherError!,
                style: const TextStyle(color: kErrorColor, fontSize: 11)),
          ],
        ],
      ),
    );
  }

  Widget _buildPreselectedConsole(NumberFormat fmt) {
    final c = widget.preselectedConsole!;
    final color = _typeColor(c.consoleType);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kDeepBlack,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              gradient: _typeGrad(c.consoleType),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(c.consoleType,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.name,
                    style: const TextStyle(
                        color: kTextPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14)),
                Text('${fmt.format(c.pricePerHour)}/jam',
                    style:
                        const TextStyle(color: kTextSecondary, fontSize: 12)),
              ],
            ),
          ),
          const Icon(Icons.check_circle, color: kSuccessColor, size: 20),
        ],
      ),
    );
  }

  Widget _buildConsoleDropdown() {
    if (_loadingConsoles) {
      return const Center(
          child: CircularProgressIndicator(color: kPrimaryBlue));
    }
    if (_availableConsoles.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: kWarningColor.withAlpha(20),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: kWarningColor.withAlpha(60)),
        ),
        child: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: kWarningColor, size: 18),
            SizedBox(width: 8),
            Expanded(
              child: Text('Tidak ada konsol tersedia saat ini',
                  style: TextStyle(color: kTextSecondary, fontSize: 13)),
            ),
          ],
        ),
      );
    }
    return DropdownButtonFormField<ConsoleModel>(
      value: _selectedConsole,
      decoration: const InputDecoration(
        labelText: 'Pilih Konsol',
        prefixIcon: Icon(Icons.sports_esports_outlined),
      ),
      dropdownColor: kCardColor,
      items: _availableConsoles.map((c) {
        return DropdownMenuItem(
          value: c,
          child: Text(
              '${c.name} (${c.consoleType}) — Rp ${c.pricePerHour.toInt()}/jam'),
        );
      }).toList(),
      onChanged: (v) {
        setState(() => _selectedConsole = v);
        _fetchPricePreview();
      },
      validator: (v) => v == null ? 'Pilih konsol' : null,
    );
  }

  void _adjustHours(bool up, void Function(VoidCallback) setSt) {
    final cur = int.tryParse(_hoursCtrl.text) ?? 0;
    final next = up ? cur + 1 : (cur > 0 ? cur - 1 : 0);
    _hoursCtrl.text = next.toString();
    setSt(() {});
    setState(() {});
    _fetchPricePreview();
  }

  void _adjustMinutes(bool up, void Function(VoidCallback) setSt) {
    final mins = int.tryParse(_minutesCtrl.text) ?? 0;
    final hrs = int.tryParse(_hoursCtrl.text) ?? 0;
    if (up) {
      // Tambah menit: jika >= 60, konversi ke jam
      if (mins + 1 >= 60) {
        _hoursCtrl.text = (hrs + 1).toString();
        _minutesCtrl.text = '0';
      } else {
        _minutesCtrl.text = (mins + 1).toString();
      }
    } else {
      // Kurang menit
      if (mins > 0) {
        _minutesCtrl.text = (mins - 1).toString();
      } else if (hrs > 0) {
        // Pinjam 1 jam → 59 menit
        _hoursCtrl.text = (hrs - 1).toString();
        _minutesCtrl.text = '59';
      }
      // else: jam=0 & menit=0 → tombol sudah disable, tidak ada aksi
    }
    setSt(() {});
    setState(() {});
    _fetchPricePreview();
  }

  /// Tampilkan dialog input manual untuk Jam atau Menit.
  /// Menit tidak boleh ≥ 60 — jika ≥ 60, otomatis dikonversi ke jam.
  Future<void> _showManualInput({
    required TextEditingController ctrl,
    required String label,
    required bool isMinutes,
    required void Function(VoidCallback) setSt,
  }) async {
    final inputCtrl = TextEditingController(text: ctrl.text);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Masukkan $label',
            style: const TextStyle(color: kTextPrimary, fontSize: 16)),
        content: TextField(
          controller: inputCtrl,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            labelText: label,
            hintText: '0',
            prefixIcon: Icon(isMinutes ? Icons.timer : Icons.schedule, size: 18),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, inputCtrl.text),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    if (result == null) return;
    final val = int.tryParse(result.trim()) ?? 0;
    if (val < 0) return;

    if (isMinutes) {
      if (val >= 60) {
        final currentHrs = int.tryParse(_hoursCtrl.text) ?? 0;
        _hoursCtrl.text = (currentHrs + val ~/ 60).toString();
        _minutesCtrl.text = (val % 60).toString();
      } else {
        _minutesCtrl.text = val.toString();
      }
    } else {
      _hoursCtrl.text = val.toString();
    }
    setSt(() {});
    setState(() {});
    _fetchPricePreview();
  }

  Widget _buildSpinnerColumn({
    required String label,
    required IconData icon,
    required TextEditingController ctrl,
    required void Function(bool up, void Function(VoidCallback) setSt) onAdjust,
    required void Function(VoidCallback) setSt,
    TextEditingController? borrowFromCtrl,
    bool isMinutes = false,
  }) {
    final val = int.tryParse(ctrl.text) ?? 0;
    final borrowVal = borrowFromCtrl != null ? (int.tryParse(borrowFromCtrl.text) ?? 0) : 0;
    final canDecrement = val > 0 || borrowVal > 0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(color: kTextSecondary, fontSize: 11)),
        const SizedBox(height: 4),
        // ▲ tombol tambah
        _buildSpinnerArrow(
          icon: Icons.keyboard_arrow_up,
          onTap: () => onAdjust(true, setSt),
        ),
        const SizedBox(height: 2),
        // Nilai saat ini — bisa di-tap untuk input manual
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showManualInput(
              ctrl: ctrl,
              label: label,
              isMinutes: isMinutes,
              setSt: setSt,
            ),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 60,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              decoration: BoxDecoration(
                color: kDeepBlack,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: kPrimaryBlue.withAlpha(isMinutes ? 50 : 30)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 14, color: kPrimaryBlue),
                  const SizedBox(width: 6),
                  Text(
                    ctrl.text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 2),
        // ▼ tombol kurang (disabled jika sudah 0)
        _buildSpinnerArrow(
          icon: Icons.keyboard_arrow_down,
          enabled: canDecrement,
          onTap: canDecrement ? () => onAdjust(false, setSt) : null,
        ),
      ],
    );
  }

  Widget _buildDurationInput(NumberFormat fmt) {
    return StatefulBuilder(
      builder: (ctx, setSt) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Jam
              _buildSpinnerColumn(
                label: 'Jam',
                icon: Icons.schedule,
                ctrl: _hoursCtrl,
                onAdjust: _adjustHours,
                setSt: setSt,
              ),
              const SizedBox(width: 24),
              // Pemisah ":"
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: Text(':', style: TextStyle(color: kTextSecondary, fontSize: 24, fontWeight: FontWeight.w300)),
              ),
              const SizedBox(width: 24),
              // Menit
              _buildSpinnerColumn(
                label: 'Menit',
                icon: Icons.timer,
                ctrl: _minutesCtrl,
                onAdjust: _adjustMinutes,
                setSt: setSt,
                borrowFromCtrl: _hoursCtrl,
                isMinutes: true,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: kDeepBlack, borderRadius: BorderRadius.circular(8), border: Border.all(color: kBorderColor)),
            child: Row(children: [
              const Icon(Icons.info_outline, size: 14, color: kTextSecondary),
              const SizedBox(width: 8),
              Text('$_durationLabel — ${fmt.format(_baseAmount.toInt())}',
                  style: const TextStyle(color: kPrimaryBlue, fontSize: 13, fontWeight: FontWeight.w600)),
              if (_loadingPrice) ...[
                const SizedBox(width: 8),
                const SizedBox(width: 12, height: 12,
                    child: CircularProgressIndicator(strokeWidth: 2, color: kAccentPurple)),
              ],
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedCustomer() {
    return Container(
      padding: const EdgeInsets.all(10),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: kSuccessColor.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: kSuccessColor.withAlpha(80)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: kSuccessColor, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_selectedCustomer!.name,
                    style: const TextStyle(
                        color: kTextPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
                Text(_selectedCustomer!.phone,
                    style:
                        const TextStyle(color: kTextSecondary, fontSize: 11)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: kTextSecondary, size: 18),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => setState(() {
              _selectedCustomer = null;
              _customerSearchCtrl.clear();
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerSearch() {
    return Consumer<CustomerProvider>(
      builder: (ctx, customerProvider, _) => Autocomplete<CustomerModel>(
        displayStringForOption: (c) => '${c.name} - ${c.phone}',
        optionsBuilder: (textEditingValue) {
          if (textEditingValue.text.isEmpty) return [];
          final q = textEditingValue.text.toLowerCase();
          return customerProvider.customers.where((c) =>
              c.name.toLowerCase().contains(q) || c.phone.contains(q));
        },
        onSelected: (c) => setState(() => _selectedCustomer = c),
        fieldViewBuilder: (ctx, ctrl, focus, onSubmit) => TextFormField(
          controller: ctrl,
          focusNode: focus,
          decoration: const InputDecoration(
            hintText: 'Cari nama atau nomor HP...',
            prefixIcon: Icon(Icons.search, size: 18),
            isDense: true,
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;
  final Color? color;

  const _SummaryRow(this.label, this.value,
      {this.isBold = false, this.color});

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      color: color ?? kTextPrimary,
      fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
      fontSize: isBold ? 14 : 13,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style.copyWith(color: color ?? kTextSecondary)),
        Text(value, style: style),
      ],
    );
  }
}

