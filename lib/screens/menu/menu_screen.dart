import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/menu_model.dart';
import '../../models/ingredient_model.dart';
import '../../providers/menu_provider.dart';
import '../../services/ingredient_service.dart';
import 'menu_form_dialog.dart';
import '../../utils/app_dialog.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});
  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MenuProvider>().loadMenus();
    });
  }

  void _openForm([MenuModel? menu]) {
    showDialog(
        context: context,
        builder: (_) => MenuFormDialog(menu: menu));
  }

  Future<void> _confirmDelete(MenuModel menu) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: kSurface,
        title: const Text('Hapus Menu',
            style: TextStyle(color: kTextPrimary)),
        content: Text('Hapus menu "${menu.name}"?',
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
      final success = await context.read<MenuProvider>().deleteMenu(menu.id);
      if (mounted) {
        if (success) {
          showSuccessDialog('Menu berhasil dihapus');
        } else {
          showErrorDialog('Gagal menghapus menu');
        }
      }
    }
  }

  void _openRecipe(MenuModel menu) {
    final menuProv = context.read<MenuProvider>();
    showDialog(
      context: context,
      builder: (_) => _RecipeDialog(menu: menu),
    ).then((_) {
      // Resep berubah → stok menu (derived dari bahan) ikut berubah.
      // Reload menu supaya stok langsung ter-update tanpa edit+simpan.
      menuProv.loadMenus();
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0F),
        title: const Text('Manajemen Menu'),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: kGradientGreen,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                      color: kSuccessColor.withAlpha(80), blurRadius: 8)
                ],
              ),
              child: const Icon(Icons.add_rounded,
                  size: 16, color: Colors.white),
            ),
            onPressed: _openForm,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Consumer<MenuProvider>(
        builder: (context, p, _) {
          if (p.isLoading) {
            return const Center(
                child: CircularProgressIndicator(color: kPrimaryBlue));
          }
          if (p.error != null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline,
                      size: 48, color: kErrorColor),
                  const SizedBox(height: 12),
                  Text(p.error!,
                      style: const TextStyle(color: kTextSecondary),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                      onPressed: p.loadMenus, child: const Text('Coba Lagi')),
                ],
              ),
            );
          }

          final allMenus = p.menus;
          final filtered = _selectedCategory == null
              ? allMenus
              : allMenus
                  .where((m) => m.category == _selectedCategory)
                  .toList();

          return Column(
            children: [
              // Category filter — horizontal scroll
              Container(
                color: const Color(0xFF0A0A0F),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _CategoryChip(
                        label: 'Semua',
                        isSelected: _selectedCategory == null,
                        onTap: () =>
                            setState(() => _selectedCategory = null),
                      ),
                      const SizedBox(width: 8),
                      ...MenuModel.categories.map((cat) {
                        final labels = {
                          'food': 'Makanan',
                          'drink': 'Minuman',
                          'snack': 'Snack',
                          'other': 'Lainnya',
                        };
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _CategoryChip(
                            label: labels[cat] ?? cat,
                            isSelected: _selectedCategory == cat,
                            onTap: () =>
                                setState(() => _selectedCategory = cat),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
              // Menu list
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                color: kCardColor,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: kBorderColor),
                              ),
                              child: const Icon(
                                  Icons.restaurant_menu_outlined,
                                  size: 36,
                                  color: kTextSecondary),
                            ),
                            const SizedBox(height: 16),
                            const Text('Belum ada menu',
                                style: TextStyle(
                                    color: kTextPrimary,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500)),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              onPressed: _openForm,
                              icon: const Icon(Icons.add_rounded,
                                  size: 16),
                              label: const Text('Tambah Menu'),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        color: kPrimaryBlue,
                        backgroundColor: kSurface,
                        onRefresh: p.loadMenus,
                        child: GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate:
                              const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 300,
                            childAspectRatio: 1.18,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemCount: filtered.length,
                          itemBuilder: (ctx, i) => _MenuCard(
                            menu: filtered[i],
                            onEdit: () => _openForm(filtered[i]),
                            onDelete: () => _confirmDelete(filtered[i]),
                            onToggle: () =>
                                p.toggleMenu(filtered[i].id),
                            onRecipe: () => _openRecipe(filtered[i]),
                          ),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _CategoryChip(
      {required this.label,
      required this.isSelected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: isSelected ? kGradientBlue : null,
          color: isSelected ? null : kCardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: isSelected ? Colors.transparent : kBorderColor),
        ),
        child: Text(
          label,
          style: TextStyle(
              color: isSelected ? Colors.white : kTextSecondary,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal),
        ),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final MenuModel menu;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggle;
  final VoidCallback onRecipe;

  const _MenuCard({
    required this.menu,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
    required this.onRecipe,
  });

  Color get _catColor {
    switch (menu.category) {
      case 'food':
        return kNeonPink;
      case 'drink':
        return kPrimaryBlue;
      case 'snack':
        return kWarningColor;
      default:
        return kTextSecondary;
    }
  }

  Color get _expiryColor {
    switch (menu.expiryStatus) {
      case MenuExpiryStatus.expired:
        return kErrorColor;
      case MenuExpiryStatus.nearExpiry:
        return kWarningColor;
      case MenuExpiryStatus.fresh:
        return kSuccessColor;
      case MenuExpiryStatus.none:
        return kTextSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final moneyFmt = NumberFormat('#,###', 'id');

    return Container(
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color:
                menu.isAvailable ? _catColor.withAlpha(60) : kBorderColor,
            width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _catColor.withAlpha(menu.isAvailable ? 25 : 10),
                  Colors.transparent,
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
              border: const Border(
                  bottom: BorderSide(color: kBorderColor, width: 0.5)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _catColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: _catColor.withAlpha(60), width: 0.5),
                  ),
                  child: Text(
                    menu.categoryLabel,
                    style: TextStyle(
                        color: _catColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w600),
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: onToggle,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: menu.isAvailable
                          ? kSuccessColor.withAlpha(25)
                          : kErrorColor.withAlpha(20),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      menu.isAvailable ? 'Tersedia' : 'Habis',
                      style: TextStyle(
                          color: menu.isAvailable
                              ? kSuccessColor
                              : kErrorColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Body
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    menu.name,
                    style: const TextStyle(
                        color: kTextPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (menu.description != null &&
                      menu.description!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      menu.description!,
                      style: const TextStyle(
                          color: kTextSecondary, fontSize: 11),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 2),
                  // Status kadaluarsa
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: _expiryColor.withAlpha(25),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                              color: _expiryColor.withAlpha(60),
                              width: 0.5),
                        ),
                        child: Text(
                          menu.expiryLabel,
                          style: TextStyle(
                              color: _expiryColor,
                              fontSize: 9,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                      if (menu.expiresAt != null) ...[
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            DateFormat('dd MMM yyyy', 'id')
                                .format(menu.expiresAt!),
                            style: const TextStyle(
                                color: kTextSecondary, fontSize: 9),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const Spacer(),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Stok: ${menu.stock.toStringAsFixed(0)}',
                                style: TextStyle(
                                    color: menu.stock <= 0
                                        ? kErrorColor
                                        : kTextSecondary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600)),
                            if (menu.limitingIngredient != null &&
                                menu.limitingIngredient!.isNotEmpty)
                              Text(
                                'Terbatas: ${menu.limitingIngredient} '
                                '(${menu.limitingIngredientStock.toStringAsFixed(0)})',
                                style: const TextStyle(
                                    color: kWarningColor, fontSize: 9),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text('HPP: Rp ${moneyFmt.format(menu.hpp.toInt())}',
                          style: const TextStyle(
                              color: kTextSecondary, fontSize: 11)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Rp ${moneyFmt.format(menu.price.toInt())}',
                    style: const TextStyle(
                        color: kSuccessColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
          // Actions
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onRecipe,
                    style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                    child: const Text('Resep',
                        style: TextStyle(fontSize: 10)),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: OutlinedButton(
                    onPressed: onEdit,
                    style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                    child: const Text('Edit',
                        style: TextStyle(fontSize: 10)),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: OutlinedButton(
                    onPressed: onDelete,
                    style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        foregroundColor: kErrorColor,
                        side: BorderSide(
                            color: kErrorColor.withAlpha(100))),
                    child: const Text('Hapus',
                        style: TextStyle(fontSize: 10)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Dialog Resep Menu ─────────────────────────────────────────────────────
class _RecipeDialog extends StatefulWidget {
  final MenuModel menu;
  const _RecipeDialog({required this.menu});
  @override
  State<_RecipeDialog> createState() => _RecipeDialogState();
}

class _RecipeRow {
  String? ingredientId;
  TextEditingController qty = TextEditingController(text: '1');
}

class _RecipeDialogState extends State<_RecipeDialog> {
  final IngredientService _service = IngredientService();
  List<IngredientModel> _ingredients = [];
  final List<_RecipeRow> _rows = [];
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final ings = await _service.getIngredients();
      final recipe = await _service.listMenuIngredients(widget.menu.id);
      if (!mounted) return;
      setState(() {
        _ingredients = ings;
        for (final r in recipe) {
          final row = _RecipeRow();
          row.ingredientId = r.ingredientId;
          row.qty = TextEditingController(text: r.quantity.toString());
          _rows.add(row);
        }
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    final items = <Map<String, dynamic>>[];
    for (final r in _rows) {
      if (r.ingredientId == null) continue;
      final qty = double.tryParse(r.qty.text) ?? 0;
      if (qty <= 0) continue;
      items.add({'ingredientId': r.ingredientId, 'quantity': qty});
    }
    setState(() => _saving = true);
    try {
      await _service.setMenuIngredients(widget.menu.id, items);
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        showErrorDialog('Gagal menyimpan resep');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: kSurface,
      title: Text('Resep: ${widget.menu.name}',
          style: const TextStyle(color: kTextPrimary)),
      content: SizedBox(
        width: 460,
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: kPrimaryBlue))
            : SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_rows.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text('Belum ada bahan',
                            style: TextStyle(color: kTextSecondary)),
                      ),
                    ..._rows.map((r) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: DropdownButtonFormField<String>(
                                  value: r.ingredientId,
                                  decoration: const InputDecoration(
                                      labelText: 'Bahan',
                                      isDense: true),
                                  dropdownColor: kCardColor,
                                  items: _ingredients
                                      .map((i) => DropdownMenuItem(
                                            value: i.id,
                                            child: Text(
                                                '${i.name} (${i.unit})',
                                                style: const TextStyle(
                                                    color: kTextPrimary)),
                                          ))
                                      .toList(),
                                  onChanged: (v) => setState(
                                      () => r.ingredientId = v),
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
                                    setState(() => _rows.remove(r)),
                              ),
                            ],
                          ),
                        )),
                    TextButton.icon(
                      onPressed: () => setState(() => _rows.add(_RecipeRow())),
                      icon: const Icon(Icons.add_rounded,
                          size: 16, color: kPrimaryBlue),
                      label: const Text('Tambah Bahan',
                          style: TextStyle(color: kPrimaryBlue)),
                    ),
                  ],
                ),
              ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal')),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Text('Simpan'),
        ),
      ],
    );
  }
}
