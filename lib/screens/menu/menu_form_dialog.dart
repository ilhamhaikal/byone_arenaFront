import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/menu_model.dart';
import '../../models/ingredient_model.dart';
import '../../providers/menu_provider.dart';
import '../../services/ingredient_service.dart';
import '../../services/menu_service.dart';
import '../../utils/app_dialog.dart';

class MenuFormDialog extends StatefulWidget {
  final MenuModel? menu;
  const MenuFormDialog({super.key, this.menu});

  @override
  State<MenuFormDialog> createState() => _MenuFormDialogState();
}

class _RecipeRow {
  String? ingredientId;
  TextEditingController qty = TextEditingController(text: '1');
}

class _MenuFormDialogState extends State<MenuFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _priceCtrl;
  late TextEditingController _hppCtrl;
  String _category = 'food';
  bool _isAvailable = true;
  bool _isLoading = false;

  final IngredientService _ingredientService = IngredientService();
  List<IngredientModel> _ingredients = [];
  final List<_RecipeRow> _recipeRows = [];
  bool _loadingRecipe = false;

  bool get _isEdit => widget.menu != null;

  /// Kadaluarsa menu = tanggal paling awal dari bahan-bahan yang dipilih.
  DateTime? get _computedExpiry {
    DateTime? result;
    for (final r in _recipeRows) {
      final id = r.ingredientId;
      if (id == null) continue;
      IngredientModel? match;
      for (final i in _ingredients) {
        if (i.id == id) {
          match = i;
          break;
        }
      }
      final e = match?.nearestExpiry;
      if (e != null && (result == null || e.isBefore(result))) {
        result = e;
      }
    }
    return result;
  }

  @override
  void initState() {
    super.initState();
    final m = widget.menu;
    _nameCtrl = TextEditingController(text: m?.name ?? '');
    _descCtrl = TextEditingController(text: m?.description ?? '');
    _priceCtrl =
        TextEditingController(text: m?.price.toStringAsFixed(0) ?? '');
    _hppCtrl =
        TextEditingController(text: m?.hpp.toStringAsFixed(0) ?? '0');
    _category = m?.category ?? 'food';
    _isAvailable = m?.isAvailable ?? true;
    _loadRecipe();
  }

  Future<void> _loadRecipe() async {
    setState(() => _loadingRecipe = true);
    try {
      final ings = await _ingredientService.getIngredients();
      if (_isEdit) {
        final recipe =
            await _ingredientService.listMenuIngredients(widget.menu!.id);
        if (!mounted) return;
        setState(() {
          _ingredients = ings;
          for (final r in recipe) {
            final row = _RecipeRow();
            row.ingredientId = r.ingredientId;
            row.qty = TextEditingController(text: r.quantity.toString());
            _recipeRows.add(row);
          }
          _loadingRecipe = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          _ingredients = ings;
          _loadingRecipe = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingRecipe = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _hppCtrl.dispose();
    for (final r in _recipeRows) {
      r.qty.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final data = <String, dynamic>{
      'name': _nameCtrl.text.trim(),
      'category': _category,
      'price': double.tryParse(_priceCtrl.text) ?? 0.0,
      'hpp': double.tryParse(_hppCtrl.text) ?? 0.0,
      'isAvailable': _isAvailable,
      if (_descCtrl.text.trim().isNotEmpty)
        'description': _descCtrl.text.trim(),
    };

    final recipeItems = <Map<String, dynamic>>[];
    for (final r in _recipeRows) {
      if (r.ingredientId == null) continue;
      final qty = double.tryParse(r.qty.text) ?? 0;
      if (qty <= 0) continue;
      recipeItems.add({'ingredientId': r.ingredientId, 'quantity': qty});
    }

    final menuService = MenuService();
    final ingredientService = IngredientService();
    try {
      String? menuId;
      if (_isEdit) {
        await menuService.updateMenu(widget.menu!.id, data);
        menuId = widget.menu!.id;
      } else {
        final created = await menuService.createMenu(data);
        menuId = created.id;
      }
      if (menuId != null && recipeItems.isNotEmpty) {
        await ingredientService.setMenuIngredients(menuId, recipeItems);
      }
      if (mounted) {
        await context.read<MenuProvider>().loadMenus();
      }
      setState(() => _isLoading = false);
      if (mounted) {
        Navigator.pop(context);
        showSuccessDialog(_isEdit ? 'Menu diperbarui' : 'Menu ditambahkan');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        showErrorDialog('Gagal menyimpan: $e');
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
                const SizedBox(height: 12),
                TextFormField(
                  controller: _hppCtrl,
                  decoration: const InputDecoration(
                      labelText: 'HPP / pcs (Rp)'),
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
                const SizedBox(height: 12),
                // ── Tanggal kadaluarsa (otomatis dari bahan) ──
                InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Tanggal Kadaluarsa (otomatis)',
                    suffixIcon: Icon(Icons.lock_outline_rounded,
                        size: 16, color: kTextSecondary),
                  ),
                  child: Text(
                    _computedExpiry == null
                        ? 'Belum diatur (pilih bahan)'
                        : DateFormat('dd MMM yyyy', 'id')
                            .format(_computedExpiry!),
                    style: TextStyle(
                      color: _computedExpiry == null
                          ? kTextSecondary
                          : kTextPrimary,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // ── Resep (bahan) ──
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Resep (bahan penyusun):',
                      style: TextStyle(
                          color: kTextSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 6),
                if (_loadingRecipe)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Center(
                        child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: kPrimaryBlue))),
                  )
                else if (_ingredients.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                        'Belum ada bahan. Tambahkan dulu di halaman Bahan.',
                        style: TextStyle(
                            color: kWarningColor, fontSize: 11)),
                  )
                else ...[
                  ..._recipeRows.map((r) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: DropdownButtonFormField<String>(
                                value: r.ingredientId,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                    labelText: 'Bahan', isDense: true),
                                dropdownColor: kCardColor,
                                items: _ingredients
                                    .map((i) => DropdownMenuItem(
                                          value: i.id,
                                          child: Text(
                                              '${i.name} (${i.unit})',
                                              overflow:
                                                  TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                  color: kTextPrimary)),
                                        ))
                                    .toList(),
                                onChanged: (v) =>
                                    setState(() => r.ingredientId = v),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 70,
                              child: TextField(
                                controller: r.qty,
                                keyboardType: TextInputType.numberWithOptions(
                                    decimal: true),
                                decoration: const InputDecoration(
                                    labelText: 'Qty', isDense: true),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close_rounded,
                                  size: 18, color: kErrorColor),
                              onPressed: () =>
                                  setState(() => _recipeRows.remove(r)),
                            ),
                          ],
                        ),
                      )),
                  TextButton.icon(
                    onPressed: () =>
                        setState(() => _recipeRows.add(_RecipeRow())),
                    icon: const Icon(Icons.add_rounded,
                        size: 16, color: kPrimaryBlue),
                    label: const Text('Tambah Bahan',
                        style: TextStyle(color: kPrimaryBlue)),
                  ),
                ],
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
