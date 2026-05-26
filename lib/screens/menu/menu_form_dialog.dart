import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/menu_model.dart';
import '../../providers/menu_provider.dart';

class MenuFormDialog extends StatefulWidget {
  final MenuModel? menu;
  const MenuFormDialog({super.key, this.menu});

  @override
  State<MenuFormDialog> createState() => _MenuFormDialogState();
}

class _MenuFormDialogState extends State<MenuFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _priceCtrl;
  String _category = 'food';
  bool _isAvailable = true;
  bool _isLoading = false;

  bool get _isEdit => widget.menu != null;

  @override
  void initState() {
    super.initState();
    final m = widget.menu;
    _nameCtrl = TextEditingController(text: m?.name ?? '');
    _descCtrl = TextEditingController(text: m?.description ?? '');
    _priceCtrl =
        TextEditingController(text: m?.price.toStringAsFixed(0) ?? '');
    _category = m?.category ?? 'food';
    _isAvailable = m?.isAvailable ?? true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final data = <String, dynamic>{
      'name': _nameCtrl.text.trim(),
      'category': _category,
      'price': double.tryParse(_priceCtrl.text) ?? 0.0,
      'isAvailable': _isAvailable,
      if (_descCtrl.text.trim().isNotEmpty)
        'description': _descCtrl.text.trim(),
    };

    final provider = context.read<MenuProvider>();
    bool success;
    if (_isEdit) {
      success = await provider.updateMenu(widget.menu!.id, data);
    } else {
      success = await provider.createMenu(data);
    }

    setState(() => _isLoading = false);
    if (mounted) {
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text(_isEdit ? 'Menu diperbarui' : 'Menu ditambahkan'),
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
    const categoryLabels = {
      'food': 'Makanan',
      'drink': 'Minuman',
      'snack': 'Snack',
      'other': 'Lainnya',
    };

    return AlertDialog(
      backgroundColor: kSurface,
      title: Text(_isEdit ? 'Edit Menu' : 'Tambah Menu',
          style: const TextStyle(color: kTextPrimary)),
      content: SizedBox(
        width: 380,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Nama Menu'),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Deskripsi (opsional)'),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _category,
                        decoration:
                            const InputDecoration(labelText: 'Kategori'),
                        dropdownColor: kCardColor,
                        items: MenuModel.categories
                            .map((cat) => DropdownMenuItem(
                                value: cat,
                                child: Text(
                                    categoryLabels[cat] ?? cat)))
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _category = v!),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _priceCtrl,
                        decoration: const InputDecoration(
                            labelText: 'Harga (Rp)'),
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Wajib diisi';
                          }
                          if (double.tryParse(v) == null) {
                            return 'Angka tidak valid';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                SwitchListTile(
                  title: const Text('Tersedia',
                      style: TextStyle(color: kTextPrimary)),
                  value: _isAvailable,
                  onChanged: (v) => setState(() => _isAvailable = v),
                  activeTrackColor: kSuccessColor,
                  contentPadding: EdgeInsets.zero,
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
