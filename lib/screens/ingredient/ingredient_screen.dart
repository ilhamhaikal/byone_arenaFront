import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/ingredient_model.dart';
import '../../providers/capital_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ingredient_provider.dart';
import '../../providers/menu_provider.dart';
import '../../services/ingredient_service.dart';
import '../../utils/app_dialog.dart';

class IngredientScreen extends StatefulWidget {
  const IngredientScreen({super.key});
  @override
  State<IngredientScreen> createState() => _IngredientScreenState();
}

class _IngredientScreenState extends State<IngredientScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<IngredientProvider>().loadIngredients();
    });
  }

  void _openForm([IngredientModel? ing]) {
    showDialog(
      context: context,
      builder: (_) => _IngredientFormDialog(ingredient: ing),
    );
  }

  Future<void> _addCapital() async {
    final amount = TextEditingController();
    final notes = TextEditingController();
    DateTime date = DateTime.now();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          backgroundColor: kSurface,
          title: const Text('Tambah Modal Awal',
              style: TextStyle(color: kTextPrimary)),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: amount,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'Jumlah (Rp)', prefixText: 'Rp '),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    final d = await showDatePicker(
                      context: ctx,
                      initialDate: date,
                      firstDate: DateTime(2024),
                      lastDate: DateTime.now(),
                    );
                    if (d != null) setSt(() => date = d);
                  },
                  child: InputDecorator(
                    decoration:
                        const InputDecoration(labelText: 'Tanggal'),
                    child: Text(DateFormat('dd MMM yyyy', 'id').format(date)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notes,
                  decoration:
                      const InputDecoration(labelText: 'Catatan (opsional)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Batal')),
            ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Simpan')),
          ],
        ),
      ),
    );
    if (ok == true && mounted) {
      final success = await context.read<CapitalProvider>().addEntry({
        'amount': double.tryParse(amount.text.replaceAll(',', '')) ?? 0,
        'entryDate': DateFormat('yyyy-MM-dd').format(date),
        if (notes.text.trim().isNotEmpty) 'notes': notes.text.trim(),
      });
      if (mounted) {
        success
            ? showSuccessDialog('Modal awal dicatat')
            : showErrorDialog('Gagal menyimpan modal');
      }
    }
  }

  Future<void> _addStock(IngredientModel ing) async {
    final qty = TextEditingController();
    final notes = TextEditingController();
    DateTime expiry = DateTime.now().add(const Duration(days: 30));
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          backgroundColor: kSurface,
          title: Text('Tambah Stok: ${ing.name}',
              style: const TextStyle(color: kTextPrimary)),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: qty,
                  keyboardType:
                      TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                      labelText: 'Jumlah (${ing.unit})'),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    final d = await showDatePicker(
                      context: ctx,
                      initialDate: expiry,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 3650)),
                    );
                    if (d != null) setState(() => expiry = d);
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                        labelText: 'Kadaluarsa / baik digunakan sampai'),
                    child: Text(DateFormat('dd MMM yyyy', 'id').format(expiry)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notes,
                  decoration: const InputDecoration(
                      labelText: 'Catatan (opsional)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Batal')),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
    if (ok == true) {
      final success = await context.read<IngredientProvider>().addStock(
            ing.id,
            {
              'quantity': double.tryParse(qty.text) ?? 0,
              'expiresAt': DateFormat('yyyy-MM-dd').format(expiry),
              if (notes.text.trim().isNotEmpty) 'notes': notes.text.trim(),
            },
          );
      if (mounted) {
        if (success) {
          // Stok menu dihitung dari stok bahan — refresh MenuProvider supaya
          // halaman Menu langsung menampilkan stok baru tanpa edit+simpan.
          unawaited(context.read<MenuProvider>().loadMenus());
          showSuccessDialog('Stok ditambahkan');
        } else {
          showErrorDialog('Gagal menambah stok');
        }
      }
    }
  }

  Future<void> _showBatches(IngredientModel ing) async {
    final service = IngredientService();
    final batches = await service.listBatches(ing.id);
    if (!mounted) return;
    final fmt = NumberFormat('#,###.##', 'id');
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: kSurface,
        title: Text('Riwayat Stok: ${ing.name}',
            style: const TextStyle(color: kTextPrimary)),
        content: SizedBox(
          width: 420,
          child: batches.isEmpty
              ? const Text('Belum ada batch',
                  style: TextStyle(color: kTextSecondary))
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: batches.length,
                  separatorBuilder: (_, __) => const Divider(color: kBorderColor),
                  itemBuilder: (ctx, i) {
                    final b = batches[i];
                    final statusColor = b.isConsumed
                        ? kTextSecondary
                        : (b.isExpired ? kErrorColor : kSuccessColor);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${fmt.format(b.quantity)} ${ing.unit}',
                              style: const TextStyle(
                                  color: kTextPrimary,
                                  fontWeight: FontWeight.w600),
                            ),
                            Text(
                              b.statusLabel,
                              style: TextStyle(
                                  color: statusColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                        Text(
                          'Ditambah: ${DateFormat('dd MMM yyyy', 'id').format(b.addedAt)} • '
                          'Sisa ${fmt.format(b.remaining)}',
                          style: const TextStyle(
                              color: kTextSecondary, fontSize: 11),
                        ),
                        if (!b.isConsumed)
                          Text(
                            'Kadaluarsa: ${DateFormat('dd MMM yyyy', 'id').format(b.expiresAt)}',
                            style: TextStyle(
                                color: statusColor, fontSize: 11),
                          ),
                        if (b.notes != null && b.notes!.isNotEmpty)
                          Text('Catatan: ${b.notes}',
                              style: const TextStyle(
                                  color: kTextSecondary, fontSize: 11)),
                      ],
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tutup')),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(IngredientModel ing) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: kSurface,
        title: const Text('Hapus Bahan',
            style: TextStyle(color: kTextPrimary)),
        content: Text('Hapus bahan "${ing.name}"?',
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
      final success =
          await context.read<IngredientProvider>().deleteIngredient(ing.id);
      if (mounted) {
        if (success) {
          showSuccessDialog('Bahan dihapus');
        } else {
          showErrorDialog('Gagal menghapus');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = context.watch<AuthProvider>().user?.role ?? '';
    final canManage = role == 'admin' || role == 'superadmin';

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0F),
        title: const Text('Manajemen Bahan'),
        actions: [
          IconButton(
            tooltip: 'Tambah Modal Awal',
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: kGradientAmber,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.account_balance_wallet_outlined,
                  size: 16, color: Colors.white),
            ),
            onPressed: _addCapital,
          ),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: kGradientGreen,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.add_rounded, size: 16, color: Colors.white),
            ),
            onPressed: _openForm,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Consumer<IngredientProvider>(
        builder: (context, p, _) {
          if (p.isLoading) {
            return const Center(child: CircularProgressIndicator(color: kPrimaryBlue));
          }
          if (p.ingredients.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.egg_outlined, size: 48, color: kTextSecondary),
                  const SizedBox(height: 12),
                  const Text('Belum ada bahan',
                      style: TextStyle(color: kTextPrimary)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _openForm,
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: const Text('Tambah Bahan'),
                  ),
                ],
              ),
            );
          }
          final fmt = NumberFormat('#,###.##', 'id');
          return RefreshIndicator(
            color: kPrimaryBlue,
            onRefresh: p.loadIngredients,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: p.ingredients.length,
              itemBuilder: (ctx, i) {
                final ing = p.ingredients[i];
                final habis = ing.stock <= 0;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: kCardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: kBorderColor),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(ing.name,
                                style: const TextStyle(
                                    color: kTextPrimary,
                                    fontWeight: FontWeight.w600)),
                            Text('Stok: ${fmt.format(ing.stock)} ${ing.unit}',
                                style: TextStyle(
                                    color: habis ? kErrorColor : kSuccessColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      if (canManage)
                        IconButton(
                          tooltip: 'Tambah Stok',
                          icon: const Icon(Icons.add_box_outlined,
                              size: 20, color: kSuccessColor),
                          onPressed: () => _addStock(ing),
                        ),
                      IconButton(
                        tooltip: 'Riwayat',
                        icon: const Icon(Icons.history_rounded,
                            size: 20, color: kPrimaryBlue),
                        onPressed: () => _showBatches(ing),
                      ),
                      if (canManage)
                        IconButton(
                          tooltip: 'Edit',
                          icon: const Icon(Icons.edit_outlined,
                              size: 20, color: kTextSecondary),
                          onPressed: () => _openForm(ing),
                        ),
                      if (canManage)
                        IconButton(
                          tooltip: 'Hapus',
                          icon: const Icon(Icons.delete_outline,
                              size: 20, color: kErrorColor),
                          onPressed: () => _confirmDelete(ing),
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

class _IngredientFormDialog extends StatefulWidget {
  final IngredientModel? ingredient;
  const _IngredientFormDialog({this.ingredient});
  @override
  State<_IngredientFormDialog> createState() => _IngredientFormDialogState();
}

class _IngredientFormDialogState extends State<_IngredientFormDialog> {
  late TextEditingController _nameCtrl;
  late TextEditingController _unitCtrl;
  bool _isLoading = false;
  bool get _isEdit => widget.ingredient != null;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.ingredient?.name ?? '');
    _unitCtrl = TextEditingController(text: widget.ingredient?.unit ?? 'pcs');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _unitCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);
    final provider = context.read<IngredientProvider>();
    final data = {
      'name': _nameCtrl.text.trim(),
      'unit': _unitCtrl.text.trim().isEmpty ? 'pcs' : _unitCtrl.text.trim(),
    };
    bool success;
    if (_isEdit) {
      success = await provider.updateIngredient(widget.ingredient!.id, data);
    } else {
      success = await provider.createIngredient(data);
    }
    setState(() => _isLoading = false);
    if (mounted) {
      Navigator.pop(context);
      if (success) {
        showSuccessDialog(_isEdit ? 'Bahan diperbarui' : 'Bahan ditambahkan');
      } else {
        showErrorDialog('Gagal menyimpan');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: kSurface,
      title: Text(_isEdit ? 'Edit Bahan' : 'Tambah Bahan',
          style: const TextStyle(color: kTextPrimary)),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Nama Bahan'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _unitCtrl,
              decoration: const InputDecoration(
                  labelText: 'Satuan (pcs/kg/ml)'),
            ),
          ],
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
