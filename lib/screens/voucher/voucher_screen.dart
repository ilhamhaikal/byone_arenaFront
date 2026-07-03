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
            child: LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth >= 1200
                    ? 5
                    : constraints.maxWidth >= 900
                        ? 4
                        : constraints.maxWidth >= 600
                            ? 3
                            : 2;

                final vouchers = p.vouchers;
                final rows = <List<VoucherModel>>[];
                for (var i = 0; i < vouchers.length; i += crossAxisCount) {
                  final end = (i + crossAxisCount > vouchers.length)
                      ? vouchers.length
                      : i + crossAxisCount;
                  rows.add(vouchers.sublist(i, end));
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: rows.map((row) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (final v in row)
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  child: _VoucherCard(
                                    voucher: v,
                                    onEdit: () => _openForm(v),
                                    onDelete: () => _confirmDelete(v),
                                  ),
                                ),
                              ),
                            for (int i = row.length; i < crossAxisCount; i++)
                              const Expanded(child: SizedBox.shrink()),
                          ],
                        ),
                      );
                    }).toList(),
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
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: _available ? kAccentPurple.withAlpha(60) : kBorderColor, width: 0.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header: code badge + status
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 4),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    gradient: _available ? kGradientPurple : null,
                    color: _available ? null : kDeepBlack,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: _available ? Colors.transparent : kBorderColor),
                  ),
                  child: Text(
                    voucher.code,
                    style: TextStyle(
                      color: _available ? Colors.white : kTextSecondary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _statusColor.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _statusColor.withAlpha(60), width: 0.5),
                  ),
                  child: Text(
                    _available ? 'Aktif' : 'Nonaktif',
                    style: TextStyle(color: _statusColor, fontSize: 9, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          // Name + discount
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 2),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(voucher.name,
                  style: const TextStyle(color: kTextPrimary, fontWeight: FontWeight.w600, fontSize: 12),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 6),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Diskon ${voucher.displayValue}',
                  style: TextStyle(color: _available ? kAccentPurple : kTextSecondary, fontSize: 11)),
            ),
          ),
          // Divider
          Container(height: 1, color: kBorderColor),
          // Usage bar + expiry
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 6, 10, 4),
            child: Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: usageRatio,
                      minHeight: 4,
                      backgroundColor: kDeepBlack,
                      valueColor: AlwaysStoppedAnimation(
                          usageRatio > 0.8 ? kErrorColor : kAccentPurple),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text('${voucher.usageCount}/${voucher.maxUsage}',
                    style: const TextStyle(color: kTextSecondary, fontSize: 10)),
              ],
            ),
          ),
          if (voucher.expiresAt != null || (voucher.minPurchase != null && voucher.minPurchase! > 0))
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 4),
              child: Wrap(
                spacing: 6,
                runSpacing: 2,
                children: [
                  if (voucher.expiresAt != null)
                    Text('Exp: ${fmt.format(voucher.expiresAt!)}',
                        style: const TextStyle(color: kTextSecondary, fontSize: 9)),
                  if (voucher.minPurchase != null && voucher.minPurchase! > 0)
                    Text('Min. Rp ${NumberFormat("#,###", "id").format(voucher.minPurchase!.toInt())}',
                        style: const TextStyle(color: kTextSecondary, fontSize: 9)),
                ],
              ),
            ),
          // Actions
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 0, 6, 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                InkWell(
                  onTap: onEdit,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: kDeepBlack,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: kBorderColor),
                    ),
                    child: const Icon(Icons.edit_outlined, size: 14, color: kPrimaryBlue),
                  ),
                ),
                const SizedBox(width: 4),
                InkWell(
                  onTap: onDelete,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: kDeepBlack,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: kBorderColor),
                    ),
                    child: const Icon(Icons.delete_outline, size: 14, color: kErrorColor),
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



