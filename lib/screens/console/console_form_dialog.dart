import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/console_model.dart';
import '../../models/pricing_tier_model.dart';
import '../../providers/console_provider.dart';

class ConsoleFormDialog extends StatefulWidget {
  final ConsoleModel? console;

  const ConsoleFormDialog({super.key, this.console});

  @override
  State<ConsoleFormDialog> createState() => _ConsoleFormDialogState();
}

class _ConsoleFormDialogState extends State<ConsoleFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _dailyPriceCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _ipCtrl = TextEditingController();
  final _typeCtrl = TextEditingController();
  String _status = 'available';
  bool _isLoading = false;

  // ── Pricing tiers ──
  final List<_TierData> _tiers = [];

  bool get _isEdit => widget.console != null;

  @override
  void initState() {
    super.initState();
    final c = widget.console;
    _nameCtrl.text = c?.name ?? '';
    _priceCtrl.text = c?.pricePerHour.toStringAsFixed(0) ?? '';
    _dailyPriceCtrl.text = c?.dailyPrice != null && c!.dailyPrice > 0
        ? c.dailyPrice.toInt().toString()
        : '';
    _descCtrl.text = c?.description ?? '';
    _ipCtrl.text = c?.ipAddress ?? '';
    _typeCtrl.text = c?.consoleType ?? 'PS4';
    _status = c?.status ?? 'available';

    // Load existing tiers
    if (c != null && c.pricingTiers.isNotEmpty) {
      for (final t in c.pricingTiers) {
        _tiers.add(_TierData(
          startMinute: t.startMinute,
          endMinute: t.endMinute,
          price: t.price,
        ));
      }
    }
  }

  void _addTier() {
    // Default: lanjutan dari tier terakhir
    final lastEnd = _tiers.isNotEmpty ? _tiers.last.endMinute : 0;
    final start = lastEnd ?? (_tiers.isNotEmpty ? _tiers.last.startMinute + 60 : 0);
    setState(() {
      _tiers.add(_TierData(
        startMinute: start,
        endMinute: start + 60,
        price: double.tryParse(_priceCtrl.text) ?? 8000,
      ));
    });
  }

  void _removeTier(int index) {
    setState(() => _tiers.removeAt(index));
  }

  List<Map<String, dynamic>>? _buildPricingTiers() {
    if (_tiers.isEmpty) return null;
    return _tiers.map((t) => t.toJson()).toList();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _dailyPriceCtrl.dispose();
    _descCtrl.dispose();
    _ipCtrl.dispose();
    _typeCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final provider = context.read<ConsoleProvider>();
    bool success;

    if (_isEdit) {
      final fields = <String, dynamic>{
        'name': _nameCtrl.text.trim(),
        'consoleType': _typeCtrl.text.trim(),
        'pricePerHour': double.parse(_priceCtrl.text),
        'status': _status,
        if (_descCtrl.text.trim().isNotEmpty) 'description': _descCtrl.text.trim(),
        if (_ipCtrl.text.trim().isNotEmpty) 'ipAddress': _ipCtrl.text.trim(),
        'pricingTiers': _buildPricingTiers() ?? [],
        if (_dailyPriceCtrl.text.isNotEmpty)
          'dailyPrice': double.tryParse(_dailyPriceCtrl.text) ?? 0,
      };
      success = await provider.update(widget.console!.id, fields);
    } else {
      final dailyPrice = _dailyPriceCtrl.text.isNotEmpty
          ? double.tryParse(_dailyPriceCtrl.text)
          : null;
      success = await provider.create(
        name: _nameCtrl.text.trim(),
        consoleType: _typeCtrl.text.trim(),
        pricePerHour: double.parse(_priceCtrl.text),
        description: _descCtrl.text.trim().isNotEmpty ? _descCtrl.text.trim() : null,
        ipAddress: _ipCtrl.text.trim().isNotEmpty ? _ipCtrl.text.trim() : null,
        pricingTiers: _buildPricingTiers(),
        dailyPrice: dailyPrice,
      );
    }

    setState(() => _isLoading = false);
    if (mounted) {
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_isEdit ? 'Konsol diperbarui' : 'Konsol ditambahkan'),
          backgroundColor: kSuccessColor,
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(provider.error ?? 'Gagal menyimpan'),
          backgroundColor: kErrorColor,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEdit ? 'Edit Konsol' : 'Tambah Konsol'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nama Konsol',
                    prefixIcon: Icon(Icons.sports_esports_outlined),
                  ),
                  validator: (v) =>
                      v == null || v.trim().length < 2 ? 'Min. 2 karakter' : null,
                ),
                const SizedBox(height: 12),
                // Tipe Konsol — free text
                const Text('Tipe Konsol',
                    style: TextStyle(color: kTextSecondary, fontSize: 12)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: ['PS3', 'PS4', 'PS5', 'Switch', 'Xbox', 'PC', 'AndroidTV'].map((t) {
                    final selected = _typeCtrl.text == t;
                    return GestureDetector(
                      onTap: () {
                        _typeCtrl.text = t;
                        setState(() {});
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: selected ? kPrimaryBlue.withAlpha(25) : kCardColor,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: selected ? kPrimaryBlue.withAlpha(80) : kBorderColor),
                        ),
                        child: Text(t,
                            style: TextStyle(
                                color: selected ? kPrimaryBlue : kTextSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.w600)),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _typeCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Tipe Konsol',
                    prefixIcon: Icon(Icons.category_outlined),
                    hintText: 'PS4, PS5, Switch, Xbox, PC, SteamDeck...',
                  ),
                  validator: (v) {
                    if (v == null || v.trim().length < 2) return 'Min. 2 karakter';
                    return null;
                  },
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _priceCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Harga/Jam (Rp)',
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Wajib diisi';
                    if (double.tryParse(v) == null) return 'Angka tidak valid';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _dailyPriceCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Harga Sewa Harian (Rp)',
                    hintText: 'Kosongkan = tidak bisa rental harian',
                    prefixIcon: Icon(Icons.hotel_outlined),
                  ),
                  keyboardType: TextInputType.number,
                ),
                // ── Pricing Tiers ──
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: kCardColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: kBorderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.stacked_bar_chart_rounded,
                              size: 18, color: kAccentPurple),
                          const SizedBox(width: 8),
                          const Text('Konfigurasi Tarif Bertingkat',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: kTextPrimary)),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: _addTier,
                            icon: const Icon(Icons.add_rounded, size: 16),
                            label: const Text('Tambah', style: TextStyle(fontSize: 11)),
                            style: TextButton.styleFrom(
                                foregroundColor: kPrimaryBlue,
                                padding: const EdgeInsets.symmetric(horizontal: 8)),
                          ),
                        ],
                      ),
                      if (_tiers.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'Belum ada tier. Harga flat Rp/jam akan digunakan.\nTambah tier untuk tarif bertingkat (0-60mnt = 9000, dst).',
                            style: TextStyle(fontSize: 11, color: kTextSecondary),
                          ),
                        ),
                      ..._tiers.asMap().entries.map((entry) {
                        final i = entry.key;
                        final t = entry.value;
                        return _TierRow(
                          index: i,
                          data: t,
                          onChanged: () => setState(() {}),
                          onRemove: () => _removeTier(i),
                        );
                      }),
                    ],
                  ),
                ),
                if (_isEdit) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _status,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      prefixIcon: Icon(Icons.circle_outlined),
                    ),
                    dropdownColor: kCardColor,
                    items: const [
                      DropdownMenuItem(
                          value: 'available', child: Text('Tersedia')),
                      DropdownMenuItem(
                          value: 'in_use', child: Text('Dalam Sesi')),
                      DropdownMenuItem(
                          value: 'maintenance', child: Text('Maintenance')),
                    ],
                    onChanged: (v) => setState(() => _status = v!),
                  ),
                ],
                const SizedBox(height: 12),
                // IP Address — wajib untuk AndroidTV
                TextFormField(
                  controller: _ipCtrl,
                  decoration: InputDecoration(
                    labelText: _typeCtrl.text.toLowerCase().contains('tv')
                        ? 'IP Address (wajib)'
                        : 'IP Address (opsional)',
                    prefixIcon: const Icon(Icons.router_outlined),
                    hintText: '192.168.1.x',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (_typeCtrl.text.toLowerCase().contains('tv') &&
                        (v == null || v.trim().isEmpty)) {
                      return 'IP Address wajib untuk TV';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Deskripsi (opsional)',
                    prefixIcon: Icon(Icons.notes_outlined),
                  ),
                  maxLines: 2,
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
        ElevatedButton(
          onPressed: _isLoading ? null : _save,
          child: _isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : Text(_isEdit ? 'Simpan' : 'Tambah'),
        ),
      ],
    );
  }
}

