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
  late TextEditingController _valueCtrl;
  late TextEditingController _minPurchaseCtrl;
  late TextEditingController _maxDiscountCtrl;
  late TextEditingController _daysOfWeekCtrl;
  late TextEditingController _priorityCtrl;

  String _ruleType = 'always';
  String _discountType = 'percentage';
  int _startHour = 0;
  int _endHour = 23;
  bool _isActive = true;
  bool _isLoading = false;

  bool get _isEdit => widget.discount != null;

  @override
  void initState() {
    super.initState();
    final d = widget.discount;
    _nameCtrl = TextEditingController(text: d?.name ?? '');
    _valueCtrl =
        TextEditingController(text: d?.discountValue.toStringAsFixed(0) ?? '');
    _minPurchaseCtrl =
        TextEditingController(text: d?.minPurchase.toStringAsFixed(0) ?? '0');
    _maxDiscountCtrl =
        TextEditingController(text: d?.maxDiscount.toStringAsFixed(0) ?? '0');
    _daysOfWeekCtrl = TextEditingController(text: d?.daysOfWeek ?? '');
    _priorityCtrl =
        TextEditingController(text: d?.priority.toString() ?? '0');
    _ruleType = d?.ruleType ?? 'always';
    _discountType = d?.discountType ?? 'percentage';
    _startHour = d?.startHour ?? 0;
    _endHour = d?.endHour ?? 23;
    _isActive = d?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _valueCtrl.dispose();
    _minPurchaseCtrl.dispose();
    _maxDiscountCtrl.dispose();
    _daysOfWeekCtrl.dispose();
    _priorityCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final data = <String, dynamic>{
      'name': _nameCtrl.text.trim(),
      'ruleType': _ruleType,
      'discountType': _discountType,
      'discountValue': double.tryParse(_valueCtrl.text) ?? 0.0,
      'startHour': _startHour,
      'endHour': _endHour,
      'minPurchase': double.tryParse(_minPurchaseCtrl.text) ?? 0.0,
      'maxDiscount': double.tryParse(_maxDiscountCtrl.text) ?? 0.0,
      'priority': int.tryParse(_priorityCtrl.text) ?? 0,
      'isActive': _isActive,
      if (_ruleType == 'day_of_week' &&
          _daysOfWeekCtrl.text.trim().isNotEmpty)
        'daysOfWeek': _daysOfWeekCtrl.text.trim(),
    };

    final provider = context.read<DiscountProvider>();
    bool success;
    if (_isEdit) {
      success = await provider.updateDiscount(widget.discount!.id, data);
    } else {
      success = await provider.createDiscount(data);
    }

    setState(() => _isLoading = false);
    if (mounted) {
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              _isEdit ? 'Aturan diskon diperbarui' : 'Aturan diskon ditambahkan'),
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
      backgroundColor: kSurface,
      title: Text(_isEdit ? 'Edit Aturan Diskon' : 'Tambah Aturan Diskon',
          style: const TextStyle(color: kTextPrimary)),
      content: SizedBox(
        width: 440,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Nama Aturan'),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _ruleType,
                  decoration:
                      const InputDecoration(labelText: 'Jenis Aturan'),
                  dropdownColor: kCardColor,
                  items: const [
                    DropdownMenuItem(
                        value: 'always', child: Text('Selalu Aktif')),
                    DropdownMenuItem(
                        value: 'happy_hour', child: Text('Happy Hour')),
                    DropdownMenuItem(
                        value: 'member', child: Text('Member')),
                    DropdownMenuItem(
                        value: 'day_of_week',
                        child: Text('Hari Tertentu')),
                  ],
                  onChanged: (v) => setState(() => _ruleType = v!),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _discountType,
                        decoration:
                            const InputDecoration(labelText: 'Tipe Diskon'),
                        dropdownColor: kCardColor,
                        items: const [
                          DropdownMenuItem(
                              value: 'percentage',
                              child: Text('Persentase (%)')),
                          DropdownMenuItem(
                              value: 'fixed_amount',
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
                // Happy Hour / Day of Week options
                if (_ruleType == 'happy_hour' ||
                    _ruleType == 'day_of_week') ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: _startHour,
                          decoration: const InputDecoration(
                              labelText: 'Jam Mulai'),
                          dropdownColor: kCardColor,
                          items: List.generate(
                              24,
                              (i) => DropdownMenuItem(
                                  value: i,
                                  child: Text(
                                      '${i.toString().padLeft(2, '0')}:00'))),
                          onChanged: (v) =>
                              setState(() => _startHour = v!),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: _endHour,
                          decoration: const InputDecoration(
                              labelText: 'Jam Selesai'),
                          dropdownColor: kCardColor,
                          items: List.generate(
                              24,
                              (i) => DropdownMenuItem(
                                  value: i,
                                  child: Text(
                                      '${i.toString().padLeft(2, '0')}:00'))),
                          onChanged: (v) => setState(() => _endHour = v!),
                        ),
                      ),
                    ],
                  ),
                ],
                if (_ruleType == 'day_of_week') ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _daysOfWeekCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Hari (e.g. Mon,Tue,Wed)',
                        hintText: 'Mon,Tue,Wed'),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _minPurchaseCtrl,
                        decoration: const InputDecoration(
                            labelText: 'Min. Pembelian (Rp)'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _maxDiscountCtrl,
                        decoration: const InputDecoration(
                            labelText: 'Maks. Diskon (Rp)'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _priorityCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Prioritas (0 = rendah)'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 4),
                SwitchListTile(
                  title: const Text('Aktif',
                      style: TextStyle(color: kTextPrimary)),
                  value: _isActive,
                  onChanged: (v) => setState(() => _isActive = v),
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
