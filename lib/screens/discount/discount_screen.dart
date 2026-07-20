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
      backgroundColor: Colors.transparent,
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
            child: LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth >= 1200
                    ? 5
                    : constraints.maxWidth >= 900
                        ? 4
                        : constraints.maxWidth >= 600
                            ? 3
                            : 2;

                final discounts = p.discounts;
                final rows = <List<DiscountModel>>[];
                for (var i = 0; i < discounts.length; i += crossAxisCount) {
                  final end = (i + crossAxisCount > discounts.length)
                      ? discounts.length
                      : i + crossAxisCount;
                  rows.add(discounts.sublist(i, end));
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
                            for (final d in row)
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  child: _DiscountCard(
                                    discount: d,
                                    onEdit: () => _openForm(d),
                                    onDelete: () => _confirmDelete(d),
                                    onToggle: () => p.toggleDiscount(d.id),
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
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: discount.isActive ? _ruleColor.withAlpha(60) : kBorderColor,
            width: 0.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header: value badge + status
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 4),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: discount.isActive ? _ruleColor.withAlpha(30) : kDeepBlack,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: discount.isActive ? _ruleColor.withAlpha(80) : kBorderColor),
                  ),
                  child: Text(
                    discount.displayValue,
                    style: TextStyle(
                        color: discount.isActive ? _ruleColor : kTextSecondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: (discount.isActive ? kSuccessColor : kErrorColor).withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: (discount.isActive ? kSuccessColor : kErrorColor).withAlpha(60),
                        width: 0.5),
                  ),
                  child: Text(
                    discount.isActive ? 'Aktif' : 'Nonaktif',
                    style: TextStyle(
                        color: discount.isActive ? kSuccessColor : kErrorColor,
                        fontSize: 9,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          // Name
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 2),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(discount.name,
                  style: const TextStyle(color: kTextPrimary, fontWeight: FontWeight.w600, fontSize: 12),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
            ),
          ),
          // Type + Priority
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 6),
            child: Row(
              children: [
                _RuleTypeBadgeCompact(ruleType: discount.ruleType),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: kDeepBlack,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: kBorderColor),
                  ),
                  child: Text('P${discount.priority}',
                      style: const TextStyle(color: kTextSecondary, fontSize: 9)),
                ),
              ],
            ),
          ),
          // Divider
          Container(height: 1, color: kBorderColor),
          // Info chips (compact)
          if (discount.ruleType == 'happy_hour' ||
              (discount.ruleType == 'day_of_week' && discount.daysOfWeek != null) ||
              discount.minPurchase > 0 ||
              discount.maxDiscount > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 0),
              child: Wrap(
                spacing: 4,
                runSpacing: 4,
                children: [
                  if (discount.ruleType == 'happy_hour')
                    _InfoChipCompact(
                      label: '${discount.startHour.toString().padLeft(2, '0')}:00–${discount.endHour.toString().padLeft(2, '0')}:00',
                      color: kWarningColor,
                    ),
                  if (discount.ruleType == 'day_of_week' && discount.daysOfWeek != null)
                    _InfoChipCompact(label: discount.daysOfWeek!, color: kAccentPurple),
                  if (discount.minPurchase > 0)
                    _InfoChipCompact(
                        label: 'Min Rp ${moneyFmt.format(discount.minPurchase.toInt())}'),
                  if (discount.maxDiscount > 0)
                    _InfoChipCompact(
                        label: 'Maks Rp ${moneyFmt.format(discount.maxDiscount.toInt())}'),
                ],
              ),
            ),
          const SizedBox(height: 6),
          // Actions
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 0, 6, 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                InkWell(
                  onTap: onToggle,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: kDeepBlack,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: kBorderColor),
                    ),
                    child: Icon(
                      discount.isActive ? Icons.toggle_on : Icons.toggle_off,
                      size: 16,
                      color: discount.isActive ? _ruleColor : kTextSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
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

class _RuleTypeBadgeCompact extends StatelessWidget {
  final String ruleType;
  const _RuleTypeBadgeCompact({required this.ruleType});

  @override
  Widget build(BuildContext context) {
    final (icon, label, color) = switch (ruleType) {
      'happy_hour' => (Icons.access_time_rounded, 'Happy Hour', kWarningColor),
      'member' => (Icons.people_rounded, 'Member', kPrimaryBlue),
      'day_of_week' => (Icons.calendar_view_week_rounded, 'Hari', kAccentPurple),
      _ => (Icons.discount_rounded, ruleType, kSuccessColor),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 9, color: color),
          const SizedBox(width: 3),
          Text(label, style: TextStyle(color: color, fontSize: 9)),
        ],
      ),
    );
  }
}

class _InfoChipCompact extends StatelessWidget {
  final String label;
  final Color color;
  const _InfoChipCompact({required this.label, this.color = kTextSecondary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: kDeepBlack,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: kBorderColor),
      ),
      child: Text(label,
          style: TextStyle(color: color, fontSize: 9)),
    );
  }
}
