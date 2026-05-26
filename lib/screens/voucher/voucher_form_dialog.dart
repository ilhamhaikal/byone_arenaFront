import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/voucher_model.dart';
import '../../providers/voucher_provider.dart';

class VoucherFormDialog extends StatefulWidget {
  final VoucherModel? voucher;

  const VoucherFormDialog({super.key, this.voucher});

  @override
  State<VoucherFormDialog> createState() => _VoucherFormDialogState();
}

class _VoucherFormDialogState extends State<VoucherFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _codeCtrl;
  late TextEditingController _nameCtrl;
  late TextEditingController _valueCtrl;
  late TextEditingController _minTxCtrl;
  late TextEditingController _maxUsageCtrl;
  String _discountType = 'percentage';
  late DateTime _expiredAt;
  bool _isActive = true;
  bool _isLoading = false;

  bool get _isEdit => widget.voucher != null;

  @override
  void initState() {
    super.initState();
    final v = widget.voucher;
    _codeCtrl = TextEditingController(text: v?.code ?? '');
    _nameCtrl = TextEditingController(text: v?.name ?? '');
    _valueCtrl =
        TextEditingController(text: v?.discountValue.toStringAsFixed(0) ?? '');
    _minTxCtrl = TextEditingController(
        text: v?.minTransaction?.toStringAsFixed(0) ?? '');
    _maxUsageCtrl =
        TextEditingController(text: v?.maxUsage.toString() ?? '100');
    _discountType = v?.discountType ?? 'percentage';
    _expiredAt = v?.expiredAt ??
        DateTime.now().add(const Duration(days: 30));
    _isActive = v?.isActive ?? true;
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _nameCtrl.dispose();
    _valueCtrl.dispose();
    _minTxCtrl.dispose();
    _maxUsageCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickExpiredDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiredAt,
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _expiredAt = picked);
  }

  void _generateCode() {
    final code = 'PS${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    setState(() => _codeCtrl.text = code.toUpperCase());
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final voucher = VoucherModel(
      id: widget.voucher?.id ?? 0,
      code: _codeCtrl.text.trim().toUpperCase(),
      name: _nameCtrl.text.trim(),
      discountType: _discountType,
      discountValue: double.parse(_valueCtrl.text),
      minTransaction: _minTxCtrl.text.isNotEmpty
          ? double.tryParse(_minTxCtrl.text)
          : null,
      maxUsage: int.parse(_maxUsageCtrl.text),
      usedCount: widget.voucher?.usedCount ?? 0,
      expiredAt: _expiredAt,
      isActive: _isActive,
    );

    final provider = context.read<VoucherProvider>();
    bool success;
    if (_isEdit) {
      success = await provider.updateVoucher(widget.voucher!.id, voucher);
    } else {
      success = await provider.createVoucher(voucher);
    }

    setState(() => _isLoading = false);
    if (mounted) {
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text(_isEdit ? 'Voucher diperbarui' : 'Voucher ditambahkan'),
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
      title: Text(_isEdit ? 'Edit Voucher' : 'Tambah Voucher'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _codeCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Kode Voucher',
                          prefixIcon:
                              Icon(Icons.confirmation_number_outlined),
                        ),
                        textCapitalization: TextCapitalization.characters,
                        validator: (v) => v == null || v.isEmpty
                            ? 'Wajib diisi'
                            : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: _generateCode,
                      icon: const Icon(Icons.auto_fix_high, size: 16),
                      label: const Text('Auto'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nameCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Nama Voucher'),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Wajib diisi' : null,
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
                              value: 'fixed', child: Text('Nominal (Rp)')),
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
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Wajib diisi' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _minTxCtrl,
                        decoration: const InputDecoration(
                            labelText: 'Min. Transaksi (opsional)'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _maxUsageCtrl,
                        decoration:
                            const InputDecoration(labelText: 'Maks. Penggunaan'),
                        keyboardType: TextInputType.number,
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Wajib diisi' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: _pickExpiredDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Tanggal Kedaluwarsa',
                      prefixIcon: Icon(Icons.event),
                    ),
                    child: Text(dateFmt(_expiredAt),
                        style: const TextStyle(color: kTextPrimary)),
                  ),
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
