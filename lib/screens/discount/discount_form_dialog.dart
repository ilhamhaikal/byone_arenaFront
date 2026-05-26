import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/discount_model.dart';
import '../../providers/discount_provider.dart';

class DiscountFormDialog extends StatefulWidget {
  final DiscountModel? discount;

  const DiscountFormDialog({super.key, this.discount});

  @override
  State<DiscountFormDialog> createState() => _DiscountFormDialogState();
}

class _DiscountFormDialogState extends State<DiscountFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _valueCtrl;
  late TextEditingController _minTxCtrl;
  String _discountType = 'percentage';
  String? _membershipType;
  late DateTime _startDate;
  late DateTime _endDate;
  bool _isActive = true;
  bool _isLoading = false;

  bool get _isEdit => widget.discount != null;

  @override
  void initState() {
    super.initState();
    final d = widget.discount;
    _nameCtrl = TextEditingController(text: d?.name ?? '');
    _descCtrl = TextEditingController(text: d?.description ?? '');
    _valueCtrl =
        TextEditingController(text: d?.discountValue.toStringAsFixed(0) ?? '');
    _minTxCtrl = TextEditingController(
        text: d?.minTransaction?.toStringAsFixed(0) ?? '');
    _discountType = d?.discountType ?? 'percentage';
    _membershipType = d?.membershipType;
    _startDate = d?.startDate ?? DateTime.now();
    _endDate = d?.endDate ??
        DateTime.now().add(const Duration(days: 30));
    _isActive = d?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _valueCtrl.dispose();
    _minTxCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final discount = DiscountModel(
      id: widget.discount?.id ?? 0,
      name: _nameCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      discountType: _discountType,
      discountValue: double.parse(_valueCtrl.text),
      minTransaction: _minTxCtrl.text.isNotEmpty
          ? double.tryParse(_minTxCtrl.text)
          : null,
      membershipType:
          _membershipType?.isEmpty == true ? null : _membershipType,
      startDate: _startDate,
      endDate: _endDate,
      isActive: _isActive,
    );

    final provider = context.read<DiscountProvider>();
    bool success;
    if (_isEdit) {
      success =
          await provider.updateDiscount(widget.discount!.id, discount);
    } else {
      success = await provider.createDiscount(discount);
    }

    setState(() => _isLoading = false);
    if (mounted) {
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              _isEdit ? 'Diskon diperbarui' : 'Diskon ditambahkan'),
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
    String dateFmt(DateTime d) =>
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

    return AlertDialog(
      title: Text(_isEdit ? 'Edit Diskon' : 'Tambah Diskon'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Nama Diskon'),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Deskripsi'),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _discountType,
                        decoration:
                            const InputDecoration(labelText: 'Tipe'),
                        dropdownColor: kCardColor,
                        items: const [
                          DropdownMenuItem(
                              value: 'percentage',
                              child: Text('Persentase (%)')),
                          DropdownMenuItem(
                              value: 'fixed',
                              child: Text('Nominal (Rp)')),
                        ],
                        onChanged: (v) =>
                            setState(() => _discountType = v!),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _valueCtrl,
                        decoration: InputDecoration(
                          labelText: _discountType == 'percentage'
                              ? 'Nilai (%)'
                              : 'Nilai (Rp)',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (v) => v == null || v.isEmpty
                            ? 'Wajib diisi'
                            : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _minTxCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Min. Transaksi (Rp, opsional)'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String?>(
                  value: _membershipType,
                  decoration: const InputDecoration(
                      labelText: 'Khusus Membership'),
                  dropdownColor: kCardColor,
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Semua')),
                    DropdownMenuItem(
                        value: 'regular', child: Text('Regular')),
                    DropdownMenuItem(
                        value: 'silver', child: Text('Silver')),
                    DropdownMenuItem(
                        value: 'gold', child: Text('Gold')),
                    DropdownMenuItem(
                        value: 'platinum', child: Text('Platinum')),
                  ],
                  onChanged: (v) => setState(() => _membershipType = v),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _pickDate(true),
                        child: InputDecorator(
                          decoration:
                              const InputDecoration(labelText: 'Mulai'),
                          child: Text(dateFmt(_startDate),
                              style:
                                  const TextStyle(color: kTextPrimary)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () => _pickDate(false),
                        child: InputDecorator(
                          decoration:
                              const InputDecoration(labelText: 'Berakhir'),
                          child: Text(dateFmt(_endDate),
                              style:
                                  const TextStyle(color: kTextPrimary)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                SwitchListTile(
                  title: const Text('Aktif',
                      style: TextStyle(color: kTextPrimary)),
                  value: _isActive,
                  onChanged: (v) => setState(() => _isActive = v),
                  activeThumbColor: kSuccessColor,
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
