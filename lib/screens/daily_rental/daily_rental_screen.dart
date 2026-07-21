import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/daily_rental_model.dart';
import '../../models/console_model.dart';
import '../../providers/daily_rental_provider.dart';
import '../../providers/console_provider.dart';
import '../../providers/customer_provider.dart';
import '../../providers/voucher_provider.dart';
import '../../models/voucher_model.dart';

class DailyRentalScreen extends StatefulWidget {
  const DailyRentalScreen({super.key});
  @override
  State<DailyRentalScreen> createState() => _DailyRentalScreenState();
}

class _DailyRentalScreenState extends State<DailyRentalScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    context.read<DailyRentalProvider>().loadAll();
    context.read<ConsoleProvider>().loadAll();
    context.read<CustomerProvider>().loadAll();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0F),
        title: const Text('Rental Harian'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: kTextSecondary),
            onPressed: _load,
          ),
          IconButton(
            icon: const Icon(Icons.add_rounded, color: kPrimaryBlue),
            onPressed: () => _openForm(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Consumer<DailyRentalProvider>(
        builder: (_, p, __) {
          if (p.isLoading && p.rentals.isEmpty) {
            return const Center(
                child: CircularProgressIndicator(color: kPrimaryBlue));
          }
          if (p.rentals.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.home_rounded, size: 56, color: kTextSecondary),
                  SizedBox(height: 12),
                  Text('Belum ada rental harian',
                      style: TextStyle(color: kTextSecondary, fontSize: 14)),
                ],
              ),
            );
          }
          return RefreshIndicator(
            color: kPrimaryBlue,
            onRefresh: () async => _load(),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: p.rentals.length,
              itemBuilder: (_, i) =>
                  _RentalCard(rental: p.rentals[i], onReload: _load),
            ),
          );
        },
      ),
    );
  }

  void _openForm() {
    showDialog(
      context: context,
      builder: (_) => const _RentalFormDialog(),
    ).then((_) => _load());
  }
}

// ─── Rental Card ────────────────────────────────────────────────────────────
class _RentalCard extends StatelessWidget {
  final DailyRentalModel rental;
  final VoidCallback onReload;
  const _RentalCard({required this.rental, required this.onReload});

  Color get _statusColor {
    switch (rental.status) {
      case 'active':
        return rental.isLate ? kErrorColor : kSuccessColor;
      case 'returned':
        return kPrimaryBlue;
      case 'overdue':
        return kErrorColor;
      default:
        return kWarningColor;
    }
  }

  String get _statusLabel {
    if (rental.isActive && rental.isLate) return 'TERLAMBAT';
    return rental.statusLabel;
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final start = DateFormat('d MMM yyyy', 'id').format(DateTime.parse(rental.startDate));
    final end = DateFormat('d MMM yyyy', 'id').format(DateTime.parse(rental.endDate));

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: rental.isLate ? kErrorColor.withAlpha(120) : kBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _statusColor.withAlpha(25),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _statusColor.withAlpha(80)),
              ),
              child: Text(_statusLabel,
                  style: TextStyle(
                      color: _statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w600)),
            ),
            const Spacer(),
            Text('$start — $end',
                style: const TextStyle(color: kTextSecondary, fontSize: 11)),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            const Icon(Icons.sports_esports_rounded,
                size: 16, color: kTextSecondary),
            const SizedBox(width: 6),
            Text(rental.consoleName ?? rental.consoleId,
                style: const TextStyle(
                    color: kTextPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 6),
          Row(children: [
            const Icon(Icons.person_outline, size: 14, color: kTextSecondary),
            const SizedBox(width: 6),
            Text(rental.customerName ?? 'Umum',
                style: const TextStyle(color: kTextSecondary, fontSize: 12)),
            const Spacer(),
            Text('${rental.totalDays} hari',
                style: const TextStyle(color: kTextSecondary, fontSize: 12)),
          ]),
          const SizedBox(height: 6),
          Row(children: [
            Text('Total: ${fmt.format((rental.finalAmount > 0 ? rental.finalAmount : rental.totalAmount).toInt())}',
                style: const TextStyle(
                    color: kTextPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
            const SizedBox(width: 12),
          ]),
          if (rental.discountAmount > 0 || rental.freeDaysUsed > 0) ...[
            const SizedBox(height: 4),
            Wrap(spacing: 6, runSpacing: 4, children: [
              if (rental.discountAmount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: kSuccessColor.withAlpha(20),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: kSuccessColor.withAlpha(60)),
                  ),
                  child: Text('Diskon -${fmt.format(rental.discountAmount.toInt())}',
                      style: const TextStyle(color: kSuccessColor, fontSize: 10, fontWeight: FontWeight.w600)),
                ),
              if (rental.freeDaysUsed > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: kPrimaryBlue.withAlpha(20),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: kPrimaryBlue.withAlpha(60)),
                  ),
                  child: Text('${rental.freeDaysUsed} hari gratis',
                      style: const TextStyle(color: kPrimaryBlue, fontSize: 10, fontWeight: FontWeight.w600)),
                ),
            ]),
          ],
          if (rental.voucherCode != null && rental.voucherCode!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text('🎟️ ${rental.voucherCode}${rental.voucherName != null ? " — ${rental.voucherName}" : ""}',
                style: const TextStyle(color: kAccentPurple, fontSize: 10)),
          ],
          if (rental.notes != null && rental.notes!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(rental.notes!,
                style: const TextStyle(
                    color: kTextSecondary, fontSize: 11, fontStyle: FontStyle.italic)),
          ],
          if (rental.isActive) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _returnRental(context),
                icon: const Icon(Icons.keyboard_return, size: 16),
                label: const Text('Kembalikan'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: kSuccessColor),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _returnRental(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Kembalikan Rental?'),
        content: Text(
            'Konfirmasi pengembalian ${rental.consoleName ?? rental.consoleId}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Tidak')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Ya, Kembalikan')),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      final success =
          await context.read<DailyRentalProvider>().returnRental(rental.id);
      if (context.mounted && success) onReload();
    }
  }
}

