import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/console_model.dart';
import '../../providers/console_provider.dart';

class ConsoleFormDialog extends StatefulWidget {
  final ConsoleModel? console;

  const ConsoleFormDialog({super.key, this.console});

  @override
  State<ConsoleFormDialog> createState() => _ConsoleFormDialogState();
}

class _ConsoleFormDialogState extends State<ConsoleFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _priceCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _ipCtrl;
  String _consoleType = 'PS4';
  String _status = 'available';
  bool _isLoading = false;

  bool get _isEdit => widget.console != null;

  @override
  void initState() {
    super.initState();
    final c = widget.console;
    _nameCtrl = TextEditingController(text: c?.name ?? '');
    _priceCtrl =
        TextEditingController(text: c?.pricePerHour.toStringAsFixed(0) ?? '');
    _descCtrl = TextEditingController(text: c?.description ?? '');
    _ipCtrl = TextEditingController(text: c?.ipAddress ?? '');
    _consoleType = c?.consoleType ?? 'PS4';
    _status = c?.status ?? 'available';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _descCtrl.dispose();
    _ipCtrl.dispose();
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
        'consoleType': _consoleType,
        'pricePerHour': double.parse(_priceCtrl.text),
        'status': _status,
        if (_descCtrl.text.trim().isNotEmpty) 'description': _descCtrl.text.trim(),
        if (_ipCtrl.text.trim().isNotEmpty) 'ipAddress': _ipCtrl.text.trim(),
      };
      success = await provider.update(widget.console!.id, fields);
    } else {
      success = await provider.create(
        name: _nameCtrl.text.trim(),
        consoleType: _consoleType,
        pricePerHour: double.parse(_priceCtrl.text),
        description: _descCtrl.text.trim().isNotEmpty ? _descCtrl.text.trim() : null,
        ipAddress: _ipCtrl.text.trim().isNotEmpty ? _ipCtrl.text.trim() : null,
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
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _consoleType,
                        decoration:
                            const InputDecoration(labelText: 'Tipe Konsol'),
                        dropdownColor: kCardColor,
                        items: const [
                          DropdownMenuItem(value: 'PS3', child: Text('PS3')),
                          DropdownMenuItem(value: 'PS4', child: Text('PS4')),
                          DropdownMenuItem(value: 'PS5', child: Text('PS5')),
                          DropdownMenuItem(
                              value: 'AndroidTV', child: Text('Android TV')),
                        ],
                        onChanged: (v) => setState(() => _consoleType = v!),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
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
                    ),
                  ],
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
                    labelText: _consoleType == 'AndroidTV'
                        ? 'IP Address (wajib)'
                        : 'IP Address (opsional)',
                    prefixIcon: const Icon(Icons.router_outlined),
                    hintText: '192.168.1.x',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (_consoleType == 'AndroidTV' &&
                        (v == null || v.trim().isEmpty)) {
                      return 'IP Address wajib untuk Android TV';
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
