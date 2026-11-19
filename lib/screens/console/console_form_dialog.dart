import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../config/permissions.dart';
import '../../models/console_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/console_provider.dart';
import '../../services/device_pairing_service.dart';

import '../../utils/app_dialog.dart';
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
  final _pairingCodeCtrl = TextEditingController();
  final _pairingService = DevicePairingService();
  String _status = 'available';
  bool _isLoading = false;

  // ── Pairing TV (khusus tambah konsol baru) ──
  bool _pairingLoading = false;
  bool _pairingResolved = false;
  String? _pairingError;

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
    _pairingCodeCtrl.dispose();
    super.dispose();
  }

  String get _cleanPairingCode =>
      _pairingCodeCtrl.text.replaceAll(RegExp(r'[^0-9]'), '');

  Future<void> _resolvePairing() async {
    final code = _cleanPairingCode;
    if (code.length != 6) {
      setState(() => _pairingError =
          'Kode harus 6 digit, sesuai yang tampil di layar TV');
      return;
    }

    setState(() {
      _pairingLoading = true;
      _pairingError = null;
    });

    try {
      final data = await _pairingService.resolveCode(code);
      final ip = (data['ipAddress'] as String?)?.trim() ?? '';
      if (ip.isEmpty) {
        throw Exception('TV belum mengirim alamat IP. Coba minta kode baru di TV.');
      }
      if (!mounted) return;
      setState(() {
        _pairingResolved = true;
        _ipCtrl.text = ip;
        _pairingError = null;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _pairingError =
            e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _pairingLoading = false);
    }
  }

  void _resetPairing() {
    setState(() {
      _pairingResolved = false;
      _pairingError = null;
      _pairingCodeCtrl.clear();
      _ipCtrl.clear();
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final provider = context.read<ConsoleProvider>();

    if (_isEdit) {
      final canEditPrice = canEditPermission(
        context.read<AuthProvider>().user,
        'console.price',
      );
      final fields = <String, dynamic>{
        'name': _nameCtrl.text.trim(),
        'consoleType': _typeCtrl.text.trim(),
        'status': _status,
        if (_descCtrl.text.trim().isNotEmpty) 'description': _descCtrl.text.trim(),
        if (_ipCtrl.text.trim().isNotEmpty) 'ipAddress': _ipCtrl.text.trim(),
      };
      // Harga hanya dikirim jika user punya izin. Tanpa ini backend menolak
      // update karena dianggap mencoba mengubah harga.
      if (canEditPrice) {
        fields['pricePerHour'] = double.parse(_priceCtrl.text);
        fields['pricingTiers'] = _buildPricingTiers() ?? [];
        if (_dailyPriceCtrl.text.isNotEmpty) {
          fields['dailyPrice'] = double.tryParse(_dailyPriceCtrl.text) ?? 0;
        }
      }
      final success = await provider.update(widget.console!.id, fields);
      setState(() => _isLoading = false);
      if (!mounted) return;
      if (success) {
        Navigator.pop(context);
        showSuccessDialog('Konsol diperbarui');
      } else {
        showErrorDialog(provider.error ?? 'Gagal menyimpan');
      }
      return;
    }

    // ── Tambah konsol baru ──
    // Bila TV sudah di-pairing, IP diambil dari perangkat TV. Konsol dibuat
    // dulu, lalu diikat memakai kode pairing yang sudah divalidasi.
    final dailyPrice = _dailyPriceCtrl.text.isNotEmpty
        ? double.tryParse(_dailyPriceCtrl.text)
        : null;
    final created = await provider.create(
      name: _nameCtrl.text.trim(),
      consoleType: _typeCtrl.text.trim(),
      pricePerHour: double.parse(_priceCtrl.text),
      description:
          _descCtrl.text.trim().isNotEmpty ? _descCtrl.text.trim() : null,
      ipAddress:
          _pairingResolved && _ipCtrl.text.trim().isNotEmpty
              ? _ipCtrl.text.trim()
              : null,
      pricingTiers: _buildPricingTiers(),
      dailyPrice: dailyPrice,
    );

    if (created == null) {
      setState(() => _isLoading = false);
      if (mounted) showErrorDialog(provider.error ?? 'Gagal menyimpan');
      return;
    }

    if (_pairingResolved) {
      try {
        await _pairingService.bindByCode(
          code: _cleanPairingCode,
          consoleId: created.id,
        );
        await provider.loadAll();
      } catch (e) {
        // Jangan tinggalkan konsol tanpa TV kalau binding gagal.
        await provider.delete(created.id);
        if (!mounted) return;
        setState(() => _isLoading = false);
        // Kode lama sudah tidak valid — minta kode baru dari TV.
        _resetPairing();
        showErrorDialog(
          'TV gagal dihubungkan: ${e.toString().replaceFirst('Exception: ', '')}. '
          'Konsol dibatalkan, silakan minta kode baru di TV lalu coba lagi.',
        );
        return;
      }
    }

    setState(() => _isLoading = false);
    if (!mounted) return;
    Navigator.pop(context);
    showSuccessDialog(_pairingResolved
        ? 'Konsol ditambahkan dan TV berhasil dihubungkan'
        : 'Konsol ditambahkan (TV belum dihubungkan)');
  }

  @override
  Widget build(BuildContext context) {
    final canEditPrice = canEditPermission(
      context.watch<AuthProvider>().user,
      'console.price',
    );
    final priceLocked = _isEdit && !canEditPrice;

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
                  readOnly: priceLocked,
                  decoration: InputDecoration(
                    labelText: 'Harga/Jam (Rp)',
                    prefixIcon: const Icon(Icons.attach_money),
                    suffixIcon: priceLocked
                        ? const Icon(Icons.lock_outline_rounded, size: 18)
                        : null,
                    helperText: priceLocked
                        ? 'Hanya admin / user dengan izin Harga Konsol'
                        : null,
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
                  readOnly: priceLocked,
                  decoration: InputDecoration(
                    labelText: 'Harga Sewa Harian (Rp)',
                    hintText: 'Kosongkan = tidak bisa rental harian',
                    prefixIcon: const Icon(Icons.hotel_outlined),
                    suffixIcon: priceLocked
                        ? const Icon(Icons.lock_outline_rounded, size: 18)
                        : null,
                  ),
                  keyboardType: TextInputType.number,
                ),
                // ── Pricing Tiers ──
                if (!priceLocked) ...[
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
                          const Flexible(
                            child: Text('Konfigurasi Tarif Bertingkat',
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: kTextPrimary),
                                overflow: TextOverflow.ellipsis),
                          ),
                          const SizedBox(width: 8),
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
                ],
                if (priceLocked) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: kCardColor.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: kBorderColor),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.lock_outline_rounded,
                            size: 16, color: kTextSecondary),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Harga per jam, harga harian, dan tarif bertingkat '
                            'hanya dapat diubah oleh admin/superadmin.',
                            style: TextStyle(
                                color: kTextSecondary, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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
                if (_isEdit)
                  // Mode edit: IP tetap bisa diubah manual.
                  TextFormField(
                    controller: _ipCtrl,
                    decoration: InputDecoration(
                      labelText: _typeCtrl.text.toLowerCase().contains('tv')
                          ? 'IP Address (wajib)'
                          : 'IP Address (opsional)',
                      prefixIcon: const Icon(Icons.router_outlined),
                      hintText: '192.168.1.x',
                      helperText:
                          'Untuk mengganti TV, gunakan tombol "Hubungkan TV" di menu Konsol.',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (_typeCtrl.text.toLowerCase().contains('tv') &&
                          (v == null || v.trim().isEmpty)) {
                        return 'IP Address wajib untuk TV';
                      }
                      return null;
                    },
                  )
                else if (!_pairingResolved)
                  // Mode tambah: input IP diganti pairing TV.
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: kAccentPurple.withAlpha(15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: kAccentPurple.withAlpha(60)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.cast_connected_rounded,
                                size: 18, color: kAccentPurple),
                            SizedBox(width: 8),
                            Text('Hubungkan TV',
                                style: TextStyle(
                                    color: kTextPrimary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Masukkan kode 6 digit yang tampil di layar TV. '
                          'IP Address akan terisi otomatis setelah berhasil.',
                          style: TextStyle(
                              color: kTextSecondary, fontSize: 11),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _pairingCodeCtrl,
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(6),
                          ],
                          style: const TextStyle(
                            color: kTextPrimary,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 10,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Kode Pairing',
                            hintText: '000000',
                            hintStyle: TextStyle(
                                letterSpacing: 6, fontSize: 20),
                            counterText: '',
                          ),
                          onChanged: (_) {
                            if (_pairingError != null) {
                              setState(() => _pairingError = null);
                            }
                          },
                          onSubmitted: (_) => _resolvePairing(),
                        ),
                        if (_pairingError != null) ...[
                          const SizedBox(height: 8),
                          Text(_pairingError!,
                              style: const TextStyle(
                                  color: kErrorColor, fontSize: 11)),
                        ],
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed:
                                _pairingLoading ? null : _resolvePairing,
                            icon: _pairingLoading
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white))
                                : const Icon(Icons.link_rounded, size: 16),
                            label: Text(_pairingLoading
                                ? 'Menghubungkan…'
                                : 'Hubungkan TV'),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: kAccentPurple),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  // Setelah pairing berhasil: tampilkan form IP.
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: kSuccessColor.withAlpha(15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: kSuccessColor.withAlpha(60)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.check_circle_rounded,
                                size: 18, color: kSuccessColor),
                            SizedBox(width: 8),
                            Text('TV berhasil terhubung',
                                style: TextStyle(
                                    color: kSuccessColor,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _ipCtrl,
                          readOnly: true,
                          decoration: const InputDecoration(
                            labelText: 'IP Address',
                            prefixIcon: Icon(Icons.router_outlined),
                            helperText: 'Otomatis dari perangkat TV',
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: _resetPairing,
                            icon: const Icon(Icons.link_off_rounded,
                                size: 16, color: kTextSecondary),
                            label: const Text('Ganti / lepas TV',
                                style: TextStyle(
                                    color: kTextSecondary, fontSize: 11)),
                          ),
                        ),
                      ],
                    ),
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
