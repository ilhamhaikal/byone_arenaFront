import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../config/api_config.dart';
import '../../models/menu_model.dart';
import '../../providers/food_order_provider.dart';
import '../../providers/menu_provider.dart';
import '../../providers/session_provider.dart';
import '../../services/api_service.dart';

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
  final _cashCtrl = TextEditingController();
  String? _selectedSessionId;
  final List<_OrderItem> _items = [];
  bool _isLoading = false;
  bool _isLoadingPrice = false;
  double _autoDiscount = 0;
  double _finalAmount = 0;

  double get _cashReceived =>
      double.tryParse(_cashCtrl.text.replaceAll(',', '')) ?? 0;
  double get _change => (_cashReceived - _finalAmount).clamp(0, double.infinity);
  bool get _isEnough => _cashReceived >= _finalAmount;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MenuProvider>().loadMenus();
      // Pastikan sesi aktif tersedia untuk dropdown
      context.read<SessionProvider>().loadActive();
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
    if (existing != -1) {
      _items[existing].quantity++;
    } else {
      _items.add(_OrderItem(menu: menu));
    }
    _fetchPricePreview();
    // Defer setState — hindari bentrok dengan MouseTracker update
    // yang terjadi saat callback onTap dari GestureDetector.
    Future.microtask(() { if (mounted) setState(() {}); });
  }

  void _removeItem(int index) {
    _items.removeAt(index);
    _fetchPricePreview();
    Future.microtask(() { if (mounted) setState(() {}); });
  }

  void _changeQty(int index, int delta) {
    _items[index].quantity += delta;
    if (_items[index].quantity <= 0) _items.removeAt(index);
    _fetchPricePreview();
    Future.microtask(() { if (mounted) setState(() {}); });
  }

  Future<void> _fetchPricePreview() async {
    if (_items.isEmpty) {
      setState(() {
        _autoDiscount = 0;
        _finalAmount = _total;
      });
      return;
    }
    setState(() => _isLoadingPrice = true);
    try {
      final api = ApiService();
      final response = await api.post('${ApiConfig.foodOrders}/price-preview', {
        'items': _items.map((i) => {
          'menuId': i.menu.id,
          'quantity': i.quantity,
        }).toList(),
      });
      final data = response['data'];
      if (data != null) {
        setState(() {
          _autoDiscount = (data['autoDiscount'] as num?)?.toDouble() ?? 0;
          _finalAmount = (data['finalAmount'] as num?)?.toDouble() ?? _total;
        });
      }
    } catch (_) {
      setState(() {
        _autoDiscount = 0;
        _finalAmount = _total;
      });
    } finally {
      if (mounted) setState(() => _isLoadingPrice = false);
    }
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
    if (_cashReceived < _finalAmount) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Uang kurang! Total: Rp ${NumberFormat('#,###', 'id').format(_finalAmount.toInt())}'),
        backgroundColor: kErrorColor,
      ));
      return;
    }

    setState(() => _isLoading = true);

    final data = {
      'sessionId': _selectedSessionId,
      'autoDiscount': _autoDiscount,
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
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: SingleChildScrollView(
            child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            // Session selector
            DropdownButtonFormField<String>(
              value: _selectedSessionId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Pilih Sesi Aktif',
                labelStyle: TextStyle(color: kTextSecondary, fontSize: 13),
                filled: true,
                fillColor: kCardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                  borderSide: BorderSide(color: kBorderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                  borderSide: BorderSide(color: kBorderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                  borderSide: BorderSide(color: kPrimaryBlue),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              dropdownColor: kCardColor,
              style: const TextStyle(color: kTextPrimary, fontSize: 13),
              icon: const Icon(Icons.arrow_drop_down_rounded, color: kPrimaryBlue),
              items: sessions.isEmpty
                  ? null
                  : sessions
                      .map((s) => DropdownMenuItem<String>(
                            value: s.id,
                            child: Text(
                              '${s.consoleName.isNotEmpty ? s.consoleName : s.consoleId}${s.customerName != null ? ' — ${s.customerName}' : ''}',
                              style: const TextStyle(color: kTextPrimary, fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ))
                      .toList(),
              onChanged: sessions.isEmpty ? null : (v) => setState(() => _selectedSessionId = v),
              hint: Text(
                sessions.isEmpty ? 'Tidak ada sesi aktif — muat ulang halaman' : 'Pilih sesi',
                style: TextStyle(color: sessions.isEmpty ? kWarningColor : kTextSecondary, fontSize: 13),
              ),
            ),
            const SizedBox(height: 10),
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
            const SizedBox(height: 10),
            // Selected items list
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Item Pesanan:',
                  style:
                      TextStyle(color: kTextSecondary, fontSize: 12)),
            ),
            const SizedBox(height: 6),
            // Items list — bounded height (scrollable di dalam dialog)
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: _items.isEmpty ? 40 : (_items.length * 56.0).clamp(80, 220),
              ),
              child: _items.isEmpty
                  ? const Center(
                      child: Text('Belum ada item',
                          style: TextStyle(color: kTextSecondary)))
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
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
            const SizedBox(height: 6),
            TextField(
              controller: _notesCtrl,
              decoration: const InputDecoration(
                  labelText: 'Catatan (opsional)',
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
              maxLines: 1,
            ),
            const SizedBox(height: 6),
            // ── Ringkasan + Diskon ──
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: kCardColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: kBorderColor),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Subtotal', style: TextStyle(color: kTextSecondary, fontSize: 12)),
                      Text('Rp ${moneyFmt.format(_total.toInt())}',
                          style: const TextStyle(color: kTextPrimary, fontSize: 12)),
                    ],
                  ),
                  if (_autoDiscount > 0) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(children: [
                          Icon(Icons.local_offer_rounded, size: 12, color: kAccentPurple),
                          SizedBox(width: 4),
                          Text('Diskon Otomatis', style: TextStyle(color: kAccentPurple, fontSize: 12)),
                        ]),
                        Text('-Rp ${moneyFmt.format(_autoDiscount.toInt())}',
                            style: const TextStyle(color: kAccentPurple, fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                  const Divider(color: kBorderColor, height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total', style: TextStyle(color: kTextPrimary, fontWeight: FontWeight.w600)),
                      if (_isLoadingPrice)
                        const SizedBox(width: 14, height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: kAccentPurple))
                      else
                        Text('Rp ${moneyFmt.format(_finalAmount.toInt())}',
                            style: const TextStyle(color: kSuccessColor, fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // ── Pembayaran ──
            TextField(
              controller: _cashCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Uang Diterima',
                prefixIcon: Icon(Icons.payments_outlined, size: 18),
                hintText: '0',
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onChanged: (_) => setState(() {}),
            ),
            if (_cashReceived > 0) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _isEnough ? kSuccessColor.withAlpha(20) : kErrorColor.withAlpha(20),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: _isEnough ? kSuccessColor.withAlpha(60) : kErrorColor.withAlpha(60)),
                ),
                child: Text(
                  _isEnough ? 'Kembalian: Rp ${moneyFmt.format(_change.toInt())}'
                      : 'Kurang: Rp ${moneyFmt.format((_finalAmount - _cashReceived).toInt())}',
                  style: TextStyle(color: _isEnough ? kSuccessColor : kErrorColor, fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
            ],
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
