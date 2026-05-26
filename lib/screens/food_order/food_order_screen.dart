import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/food_order_model.dart';
import '../../providers/food_order_provider.dart';
import 'food_order_form_dialog.dart';

class FoodOrderScreen extends StatefulWidget {
  const FoodOrderScreen({super.key});
  @override
  State<FoodOrderScreen> createState() => _FoodOrderScreenState();
}

class _FoodOrderScreenState extends State<FoodOrderScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _statusTabs = const ['Semua', 'pending', 'preparing', 'served', 'cancelled'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _statusTabs.length, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FoodOrderProvider>().loadOrders();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openForm() {
    showDialog(
        context: context,
        builder: (_) => const FoodOrderFormDialog());
  }

  List<FoodOrderModel> _filteredOrders(
      List<FoodOrderModel> all, int tabIndex) {
    if (tabIndex == 0) return all;
    final status = _statusTabs[tabIndex];
    return all.where((o) => o.status == status).toList();
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return kWarningColor;
      case 'preparing':
        return kPrimaryBlue;
      case 'served':
        return kSuccessColor;
      case 'cancelled':
        return kErrorColor;
      default:
        return kTextSecondary;
    }
  }

  String _nextStatusLabel(String current) {
    switch (current) {
      case 'pending':
        return 'Siapkan';
      case 'preparing':
        return 'Selesai';
      default:
        return '';
    }
  }

  String _nextStatus(String current) {
    switch (current) {
      case 'pending':
        return 'preparing';
      case 'preparing':
        return 'served';
      default:
        return '';
    }
  }

  Future<void> _updateStatus(
      BuildContext context, FoodOrderModel order) async {
    final next = _nextStatus(order.status);
    if (next.isEmpty) return;
    await context.read<FoodOrderProvider>().updateStatus(order.id, next);
  }

  Future<void> _cancelOrder(
      BuildContext context, FoodOrderModel order) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: kSurface,
        title: const Text('Batalkan Pesanan',
            style: TextStyle(color: kTextPrimary)),
        content: Text(
            'Batalkan pesanan ${order.orderNumber}?',
            style: const TextStyle(color: kTextSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Tidak')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: kErrorColor),
            child: const Text('Batalkan'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await context.read<FoodOrderProvider>().cancelOrder(order.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDeepBlack,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0F),
        title: const Text('Pemesanan Makanan'),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: kGradientPink,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                      color: kNeonPink.withAlpha(80), blurRadius: 8)
                ],
              ),
              child: const Icon(Icons.add_rounded,
                  size: 16, color: Colors.white),
            ),
            onPressed: _openForm,
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: kPrimaryBlue,
          labelColor: kTextPrimary,
          unselectedLabelColor: kTextSecondary,
          tabs: [
            const Tab(text: 'Semua'),
            ..._statusTabs.skip(1).map((s) {
              final labels = {
                'pending': 'Menunggu',
                'preparing': 'Disiapkan',
                'served': 'Selesai',
                'cancelled': 'Dibatalkan',
              };
              return Tab(text: labels[s] ?? s);
            }),
          ],
        ),
      ),
      body: Consumer<FoodOrderProvider>(
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
                      onPressed: p.loadOrders,
                      child: const Text('Coba Lagi')),
                ],
              ),
            );
          }

          return TabBarView(
            controller: _tabController,
            children: List.generate(_statusTabs.length, (tabIdx) {
              final orders =
                  _filteredOrders(p.orders, tabIdx);
              if (orders.isEmpty) {
                return Center(
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
                        child: const Icon(Icons.receipt_long_outlined,
                            size: 36, color: kTextSecondary),
                      ),
                      const SizedBox(height: 16),
                      const Text('Belum ada pesanan',
                          style: TextStyle(
                              color: kTextPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w500)),
                      if (tabIdx == 0) ...[
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: _openForm,
                          icon: const Icon(Icons.add_rounded, size: 16),
                          label: const Text('Buat Pesanan'),
                        ),
                      ],
                    ],
                  ),
                );
              }
              return RefreshIndicator(
                color: kPrimaryBlue,
                backgroundColor: kSurface,
                onRefresh: p.loadOrders,
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  itemCount: orders.length,
                  itemBuilder: (ctx, i) => _FoodOrderCard(
                    order: orders[i],
                    statusColor: _statusColor(orders[i].status),
                    nextStatusLabel: _nextStatusLabel(orders[i].status),
                    onAdvance: orders[i].status == 'pending' ||
                            orders[i].status == 'preparing'
                        ? () => _updateStatus(context, orders[i])
                        : null,
                    onCancel: orders[i].status != 'served' &&
                            orders[i].status != 'cancelled'
                        ? () => _cancelOrder(context, orders[i])
                        : null,
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

class _FoodOrderCard extends StatelessWidget {
  final FoodOrderModel order;
  final Color statusColor;
  final String nextStatusLabel;
  final VoidCallback? onAdvance;
  final VoidCallback? onCancel;

  const _FoodOrderCard({
    required this.order,
    required this.statusColor,
    required this.nextStatusLabel,
    this.onAdvance,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final moneyFmt = NumberFormat('#,###', 'id');
    final timeFmt = DateFormat('dd MMM, HH:mm');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: statusColor.withAlpha(60), width: 0.5),
        boxShadow: [
          BoxShadow(color: statusColor.withAlpha(12), blurRadius: 16)
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  statusColor.withAlpha(20),
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
                const Icon(Icons.receipt_long_outlined,
                    size: 18, color: kTextSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.orderNumber,
                        style: const TextStyle(
                            color: kTextPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14),
                      ),
                      Text(
                        timeFmt.format(order.createdAt.toLocal()),
                        style: const TextStyle(
                            color: kTextSecondary, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: statusColor.withAlpha(60), width: 0.5),
                  ),
                  child: Text(
                    order.statusLabel,
                    style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          // Items
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
            child: Column(
              children: [
                ...order.items.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Text(
                            '${item.quantity}×',
                            style: const TextStyle(
                                color: kPrimaryBlue,
                                fontSize: 12,
                                fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              item.menuItem?.name ?? item.menuItemId,
                              style: const TextStyle(
                                  color: kTextPrimary, fontSize: 12),
                            ),
                          ),
                          Text(
                            'Rp ${moneyFmt.format(item.subtotal.toInt())}',
                            style: const TextStyle(
                                color: kTextSecondary, fontSize: 12),
                          ),
                        ],
                      ),
                    )),
                const Divider(color: kDividerColor, height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (order.customer != null)
                          Text(
                            order.customer!.name,
                            style: const TextStyle(
                                color: kTextSecondary, fontSize: 11),
                          ),
                        if (order.notes != null &&
                            order.notes!.isNotEmpty)
                          Text(
                            'Catatan: ${order.notes}',
                            style: const TextStyle(
                                color: kTextSecondary,
                                fontSize: 11,
                                fontStyle: FontStyle.italic),
                          ),
                      ],
                    ),
                    Text(
                      'Rp ${moneyFmt.format(order.totalAmount.toInt())}',
                      style: const TextStyle(
                          color: kSuccessColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 15),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Actions
          if (onAdvance != null || onCancel != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (onCancel != null)
                    OutlinedButton(
                      onPressed: onCancel,
                      style: OutlinedButton.styleFrom(
                          foregroundColor: kErrorColor,
                          side: BorderSide(
                              color: kErrorColor.withAlpha(120)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          minimumSize: Size.zero),
                      child: const Text('Batalkan',
                          style: TextStyle(fontSize: 12)),
                    ),
                  if (onAdvance != null && onCancel != null)
                    const SizedBox(width: 8),
                  if (onAdvance != null)
                    ElevatedButton(
                      onPressed: onAdvance,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: statusColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          minimumSize: Size.zero),
                      child: Text(nextStatusLabel,
                          style: const TextStyle(fontSize: 12)),
                    ),
                ],
              ),
            )
          else
            const SizedBox(height: 10),
        ],
      ),
    );
  }
}