// ── Helper: data tier sementara ──────────────────────────────────────────
class _TierData {
  int startMinute;
  int? endMinute;
  double price;

  _TierData({
    required this.startMinute,
    this.endMinute,
    required this.price,
  });

  Map<String, dynamic> toJson() => {
        'startMinute': startMinute,
        if (endMinute != null) 'endMinute': endMinute,
        'price': price,
      };

  String get label {
    final startH = startMinute ~/ 60;
    final startM = startMinute % 60;
    if (endMinute == null) {
      return '≥ ${startH}j ${startM}m';
    }
    final endH = endMinute! ~/ 60;
    final endM = endMinute! % 60;
    return '${startH}j$startM - ${endH}j$endM';
  }
}

// ── Row untuk satu tier ──────────────────────────────────────────────────
class _TierRow extends StatelessWidget {
  final int index;
  final _TierData data;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  const _TierRow({
    required this.index,
    required this.data,
    required this.onChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          // Label tier
          Container(
            width: 65,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: kPrimaryBlue.withAlpha(15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(data.label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 9, color: kPrimaryBlue)),
          ),
          const SizedBox(width: 6),
          // Start (menit)
          Expanded(
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Mulai (mnt)',
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              ),
              keyboardType: TextInputType.number,
              controller: TextEditingController(text: data.startMinute.toString()),
              style: const TextStyle(fontSize: 12),
              onChanged: (v) {
                data.startMinute = int.tryParse(v) ?? data.startMinute;
                onChanged();
              },
            ),
          ),
          const SizedBox(width: 6),
          // End (menit)
          Expanded(
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Selesai (mnt)',
                hintText: 'kosong = ∞',
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              ),
              keyboardType: TextInputType.number,
              controller: TextEditingController(
                  text: data.endMinute?.toString() ?? ''),
              style: const TextStyle(fontSize: 12),
              onChanged: (v) {
                data.endMinute = int.tryParse(v);
                onChanged();
              },
            ),
          ),
          const SizedBox(width: 6),
          // Harga
          SizedBox(
            width: 65,
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Rp',
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              ),
              keyboardType: TextInputType.number,
              controller: TextEditingController(text: data.price.toInt().toString()),
              style: const TextStyle(fontSize: 12),
              onChanged: (v) {
                data.price = double.tryParse(v) ?? data.price;
                onChanged();
              },
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline_rounded,
                size: 18, color: kErrorColor),
            onPressed: onRemove,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}
