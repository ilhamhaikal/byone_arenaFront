import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/discount_model.dart';
import '../../providers/discount_provider.dart';
import 'discount_form_dialog.dart';

class DiscountScreen extends StatefulWidget {
  const DiscountScreen({super.key});
  @override
  State<DiscountScreen> createState() => _DiscountScreenState();
}

class _DiscountScreenState extends State<DiscountScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DiscountProvider>().loadDiscounts();
    });
  }

  void _openForm([DiscountModel? discount]) {
    showDialog(context: context, builder: (_) => DiscountFormDialog(discount: discount));
  }

  Future<void> _confirmDelete(DiscountModel discount) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Diskon'),
        content: Text('Hapus diskon "${discount.name}"?'),
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
      await context.read<DiscountProvider>().deleteDiscount(discount.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Diskon berhasil dihapus')),
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
        title: const Text('Manajemen Diskon'),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: kGradientAmber,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [BoxShadow(color: kWarningColor.withAlpha(80), blurRadius: 8)],
              ),
              child: const Icon(Icons.add_rounded, size: 16, color: Colors.white),
            ),
            onPressed: _openForm,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Consumer<DiscountProvider>(
        builder: (context, p, _) {
          if (p.isLoading) {
            return const Center(child: CircularProgressIndicator(color: kPrimaryBlue));
          }
          if (p.discounts.isEmpty) {
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
                    child: const Icon(Icons.local_offer_outlined, size: 36, color: kTextSecondary),
                  ),
                  const SizedBox(height: 16),
                  const Text('Belum ada diskon',
                      style: TextStyle(color: kTextPrimary, fontSize: 15, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _openForm,
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: const Text('Tambah Diskon'),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            color: kPrimaryBlue,
            backgroundColor: kSurface,
            onRefresh: p.loadDiscounts,
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              itemCount: p.discounts.length,
              itemBuilder: (ctx, i) => _DiscountCard(
                discount: p.discounts[i],
                onEdit: () => _openForm(p.discounts[i]),
                onDelete: () => _confirmDelete(p.discounts[i]),
                onToggle: (v) => p.toggleDiscount(p.discounts[i].id, v),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DiscountCard extends StatelessWidget {
  final DiscountModel discount;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<bool> onToggle;

  const _DiscountCard({
    required this.discount,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
  });

  bool get _expired => discount.isExpired;
  bool get _active => discount.isActive && !_expired;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd MMM yyyy');
    final isPercentage = discount.discountType == 'percentage';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: _active ? kWarningColor.withAlpha(60) : kBorderColor, width: 0.5),
        boxShadow: _active
            ? [BoxShadow(color: kWarningColor.withAlpha(15), blurRadius: 16)]
            : null,
      ),
      child: Column(
        children: [
          // ── Header ──
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  kWarningColor.withAlpha(_active ? 20 : 8),
                  Colors.transparent,
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              border: const Border(bottom: BorderSide(color: kBorderColor, width: 0.5)),
            ),
            child: Row(
              children: [
                // Value badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: _active ? kGradientAmber : null,
                    color: _active ? null : kDeepBlack,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _active ? Colors.transparent : kBorderColor),
                  ),
                  child: Text(
                    discount.displayValue,
                    style: TextStyle(
                        color: _active ? Colors.white : kTextSecondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(discount.name,
                      style: const TextStyle(
                          color: kTextPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                ),
                Switch(value: _active, onChanged: _expired ? null : onToggle),
              ],
            ),
          ),
          // ── Body ──
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (discount.description.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(discount.description,
                        style: const TextStyle(color: kTextSecondary, fontSize: 12)),
                  ),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _InfoChip(
                      icon: Icons.calendar_today_rounded,
                      label:
                          '${fmt.format(discount.startDate)} – ${fmt.format(discount.endDate)}',
                    ),
                    if (discount.minTransaction != null && discount.minTransaction! > 0)
                      _InfoChip(
                        icon: Icons.account_balance_wallet_outlined,
                        label: 'Min. Rp ${NumberFormat('#,###', 'id').format(discount.minTransaction!.toInt())}',
                      ),
                    if (discount.membershipType != null)
                      _TierBadge(type: discount.membershipType!),
                    if (_expired)
                      _InfoChip(
                        icon: Icons.warning_amber_rounded,
                        label: 'Kadaluarsa',
                        color: kErrorColor,
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: onEdit,
                      style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          minimumSize: Size.zero),
                      icon: const Icon(Icons.edit_outlined, size: 14),
                      label: const Text('Edit', style: TextStyle(fontSize: 12)),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: onDelete,
                      style: OutlinedButton.styleFrom(
                          side: BorderSide(color: kErrorColor.withAlpha(150)),
                          foregroundColor: kErrorColor,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          minimumSize: Size.zero),
                      icon: const Icon(Icons.delete_outline_rounded, size: 14),
                      label: const Text('Hapus', style: TextStyle(fontSize: 12)),
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

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _InfoChip({required this.icon, required this.label, this.color = kTextSecondary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withAlpha(40), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontSize: 11)),
        ],
      ),
    );
  }
}

class _TierBadge extends StatelessWidget {
  final String type;
  const _TierBadge({required this.type});

  Color get _color {
    switch (type) {
      case 'platinum': return const Color(0xFF06B6D4);
      case 'gold': return const Color(0xFFEAB308);
      case 'silver': return const Color(0xFF94A3B8);
      default: return kTextSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withAlpha(20),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _color.withAlpha(60), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.card_membership_rounded, size: 11, color: kTextSecondary),
          const SizedBox(width: 4),
          Text(type[0].toUpperCase() + type.substring(1),
              style: TextStyle(color: _color, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}


