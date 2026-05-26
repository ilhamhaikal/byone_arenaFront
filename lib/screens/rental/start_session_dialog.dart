import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/customer_model.dart';
import '../../models/console_model.dart';
import '../../providers/console_provider.dart';
import '../../providers/customer_provider.dart';
import '../../providers/session_provider.dart';

class StartSessionDialog extends StatefulWidget {
  const StartSessionDialog({super.key});

  @override
  State<StartSessionDialog> createState() => _StartSessionDialogState();
}

class _StartSessionDialogState extends State<StartSessionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _customerSearchCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  ConsoleModel? _selectedConsole;
  CustomerModel? _selectedCustomer;
  bool _isLoading = false;
  bool _loadingConsoles = false;
  List<ConsoleModel> _availableConsoles = [];

  @override
  void initState() {
    super.initState();
    _loadAvailableConsoles();
  }

  @override
  void dispose() {
    _customerSearchCtrl.dispose();
    _notesCtrl.dispose();
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
    if (_selectedConsole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih konsol terlebih dahulu'), backgroundColor: kErrorColor),
      );
      return;
    }
    setState(() => _isLoading = true);

    final session = await context.read<SessionProvider>().start(
          consoleId: _selectedConsole!.id,
          customerId: _selectedCustomer?.id,
          notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        );

    setState(() => _isLoading = false);
    if (mounted) {
      if (session != null) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Sesi berhasil dimulai!'),
          backgroundColor: kSuccessColor,
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(context.read<SessionProvider>().error ?? 'Gagal memulai sesi'),
          backgroundColor: kErrorColor,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Mulai Sesi Baru'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Pilih konsol ──
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Pilih Konsol', style: TextStyle(color: kTextSecondary, fontSize: 12)),
                ),
                const SizedBox(height: 8),
                _loadingConsoles
                    ? const Center(child: CircularProgressIndicator(color: kPrimaryBlue))
                    : _availableConsoles.isEmpty
                        ? Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: kErrorColor.withAlpha(20),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: kErrorColor.withAlpha(60)),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.warning_amber_rounded, color: kWarningColor, size: 18),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Tidak ada konsol tersedia saat ini',
                                    style: TextStyle(color: kTextSecondary, fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : DropdownButtonFormField<ConsoleModel>(
                            value: _selectedConsole,
                            decoration: const InputDecoration(
                              labelText: 'Konsol',
                              prefixIcon: Icon(Icons.sports_esports),
                            ),
                            dropdownColor: kCardColor,
                            items: _availableConsoles.map((c) {
                              return DropdownMenuItem(
                                value: c,
                                child: Text('${c.name} (${c.consoleType}) - Rp ${c.pricePerHour.toInt()}/jam'),
                              );
                            }).toList(),
                            onChanged: (v) => setState(() => _selectedConsole = v),
                            validator: (v) => v == null ? 'Pilih konsol' : null,
                          ),
                const SizedBox(height: 16),
                const Divider(),
                // ── Pelanggan opsional ──
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Pelanggan (Opsional)', style: TextStyle(color: kTextSecondary, fontSize: 12)),
                ),
                const SizedBox(height: 8),
                if (_selectedCustomer != null)
                  Container(
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
                                  style: const TextStyle(color: kTextPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
                              Text(_selectedCustomer!.phone,
                                  style: const TextStyle(color: kTextSecondary, fontSize: 11)),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: kTextSecondary, size: 18),
                          onPressed: () => setState(() {
                            _selectedCustomer = null;
                            _customerSearchCtrl.clear();
                          }),
                        ),
                      ],
                    ),
                  ),
                Consumer<CustomerProvider>(
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
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _notesCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Catatan (opsional)',
                    prefixIcon: Icon(Icons.notes),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
        ElevatedButton.icon(
          onPressed: _isLoading ? null : _start,
          icon: const Icon(Icons.play_circle_outline),
          label: _isLoading
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Mulai'),
        ),
      ],
    );
  }
}
