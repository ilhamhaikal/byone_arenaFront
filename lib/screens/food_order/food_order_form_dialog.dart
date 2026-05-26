import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/menu_model.dart';
import '../../providers/food_order_provider.dart';
import '../../providers/menu_provider.dart';
import '../../providers/session_provider.dart';

class _OrderItem {
  final MenuModel menu;
  int quantity;
  String? notes;

  _OrderItem({required this.menu, this.quantity = 1, this.notes});
}

class FoodOrderFormDialog extends StatefulWidget {
  const FoodOrderFormDialog({super.key});

  @override
  State<FoodOrderFormDialog> createState() => _FoodOrderFormDialogState();
}

class _FoodOrderFormDialogState extends State<FoodOrderFormDialog> {
  final _notesCtrl = TextEditingController();
  String? _selectedSessionId;
  final List<_OrderItem> _items = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MenuProvider>().loadMenus();
    });
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  double get _total =>
      _items.fold(0.0, (sum, i) => sum + i.menu.price * i.quantity);

  void _addMenu(MenuModel menu) {
    final existing = _items.indexWhere((i) => i.menu.id == menu.id);
    setState(() {
      if (existing != -1) {
        _items[existing].quantity++;
      } else {
        _items.add(_OrderItem(menu: menu));
      }
    });
  }

  void _removeItem(int index) {
    setState(() => _items.removeAt(index));
  }

  void _changeQty(int index, int delta) {
    setState(() {
      _items[index].quantity += delta;
      if (_items[index].quantity <= 0) _items.removeAt(index);
    });
  }

  Future<void> _save() async {
    if (_selectedSessionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Pilih sesi terlebih dahulu'),
        backgroundColor: kErrorColor,
      ));
      return;
    }
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Tambahkan minimal 1 menu'),
        backgroundColor: kErrorColor,
      ));
      return;
    }

    setState(() => _isLoading = true);

    final data = {
      'sessionId': _selectedSessionId,
      'items': _items
          .map((i) => {
                'menuItemId': i.menu.id,
                'quantity': i.quantity,
                if (i.notes != null && i.notes!.isNotEmpty)
                  'notes': i.notes,
              })
          .toList(),
      if (_notesCtrl.text.trim().isNotEmpty) 'notes': _notesCtrl.text.trim(),
    };

    final provider = context.read<FoodOrderProvider>();
    final success = await provider.createOrder(data);

    setState(() => _isLoading = false);
    if (mounted) {
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Pesanan berhasil dibuat'),
          backgroundColor: kSuccessColor,
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(provider.error ?? 'Gagal membuat pesanan'),
          backgroundColor: kErrorColor,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessions = context
        .watch<SessionProvider>()
        .activeSessions;
    final menus = context.watch<MenuProvider>().menus;
    final availableMenus =
        menus.where((m) => m.isAvailable).toList();

    final moneyFmt = _MoneyFmt();

    return AlertDialog(
      backgroundColor: kSurface,
      title: const Text('Buat Pesanan Makanan',
          style: TextStyle(color: kTextPrimary)),
      content: SizedBox(
        width: 500,
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            // Session selector
            DropdownButtonFormField<String>(
              value: _selectedSessionId,
              decoration: const InputDecoration(labelText: 'Pilih Sesi Aktif'),
              dropdownColor: kCardColor,
              items: sessions
                  .map((s) => DropdownMenuItem(
                        value: s.id,
                        child: Text(
                          '${s.console?.name ?? s.consoleId}${s.customer != null ? ' — ${s.customer!.name}' : ''}',
                          style:
                              const TextStyle(color: kTextPrimary, fontSize: 13),
                        ),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _selectedSessionId = v),
              hint: const Text('Pilih sesi',
                  style: TextStyle(color: kTextSecondary)),
            ),
            const SizedBox(height: 12),
            // Menu grid to select
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Pilih Menu:',
                  style:
                      TextStyle(color: kTextSecondary, fontSize: 12)),
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 140,
              child: availableMenus.isEmpty
                  ? const Center(
                      child: Text('Tidak ada menu tersedia',
                          style: TextStyle(color: kTextSecondary)))
                  : ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: availableMenus.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(width: 8),
                      itemBuilder: (ctx, i) {
                        final m = availableMenus[i];
                        return GestureDetector(
                          onTap: () => _addMenu(m),
                          child: Container(
                            width: 110,
                            decoration: BoxDecoration(
                              color: kCardColor,
                              borderRadius: BorderRadius.circular(10),
                              border:
                                  Border.all(color: kBorderColor),
                            ),
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding:
                                      const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: kPrimaryBlue.withAlpha(25),
                                    borderRadius:
                                        BorderRadius.circular(4),
                                  ),
                                  child: Text(m.categoryLabel,
                                      style: const TextStyle(
                                          color: kPrimaryBlue,
                                          fontSize: 9)),
                                ),
                                const SizedBox(height: 4),
                                Expanded(
                                  child: Text(m.name,
                                      style: const TextStyle(
                                          color: kTextPrimary,
                                          fontSize: 12,
                                          fontWeight:
                                              FontWeight.w600),
                                      maxLines: 2,
                                      overflow:
                                          TextOverflow.ellipsis),
                                ),
                                Text(
                                  'Rp ${moneyFmt.format(m.price.toInt())}',
                                  style: const TextStyle(
                                      color: kSuccessColor,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  width: double.infinity,
                                  padding:
                                      const EdgeInsets.symmetric(
                                          vertical: 4),
                                  decoration: BoxDecoration(
                                    gradient: kGradientBlue,
                                    borderRadius:
                                        BorderRadius.circular(6),
                                  ),
                                  child: const Center(
                                    child: Text('+ Tambah',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight:
                                                FontWeight.w600)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 12),
            // Selected items list
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Item Pesanan:',
                  style:
                      TextStyle(color: kTextSecondary, fontSize: 12)),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: _items.isEmpty
                  ? const Center(
                      child: Text('Belum ada item',
                          style: TextStyle(color: kTextSecondary)))
                  : ListView.builder(
                      itemCount: _items.length,
                      itemBuilder: (ctx, i) {
                        final item = _items[i];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: kCardColor,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: kBorderColor),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(item.menu.name,
                                        style: const TextStyle(
                                            color: kTextPrimary,
                                            fontSize: 12,
                                            fontWeight:
                                                FontWeight.w600)),
                                    Text(
                                      'Rp ${moneyFmt.format((item.menu.price * item.quantity).toInt())}',
                                      style: const TextStyle(
                                          color: kSuccessColor,
                                          fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                              // Qty control
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                        Icons.remove_circle_outline,
                                        size: 18,
                                        color: kErrorColor),
                                    onPressed: () => _changeQty(i, -1),
                                    padding: EdgeInsets.zero,
                                    constraints:
                                        const BoxConstraints(),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8),
                                    child: Text(
                                      '${item.quantity}',
                                      style: const TextStyle(
                                          color: kTextPrimary,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                        Icons.add_circle_outline,
                                        size: 18,
                                        color: kSuccessColor),
                                    onPressed: () => _changeQty(i, 1),
                                    padding: EdgeInsets.zero,
                                    constraints:
                                        const BoxConstraints(),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notesCtrl,
              decoration: const InputDecoration(
                  labelText: 'Catatan (opsional)',
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
              maxLines: 1,
            ),
            const SizedBox(height: 8),
            // Total
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: kCardColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: kBorderColor),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total',
                      style: TextStyle(color: kTextSecondary)),
                  Text(
                    'Rp ${moneyFmt.format(_total.toInt())}',
                    style: const TextStyle(
                        color: kSuccessColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  ),
                ],
              ),
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
              : const Text('Buat Pesanan'),
        ),
      ],
    );
  }
}

class _MoneyFmt {
  final NumberFormat _fmt = NumberFormat('#,###', 'id');
  String format(int v) => _fmt.format(v);
}