// ─── Rental Form Dialog ─────────────────────────────────────────────────────
class _RentalFormDialog extends StatefulWidget {
  const _RentalFormDialog();
  @override
  State<_RentalFormDialog> createState() => _RentalFormDialogState();
}

class _RentalFormDialogState extends State<_RentalFormDialog> {
  final _formKey = GlobalKey<FormState>();
  String? _consoleId;
  String? _customerId;
  final _startCtrl = TextEditingController(
      text: DateFormat('yyyy-MM-dd').format(DateTime.now()));
  final _endCtrl = TextEditingController(
      text: DateFormat('yyyy-MM-dd')
          .format(DateTime.now().add(const Duration(days: 3))));
  final _dailyPriceCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _voucherCodeCtrl = TextEditingController();
  bool _loading = false;
  bool _validatingVoucher = false;
  VoucherModel? _voucher;
  String? _voucherError;

  @override
  void initState() {
    super.initState();
    // dailyPrice akan diisi dari konsol terpilih
  }

  @override
  void dispose() {
    _startCtrl.dispose();
    _endCtrl.dispose();
    _dailyPriceCtrl.dispose();
    _notesCtrl.dispose();
    _voucherCodeCtrl.dispose();
    super.dispose();
  }

  Future<void> _validateVoucher() async {
    final code = _voucherCodeCtrl.text.trim();
    if (code.isEmpty) {
      setState(() { _voucher = null; _voucherError = null; });
      return;
    }
    setState(() => _validatingVoucher = true);
    final voucher = await context.read<VoucherProvider>().validateVoucherByCode(code);
    if (!mounted) return;
    setState(() {
      _validatingVoucher = false;
      if (voucher != null && voucher.isAvailable) {
        _voucher = voucher;
        _voucherError = null;
      } else {
        _voucher = null;
        _voucherError = 'Voucher tidak valid atau sudah tidak aktif';
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_consoleId == null) return;
    setState(() => _loading = true);
    final ok = await context.read<DailyRentalProvider>().create(
          consoleId: _consoleId!,
          customerId: _customerId,
          startDate: _startCtrl.text.trim(),
          endDate: _endCtrl.text.trim(),
          dailyPrice: double.tryParse(_dailyPriceCtrl.text) ?? 0,
          notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
          voucherCode: _voucherCodeCtrl.text.trim().isEmpty
              ? null
              : _voucherCodeCtrl.text.trim(),
        );
    setState(() => _loading = false);
    if (mounted) {
      if (ok != null) {
        Navigator.pop(context);
      } else {
        final err = context.read<DailyRentalProvider>().error;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(err ?? 'Gagal membuat rental'),
          backgroundColor: kErrorColor,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final consoles = context.watch<ConsoleProvider>().consoles;
    final customers = context.watch<CustomerProvider>().customers;

    return AlertDialog(
      title: const Text('Buat Rental Harian'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: _consoleId,
                  decoration: const InputDecoration(labelText: 'Konsol'),
                  items: consoles
                      .map((c) {
                        final isAvailable = c.status == 'available';
                        return DropdownMenuItem(
                          value: c.id,
                          child: Text(
                            '${c.name} — Rp ${c.dailyPrice.toInt()}/hari${isAvailable ? "" : "  ⚠️ DIPAKAI"}',
                            style: TextStyle(color: isAvailable ? kTextPrimary : kWarningColor, fontSize: 13),
                          ),
                        );
                      })
                      .toList(),
                  onChanged: (v) {
                    setState(() => _consoleId = v);
                    final console = consoles.where((c) => c.id == v).firstOrNull;
                    if (console != null && console.dailyPrice > 0) {
                      _dailyPriceCtrl.text = console.dailyPrice.toInt().toString();
                    }
                    // Validasi: tampilkan warning jika konsol tidak available
                    if (console != null && console.status != 'available') {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('⚠️ Konsol ini sedang tidak tersedia (dalam sesi/maintenance)'),
                        backgroundColor: kWarningColor,
                        duration: Duration(seconds: 3),
                      ));
                    }
                  },
                  validator: (v) {
                    if (v == null) return 'Pilih konsol';
                    final c = consoles.where((c) => c.id == v).firstOrNull;
                    if (c != null && c.status != 'available') {
                      return 'Konsol tidak tersedia (${c.status})';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String?>(
                  value: _customerId,
                  decoration:
                      const InputDecoration(labelText: 'Pelanggan (opsional)'),
                  items: [
                    const DropdownMenuItem(
                        value: null, child: Text('Umum (walk-in)')),
                    ...customers.map((c) => DropdownMenuItem(
                          value: c.id,
                          child: Text('${c.name} (${c.phone})'),
                        )),
                  ],
                  onChanged: (v) => setState(() => _customerId = v),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _startCtrl,
                  decoration: const InputDecoration(labelText: 'Tgl Mulai (YYYY-MM-DD)'),
                  validator: (v) => v?.isEmpty == true ? 'Isi tanggal' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _endCtrl,
                  decoration: const InputDecoration(labelText: 'Tgl Selesai (YYYY-MM-DD)'),
                  validator: (v) => v?.isEmpty == true ? 'Isi tanggal' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _dailyPriceCtrl,
                  decoration: InputDecoration(
                    labelText: 'Harga per Hari (Rp) — opsional',
                    hintText: 'Kosongkan = auto dari settings',
                    prefixIcon: const Icon(Icons.monetization_on_outlined, size: 18),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _notesCtrl,
                  decoration: const InputDecoration(labelText: 'Catatan (opsional)'),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                // ── Voucher ──
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _voucherCodeCtrl,
                        decoration: InputDecoration(
                          labelText: 'Kode Voucher (opsional)',
                          prefixIcon: _validatingVoucher
                              ? const SizedBox(
                                  width: 18, height: 18,
                                  child: Padding(
                                    padding: EdgeInsets.all(12),
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ))
                              : const Icon(Icons.discount_outlined),
                          suffixIcon: _voucher != null
                              ? const Icon(Icons.check_circle, color: kSuccessColor, size: 18)
                              : _voucherError != null
                                  ? const Icon(Icons.error, color: kErrorColor, size: 18)
                                  : null,
                        ),
                        textCapitalization: TextCapitalization.characters,
                        onChanged: (_) {
                          setState(() { _voucher = null; _voucherError = null; });
                        },
                        onSubmitted: (_) => _validateVoucher(),
                      ),
                    ),
                    if (_voucherCodeCtrl.text.trim().isNotEmpty) ...[
                      const SizedBox(width: 6),
                      OutlinedButton(
                        onPressed: _validatingVoucher ? null : _validateVoucher,
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
                  const SizedBox(height: 4),
                  Text('✓ ${_voucher!.name} — ${_voucher!.displayValue}',
                      style: const TextStyle(color: kSuccessColor, fontSize: 11)),
                ],
                if (_voucherError != null) ...[
                  const SizedBox(height: 4),
                  Text(_voucherError!,
                      style: const TextStyle(color: kErrorColor, fontSize: 11)),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context), child: const Text('Batal')),
        ElevatedButton(
            onPressed: _loading ? null : _submit,
            child: _loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Text('Simpan')),
      ],
    );
  }
}
