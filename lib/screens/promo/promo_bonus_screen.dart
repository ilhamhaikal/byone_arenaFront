import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_theme.dart';
import '../../models/promo_bonus_model.dart';
import '../../providers/promo_provider.dart';

import '../../utils/app_dialog.dart';
/// Pengaturan bonus waktu gratis (mis. akhir pekan: min 60 menit, bonus 30).
class PromoBonusScreen extends StatefulWidget {
  const PromoBonusScreen({super.key});

  @override
  State<PromoBonusScreen> createState() => _PromoBonusScreenState();
}

class _PromoBonusScreenState extends State<PromoBonusScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PromoProvider>().loadRules();
    });
  }

  Future<void> _openForm([PromoBonusRuleModel? rule]) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _PromoFormDialog(rule: rule),
    );
    if (saved == true && mounted) {
      showSuccessDialog('Aturan promo disimpan');
    }
  }

  Future<void> _delete(PromoBonusRuleModel rule) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kSurface,
        title: const Text('Hapus Aturan Promo'),
        content: Text('Hapus "${rule.name}"? Sesi yang sudah memakai bonus tidak terpengaruh.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: kErrorColor),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final err = await context.read<PromoProvider>().deleteRule(rule.id);
    if (!mounted) return;
    if (err == null) {
      showSuccessDialog('Aturan promo dihapus');
    } else {
      showErrorDialog(err);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0F),
        title: const Text('Bonus Waktu'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: kTextSecondary),
            onPressed: () => context.read<PromoProvider>().loadRules(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        backgroundColor: kPrimaryBlue,
        icon: const Icon(Icons.add),
        label: const Text('Tambah Aturan'),
      ),
      body: Consumer<PromoProvider>(
        builder: (context, p, _) {
          if (p.isLoading && p.rules.isEmpty) {
            return const Center(child: CircularProgressIndicator(color: kPrimaryBlue));
          }
          if (p.error != null && p.rules.isEmpty) {
            return Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.error_outline, color: kErrorColor, size: 48),
                const SizedBox(height: 12),
                Text(p.error!, style: const TextStyle(color: kTextSecondary)),
                const SizedBox(height: 16),
                ElevatedButton(
                    onPressed: p.loadRules, child: const Text('Coba Lagi')),
              ]),
            );
          }
          if (p.rules.isEmpty) {
            return const Center(
              child: Text('Belum ada aturan bonus waktu',
                  style: TextStyle(color: kTextSecondary)),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
            itemCount: p.rules.length,
            itemBuilder: (_, i) {
              final r = p.rules[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: kCardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: r.isActive
                          ? kSuccessColor.withAlpha(70)
                          : kBorderColor),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: (r.isActive ? kSuccessColor : kTextSecondary)
                            .withAlpha(22),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.card_giftcard_rounded,
                          color: r.isActive ? kSuccessColor : kTextSecondary,
                          size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r.name,
                              style: const TextStyle(
                                  color: kTextPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          Text(
                            '${r.daysLabel} • min ${r.minPaidMinutes} menit → bonus ${r.bonusMinutes} menit',
                            style: const TextStyle(
                                color: kTextSecondary, fontSize: 11),
                          ),
                          Text(
                            r.maxPerSession == 0
                                ? 'Boleh dipakai berulang dalam satu sesi'
                                : 'Maksimal ${r.maxPerSession}× per sesi',
                            style: TextStyle(
                                color: r.maxPerSession == 0
                                    ? kSuccessColor
                                    : kTextSecondary,
                                fontSize: 10),
                          ),
                          if (!r.isActive)
                            const Padding(
                              padding: EdgeInsets.only(top: 4),
                              child: Text('Nonaktif',
                                  style: TextStyle(
                                      color: kTextSecondary,
                                      fontSize: 11,
                                      fontStyle: FontStyle.italic)),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Edit',
                      icon: const Icon(Icons.edit_outlined,
                          size: 20, color: kTextSecondary),
                      onPressed: () => _openForm(r),
                    ),
                    IconButton(
                      tooltip: 'Hapus',
                      icon: const Icon(Icons.delete_outline,
                          size: 20, color: kErrorColor),
                      onPressed: () => _delete(r),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _PromoFormDialog extends StatefulWidget {
  final PromoBonusRuleModel? rule;
  const _PromoFormDialog({this.rule});

  @override
  State<_PromoFormDialog> createState() => _PromoFormDialogState();
}

class _PromoFormDialogState extends State<_PromoFormDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _minCtrl;
  late final TextEditingController _bonusCtrl;
  late final TextEditingController _maxCtrl;
  late Set<int> _days;
  late bool _active;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final r = widget.rule;
    _nameCtrl = TextEditingController(text: r?.name ?? 'Bonus Weekend');
    _minCtrl = TextEditingController(text: (r?.minPaidMinutes ?? 60).toString());
    _bonusCtrl = TextEditingController(text: (r?.bonusMinutes ?? 30).toString());
    _maxCtrl = TextEditingController(text: (r?.maxPerSession ?? 0).toString());
    _days = (r?.daysOfWeek ?? '6,7')
        .split(',')
        .map((e) => int.tryParse(e.trim()))
        .whereType<int>()
        .toSet();
    _active = r?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _minCtrl.dispose();
    _bonusCtrl.dispose();
    _maxCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final min = int.tryParse(_minCtrl.text.trim()) ?? 0;
    final bonus = int.tryParse(_bonusCtrl.text.trim()) ?? 0;
    final maxPer = int.tryParse(_maxCtrl.text.trim()) ?? 0;
    if (_nameCtrl.text.trim().length < 2) {
      setState(() => _error = 'Nama minimal 2 karakter');
      return;
    }
    if (min < 1 || bonus < 1) {
      setState(() => _error = 'Minimal menit dan bonus harus lebih dari 0');
      return;
    }
    if (_days.isEmpty) {
      setState(() => _error = 'Pilih minimal satu hari');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final rule = PromoBonusRuleModel(
      id: widget.rule?.id ?? '',
      name: _nameCtrl.text.trim(),
      daysOfWeek: (_days.toList()..sort()).join(','),
      minPaidMinutes: min,
      bonusMinutes: bonus,
      maxPerSession: maxPer < 0 ? 0 : maxPer,
      validFrom: widget.rule?.validFrom,
      validTo: widget.rule?.validTo,
      isActive: _active,
    );

    final err = await context.read<PromoProvider>().saveRule(rule);
    if (!mounted) return;
    if (err != null) {
      setState(() {
        _saving = false;
        _error = err;
      });
      return;
    }
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    const dayNames = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];

    return AlertDialog(
      backgroundColor: kSurface,
      title: Text(widget.rule == null ? 'Tambah Aturan Bonus' : 'Edit Aturan Bonus'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Nama aturan'),
            ),
            const SizedBox(height: 12),
            const Text('Hari berlaku',
                style: TextStyle(color: kTextSecondary, fontSize: 12)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              children: List.generate(7, (d) {
                final selected = _days.contains(d);
                return FilterChip(
                  label: Text(dayNames[d],
                      style: TextStyle(
                          fontSize: 11,
                          color: selected ? Colors.white : kTextSecondary)),
                  selected: selected,
                  selectedColor: kPrimaryBlue,
                  backgroundColor: kCardColor,
                  onSelected: (v) => setState(() {
                    if (v) {
                      _days.add(d);
                    } else {
                      _days.remove(d);
                    }
                  }),
                );
              }),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _minCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'Min. menit bayar'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _bonusCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'Bonus menit'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _maxCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Maks. pemakaian per sesi',
                helperText: 'Isi 0 untuk bebas dipakai berulang',
              ),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Aktif', style: TextStyle(fontSize: 13)),
              value: _active,
              activeColor: kSuccessColor,
              onChanged: (v) => setState(() => _active = v),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(_error!,
                    style: const TextStyle(color: kErrorColor, fontSize: 12)),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: _saving ? null : () => Navigator.pop(context),
            child: const Text('Batal')),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Simpan'),
        ),
      ],
    );
  }
}