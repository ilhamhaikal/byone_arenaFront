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
    showDialog(
        context: context,
        builder: (_) => DiscountFormDialog(discount: discount));
  }

  Future<void> _confirmDelete(DiscountModel discount) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: kSurface,
        title: const Text('Hapus Aturan Diskon',
            style: TextStyle(color: kTextPrimary)),
        content: Text('Hapus aturan "${discount.name}"?',
            style: const TextStyle(color: kTextSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style:
                ElevatedButton.styleFrom(backgroundColor: kErrorColor),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      final ok2 =
          await context.read<DiscountProvider>().deleteDiscount(discount.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(ok2
                  ? 'Aturan diskon berhasil dihapus'
                  : 'Gagal menghapus aturan diskon')),
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
        title: const Text('Aturan Diskon'),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: kGradientAmber,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                      color: kWarningColor.withAlpha(80), blurRadius: 8)
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
      body: Consumer<DiscountProvider>(
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
                      onPressed: p.loadDiscounts,
                      child: const Text('Coba Lagi')),
                ],
              ),
            );
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
                    child: const Icon(Icons.local_offer_outlined,
                        size: 36, color: kTextSecondary),
                  ),
                  const SizedBox(height: 16),
                  const Text('Belum ada aturan diskon',
                      style: TextStyle(
                          color: kTextPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _openForm,
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: const Text('Tambah Aturan Diskon'),
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
                onToggle: () => p.toggleDiscount(p.discounts[i].id),
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
  final VoidCallback onToggle;

  const _DiscountCard({
    required this.discount,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
  });

  Color get _ruleColor {
    switch (discount.ruleType) {
      case 'happy_hour':
        return kWarningColor;
      case 'member':
        return kPrimaryBlue;
      case 'day_of_week':
        return kAccentPurple;
      default:
        return kSuccessColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final moneyFmt = NumberFormat('#,###', 'id');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: discount.isActive
                ? _ruleColor.withAlpha(60)
                : kBorderColor,
            width: 0.5),
        boxShadow: discount.isActive
            ? [BoxShadow(color: _ruleColor.withAlpha(15), blurRadius: 16)]
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
                  _ruleColor.withAlpha(discount.isActive ? 20 : 8),
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
                // Value badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: discount.isActive
                        ? _ruleColor.withAlpha(30)
                        : kDeepBlack,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: discount.isActive
                            ? _ruleColor.withAlpha(80)
                            : kBorderColor),
                  ),
                  child: Text(
                    discount.displayValue,
                    style: TextStyle(
                        color: discount.isActive
                            ? _ruleColor
                            : kTextSecondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(discount.name,
                          style: const TextStyle(
                              color: kTextPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 14)),
                      const SizedBox(height: 2),
                      _RuleTypeBadge(ruleType: discount.ruleType),
                    ],
                  ),
                ),
                // Priority
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: kDeepBlack,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: kBorderColor),
                  ),
                  child: Text(
                    'P${discount.priority}',
                    style: const TextStyle(
                        color: kTextSecondary, fontSize: 11),
                  ),
                ),
                const SizedBox(width: 6),
                Switch(
                  value: discount.isActive,
                  onChanged: (_) => onToggle(),
                  activeColor: _ruleColor,
                ),
              ],
            ),
          ),
          // ── Body ──
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    if (discount.ruleType == 'happy_hour')
                      _InfoChip(
                        icon: Icons.access_time_rounded,
                        label:
                            '${discount.startHour.toString().padLeft(2, '0')}:00 – ${discount.endHour.toString().padLeft(2, '0')}:00',
                        color: kWarningColor,
                      ),
                    if (discount.ruleType == 'day_of_week' &&
                        discount.daysOfWeek != null)
                      _InfoChip(
                        icon: Icons.calendar_view_week_rounded,
                        label: discount.daysOfWeek!,
                        color: kAccentPurple,
                      ),
                    if (discount.minPurchase > 0)
                      _InfoChip(
                        icon: Icons.account_balance_wallet_outlined,
                        label:
                            'Min. Rp ${moneyFmt.format(discount.minPurchase.toInt())}',
                      ),
                    if (discount.maxDiscount > 0)
                      _InfoChip(
                        icon: Icons.price_check_rounded,
                        label:
                            'Maks. Rp ${moneyFmt.format(discount.maxDiscount.toInt())}',
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
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          minimumSize: Size.zero),
                      icon:
                          const Icon(Icons.edit_outlined, size: 14),
                      label: const Text('Edit',
                          style: TextStyle(fontSize: 12)),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: onDelete,
                      style: OutlinedButton.styleFrom(
                          side: BorderSide(
                              color: kErrorColor.withAlpha(150)),
                          foregroundColor: kErrorColor,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          minimumSize: Size.zero),
                      icon: const Icon(
                          Icons.delete_outline_rounded,
                          size: 14),
                      label: const Text('Hapus',
                          style: TextStyle(fontSize: 12)),
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

class _RuleTypeBadge extends StatelessWidget {
  final String ruleType;
  const _RuleTypeBadge({required this.ruleType});

  Color get _color {
    switch (ruleType) {
      case 'happy_hour':
        return kWarningColor;
      case 'member':
        return kPrimaryBlue;
      case 'day_of_week':
        return kAccentPurple;
      default:
        return kSuccessColor;
    }
  }

  String get _label {
    switch (ruleType) {
      case 'happy_hour':
        return 'Happy Hour';
      case 'member':
        return 'Member';
      case 'day_of_week':
        return 'Hari Tertentu';
      default:
        return 'Selalu Aktif';
    }
  }

  IconData get _icon {
    switch (ruleType) {
      case 'happy_hour':
        return Icons.access_time_rounded;
      case 'member':
        return Icons.card_membership_rounded;
      case 'day_of_week':
        return Icons.calendar_view_week_rounded;
      default:
        return Icons.all_inclusive_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(_icon, size: 11, color: _color),
        const SizedBox(width: 4),
        Text(_label,
            style: TextStyle(
                color: _color,
                fontSize: 11,
                fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _InfoChip(
      {required this.icon,
      required this.label,
      this.color = kTextSecondary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(6),
        border:
            Border.all(color: color.withAlpha(40), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(color: color, fontSize: 11)),
        ],
      ),
    );
  }
}
