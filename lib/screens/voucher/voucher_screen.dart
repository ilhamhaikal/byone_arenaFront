import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/voucher_model.dart';
import '../../providers/voucher_provider.dart';
import 'voucher_form_dialog.dart';

class VoucherScreen extends StatefulWidget {
  const VoucherScreen({super.key});
  @override
  State<VoucherScreen> createState() => _VoucherScreenState();
}

class _VoucherScreenState extends State<VoucherScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VoucherProvider>().loadVouchers();
    });
  }

  void _openForm([VoucherModel? voucher]) {
    showDialog(context: context, builder: (_) => VoucherFormDialog(voucher: voucher));
  }

  Future<void> _confirmDelete(VoucherModel voucher) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Voucher'),
        content: Text('Hapus voucher "${voucher.code}"?'),
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
      await context.read<VoucherProvider>().deleteVoucher(voucher.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Voucher berhasil dihapus')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDeepBlack,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0F),
        title: const Text('Manajemen Voucher'),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: kGradientPurple,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [BoxShadow(color: kAccentPurple.withAlpha(80), blurRadius: 8)],
              ),
              child: const Icon(Icons.add_rounded, size: 16, color: Colors.white),
            ),
            onPressed: _openForm,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Consumer<VoucherProvider>(
        builder: (context, p, _) {
          if (p.isLoading) {
            return const Center(child: CircularProgressIndicator(color: kPrimaryBlue));
          }
          if (p.vouchers.isEmpty) {
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
                    child: const Icon(Icons.confirmation_number_outlined, size: 36, color: kTextSecondary),
                  ),
                  const SizedBox(height: 16),
                  const Text('Belum ada voucher',
                      style: TextStyle(color: kTextPrimary, fontSize: 15, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _openForm,
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: const Text('Tambah Voucher'),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            color: kPrimaryBlue,
            backgroundColor: kSurface,
            onRefresh: p.loadVouchers,
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              itemCount: p.vouchers.length,
              itemBuilder: (ctx, i) => _VoucherCard(
                voucher: p.vouchers[i],
                onEdit: () => _openForm(p.vouchers[i]),
                onDelete: () => _confirmDelete(p.vouchers[i]),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _VoucherCard extends StatelessWidget {
  final VoucherModel voucher;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _VoucherCard({required this.voucher, required this.onEdit, required this.onDelete});

  bool get _available => voucher.isAvailable;
  Color get _statusColor => _available ? kSuccessColor : kErrorColor;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd MMM yyyy');
    final usageRatio =
        voucher.maxUsage > 0 ? (voucher.usageCount / voucher.maxUsage).clamp(0.0, 1.0) : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: _available ? kAccentPurple.withAlpha(60) : kBorderColor, width: 0.5),
        boxShadow: _available
            ? [BoxShadow(color: kAccentPurple.withAlpha(15), blurRadius: 16)]
            : null,
      ),
      child: Column(
        children: [
          // ── Ticket header ──
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  kAccentPurple.withAlpha(_available ? 25 : 10),
                  Colors.transparent,
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                // Code badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    gradient: _available ? kGradientPurple : null,
                    color: _available ? null : kDeepBlack,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: _available ? Colors.transparent : kBorderColor),
                  ),
                  child: Text(
                    voucher.code,
                    style: TextStyle(
                      color: _available ? Colors.white : kTextSecondary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      letterSpacing: 1.5,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(voucher.name,
                          style: const TextStyle(
                              color: kTextPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
                      const SizedBox(height: 2),
                      Text('Diskon ${voucher.displayValue}',
                          style: TextStyle(color: _available ? kAccentPurple : kTextSecondary, fontSize: 12)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _statusColor.withAlpha(60), width: 0.5),
                  ),
                  child: Text(
                    _available ? 'Aktif' : 'Nonaktif',
                    style: TextStyle(
                        color: _statusColor, fontSize: 10, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          // ── Dashed divider ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: List.generate(
                30,
                (i) => Expanded(
                  child: Container(
                    height: 1,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    color: i.isEven ? kBorderColor : Colors.transparent,
                  ),
                ),
              ),
            ),
          ),
          // ── Usage + info ──
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                // Usage bar
                Row(
                  children: [
                    const Icon(Icons.people_outline_rounded, size: 12, color: kTextSecondary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: usageRatio,
                          minHeight: 6,
                          backgroundColor: kDeepBlack,
                          valueColor: AlwaysStoppedAnimation(
                              usageRatio > 0.8 ? kErrorColor : kAccentPurple),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${voucher.usageCount}/${voucher.maxUsage}',
                      style: const TextStyle(color: kTextSecondary, fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.event_rounded, size: 12, color: kTextSecondary),
                    const SizedBox(width: 4),
                    Text('Exp: ${voucher.expiresAt != null ? fmt.format(voucher.expiresAt!) : '-'}',
                        style: const TextStyle(color: kTextSecondary, fontSize: 11)),
                    if (voucher.minPurchase != null && voucher.minPurchase! > 0) ...[
                      const SizedBox(width: 12),
                      const Icon(Icons.account_balance_wallet_outlined,
                          size: 12, color: kTextSecondary),
                      const SizedBox(width: 4),
                      Text(
                          'Min. Rp ${NumberFormat('#,###', 'id').format(voucher.minPurchase!.toInt())}',
                          style: const TextStyle(color: kTextSecondary, fontSize: 11)),
                    ],
                    const Spacer(),
                    // Edit / Delete
                    InkWell(
                      onTap: onEdit,
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(Icons.edit_outlined, size: 16, color: kPrimaryBlue),
                      ),
                    ),
                    const SizedBox(width: 10),
                    InkWell(
                      onTap: onDelete,
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(Icons.delete_outline_rounded,
                            size: 16, color: kErrorColor.withAlpha(180)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


