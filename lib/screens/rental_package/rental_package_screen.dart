import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/menu_model.dart';
import '../../models/rental_package_model.dart';
import '../../providers/menu_provider.dart';
import '../../providers/rental_package_provider.dart';
import '../../utils/app_dialog.dart';

class RentalPackageScreen extends StatefulWidget {
  const RentalPackageScreen({super.key});

  @override
  State<RentalPackageScreen> createState() => _RentalPackageScreenState();
}

class _RentalPackageScreenState extends State<RentalPackageScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RentalPackageProvider>().load();
      context.read<MenuProvider>().loadMenus();
    });
  }

  Future<void> _openForm([RentalPackageModel? pkg]) async {
    await showDialog(
      context: context,
      builder: (_) => _PackageFormDialog(package: pkg),
    );
    if (mounted) context.read<RentalPackageProvider>().load();
  }

  Future<void> _confirmDelete(RentalPackageModel pkg) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: kSurface,
        title: const Text('Hapus Paket',
            style: TextStyle(color: kTextPrimary)),
        content: Text('Hapus paket "${pkg.name}"?',
            style: const TextStyle(color: kTextSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: kErrorColor),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      final success = await context.read<RentalPackageProvider>().delete(pkg.id);
      if (mounted) {
        success
            ? showSuccessDialog('Paket dihapus')
            : showErrorDialog('Gagal menghapus paket');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,###', 'id');
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0F),
        title: const Text('Paket Rental'),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: kGradientPurple,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.add_rounded, size: 16, color: Colors.white),
            ),
            onPressed: _openForm,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Consumer<RentalPackageProvider>(
        builder: (context, p, _) {
          if (p.isLoading && p.packages.isEmpty) {
            return const Center(child: CircularProgressIndicator(color: kPrimaryBlue));
          }
          if (p.packages.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.nights_stay_outlined, size: 48, color: kTextSecondary),
                  const SizedBox(height: 12),
                  const Text('Belum ada paket',
                      style: TextStyle(color: kTextPrimary)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _openForm,
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: const Text('Tambah Paket'),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            color: kPrimaryBlue,
            onRefresh: p.load,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: p.packages.length,
              itemBuilder: (ctx, i) {
                final pkg = p.packages[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: kCardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: kBorderColor),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: kGradientPurple,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.nights_stay_rounded,
                            size: 18, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Expanded(
                                child: Text(pkg.name,
                                    style: const TextStyle(
                                        color: kTextPrimary,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14)),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: (pkg.isActive ? kSuccessColor : kTextSecondary)
                                      .withAlpha(25),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(pkg.isActive ? 'Aktif' : 'Nonaktif',
                                    style: TextStyle(
                                        color: pkg.isActive ? kSuccessColor : kTextSecondary,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700)),
                              ),
                            ]),
                            const SizedBox(height: 3),
                            Text(
                              '${pkg.startTime} – ${pkg.endTime} • ${pkg.durationMinutes ~/ 60}j ${pkg.durationMinutes % 60}m',
                              style: const TextStyle(color: kPrimaryBlue, fontSize: 12),
                            ),
                            Text('Rp ${fmt.format(pkg.price.toInt())}',
                                style: const TextStyle(
                                    color: kSuccessColor,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700)),
                            if (pkg.items.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                pkg.items
                                    .map((it) => '${it.menuItemName} ×${it.quantity}')
                                    .join(' • '),
                                style: const TextStyle(color: kTextSecondary, fontSize: 10),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Edit',
                        icon: const Icon(Icons.edit_outlined,
                            size: 20, color: kTextSecondary),
                        onPressed: () => _openForm(pkg),
                      ),
                      IconButton(
                        tooltip: 'Hapus',
                        icon: const Icon(Icons.delete_outline,
                            size: 20, color: kErrorColor),
                        onPressed: () => _confirmDelete(pkg),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _PackageFormDialog extends StatefulWidget {
  final RentalPackageModel? package;
  const _PackageFormDialog({this.package});

  @override
  State<_PackageFormDialog> createState() => _PackageFormDialogState();
}

class _PackageFormDialogState extends State<_PackageFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _descCtrl;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  bool _isActive = true;
  bool _saving = false;

  // menuItemId -> quantity
  final Map<String, int> _items = {};

  bool get _isEdit => widget.package != null;

  @override
  void initState() {
    super.initState();
    final p = widget.package;
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _priceCtrl = TextEditingController(
        text: p != null ? p.price.toInt().toString() : '');
    _descCtrl = TextEditingController(text: p?.description ?? '');
    _isActive = p?.isActive ?? true;
    if (p != null) {
      if (p.startTime.isNotEmpty) {
        _startTime = _parseTime(p.startTime);
      }
      if (p.endTime.isNotEmpty) {
        _endTime = _parseTime(p.endTime);
      }
      for (final it in p.items) {
        _items[it.menuItemId] = it.quantity;
      }
    }
  }

  TimeOfDay _parseTime(String s) {
    final parts = s.split(':');
    if (parts.length >= 2) {
      return TimeOfDay(
          hour: int.tryParse(parts[0]) ?? 0, minute: int.tryParse(parts[1]) ?? 0);
    }
    return const TimeOfDay(hour: 21, minute: 0);
  }

  String _fmtTime(TimeOfDay? t) => t == null
      ? 'Pilih jam'
      : '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _pickStart() async {
    final t = await showTimePicker(context: context, initialTime: _startTime ?? const TimeOfDay(hour: 21, minute: 0));
    if (t != null) setState(() => _startTime = t);
  }

  Future<void> _pickEnd() async {
    final t = await showTimePicker(context: context, initialTime: _endTime ?? const TimeOfDay(hour: 6, minute: 0));
    if (t != null) setState(() => _endTime = t);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startTime == null || _endTime == null) {
      showErrorDialog('Jam mulai dan selesai wajib diisi');
      return;
    }
    setState(() => _saving = true);
    final data = {
      if (_isEdit) 'id': widget.package!.id,
      'name': _nameCtrl.text.trim(),
      'startTime': _fmtTime(_startTime),
      'endTime': _fmtTime(_endTime),
      'price': double.tryParse(_priceCtrl.text.replaceAll(',', '')) ?? 0,
      if (_descCtrl.text.trim().isNotEmpty) 'description': _descCtrl.text.trim(),
      'isActive': _isActive,
      'items': _items.entries
          .map((e) => {'menuItemId': e.key, 'quantity': e.value})
          .toList(),
    };
    final success = await context.read<RentalPackageProvider>().save(data);
    if (mounted) {
      setState(() => _saving = false);
      if (success) {
        Navigator.pop(context);
      } else {
        showErrorDialog(context.read<RentalPackageProvider>().error ?? 'Gagal menyimpan');
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final menus = context.watch<MenuProvider>().menus;
    return AlertDialog(
      backgroundColor: kSurface,
      title: Text(_isEdit ? 'Edit Paket' : 'Tambah Paket',
          style: const TextStyle(color: kTextPrimary)),
      content: SizedBox(
        width: 460,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nama Paket'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Nama wajib diisi' : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: _pickStart,
                        child: InputDecorator(
                          decoration: const InputDecoration(labelText: 'Jam Mulai'),
                          child: Text(_fmtTime(_startTime)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: InkWell(
                        onTap: _pickEnd,
                        child: InputDecorator(
                          decoration: const InputDecoration(labelText: 'Jam Selesai'),
                          child: Text(_fmtTime(_endTime)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _priceCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'Harga Paket', prefixText: 'Rp '),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Harga wajib diisi' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descCtrl,
                  decoration: const InputDecoration(labelText: 'Deskripsi (opsional)'),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Aktif', style: TextStyle(color: kTextPrimary)),
                  value: _isActive,
                  onChanged: (v) => setState(() => _isActive = v),
                ),
                const SizedBox(height: 12),
                const Text('Item Bundling (opsional):',
                    style: TextStyle(color: kTextSecondary, fontSize: 12)),
                const SizedBox(height: 6),
                if (menus.isEmpty)
                  const Text('Belum ada menu — tambahkan menu dulu',
                      style: TextStyle(color: kTextSecondary, fontSize: 11))
                else
                  ...menus.map((m) => _bundlingRow(m)),
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
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 18, height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Simpan'),
        ),
      ],
    );
  }

  Widget _bundlingRow(MenuModel m) {
    final qty = _items[m.id] ?? 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: kBorderColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(m.name,
                style: const TextStyle(color: kTextPrimary, fontSize: 12)),
          ),
          if (qty > 0)
            IconButton(
              icon: const Icon(Icons.remove_circle_outline,
                  size: 18, color: kErrorColor),
              onPressed: () => setState(() {
                final n = qty - 1;
                if (n <= 0) {
                  _items.remove(m.id);
                } else {
                  _items[m.id] = n;
                }
              }),
            ),
          Text(qty > 0 ? '$qty' : '—',
              style: const TextStyle(
                  color: kTextPrimary, fontWeight: FontWeight.w700)),
          IconButton(
            icon: const Icon(Icons.add_circle_outline,
                size: 18, color: kSuccessColor),
            onPressed: () =>
                setState(() => _items[m.id] = (qty + 1)),
          ),
        ],
      ),
    );
  }
}
