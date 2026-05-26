import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/console_model.dart';
import '../../models/console_overview_model.dart';
import '../../models/customer_model.dart';
import '../../providers/console_provider.dart';
import '../../providers/customer_provider.dart';
import '../../providers/session_provider.dart';

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

  ConsoleModel? _selectedConsole;
  CustomerModel? _selectedCustomer;
  int _bookedDuration = 60; // menit (min: 60, kelipatan 60)
  bool _isLoading = false;
  bool _loadingConsoles = false;
  List<ConsoleModel> _availableConsoles = [];

  bool get _hasPreselected => widget.preselectedConsole != null;

  double get _pricePerHour => _hasPreselected
      ? widget.preselectedConsole!.pricePerHour
      : (_selectedConsole?.pricePerHour ?? 0);
  double get _totalPrice => _pricePerHour * (_bookedDuration / 60);
  double get _cashReceivedAmt =>
      double.tryParse(_cashCtrl.text.replaceAll(',', '')) ?? 0;
  double get _change => (_cashReceivedAmt - _totalPrice).clamp(0, double.infinity);
  bool get _isEnough => _totalPrice > 0 && _cashReceivedAmt >= _totalPrice;

  @override
  void initState() {
    super.initState();
    if (!_hasPreselected) _loadAvailableConsoles();
  }

  @override
  void dispose() {
    _customerSearchCtrl.dispose();
    _notesCtrl.dispose();
    _cashCtrl.dispose();
    _voucherCodeCtrl.dispose();
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
            'Uang kurang! Total: Rp ${fmt.format(_totalPrice.toInt())}'),
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
          bookedDurationMinutes: _bookedDuration,
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
                _buildDurationChips(fmt),

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
                          if (_cashReceivedAmt < _totalPrice) {
                            return 'Uang kurang dari total';
                          }
                          return null;
                        },
                        onChanged: (_) => setSt(() {}),
                      ),
                      if (_cashReceivedAmt > 0 && _totalPrice > 0) ...[
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
                                'Rp ${fmt.format(_isEnough ? _change.toInt() : (_totalPrice - _cashReceivedAmt).toInt())}',
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
                      TextField(
                        controller: _voucherCodeCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Kode Voucher (opsional)',
                          prefixIcon: Icon(Icons.discount_outlined),
                          hintText: 'DISKON10',
                        ),
                        textCapitalization: TextCapitalization.characters,
                      ),
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

  Widget _buildCostSummary(NumberFormat fmt) {
    final hours = _bookedDuration ~/ 60;
    final price = _pricePerHour;
    final total = _totalPrice;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kDeepBlack,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: kBorderColor),
      ),
      child: Column(
        children: [
          _SummaryRow(
              '${fmt.format(price)}/jam × $hours jam', fmt.format(total.toInt())),
          if (total > 0) ...[
            const Divider(color: kBorderColor, height: 16),
            _SummaryRow('Total', fmt.format(total.toInt()),
                isBold: true, color: kPrimaryBlue),
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
      onChanged: (v) => setState(() => _selectedConsole = v),
      validator: (v) => v == null ? 'Pilih konsol' : null,
    );
  }

  Widget _buildDurationChips(NumberFormat fmt) {
    final pricePerHour = _hasPreselected
        ? widget.preselectedConsole!.pricePerHour
        : (_selectedConsole?.pricePerHour ?? 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [1, 2, 3, 4, 5, 6].map((h) {
            final minutes = h * 60;
            final isSelected = _bookedDuration == minutes;
            final cost = pricePerHour * h;
            return GestureDetector(
              onTap: () => setState(() => _bookedDuration = minutes),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  gradient: isSelected ? kGradientBlue : null,
                  color: isSelected ? null : kCardColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? kPrimaryBlue : kBorderColor,
                    width: isSelected ? 1.5 : 0.5,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                              color: kPrimaryBlue.withAlpha(60), blurRadius: 8)
                        ]
                      : null,
                ),
                child: Column(
                  children: [
                    Text(
                      '${h}h',
                      style: TextStyle(
                        color: isSelected ? Colors.white : kTextPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    if (cost > 0)
                      Text(
                        fmt.format(cost),
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white.withAlpha(200)
                              : kTextSecondary,
                          fontSize: 10,
                        ),
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 6),
        Text(
          'Durasi dipilih: ${_bookedDuration ~/ 60} jam',
          style: const TextStyle(color: kTextSecondary, fontSize: 12),
        ),
      ],
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

