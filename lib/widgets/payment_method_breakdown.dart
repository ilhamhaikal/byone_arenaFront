import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../config/app_theme.dart';
import '../models/report_summary_model.dart';

/// Label ramah untuk tiap metode pembayaran.
String paymentMethodLabel(String method) {
  switch (method) {
    case 'qris':
      return 'QRIS';
    case 'transfer':
      return 'Transfer';
    case 'cash':
      return 'Tunai';
    default:
      return method.isEmpty ? 'Lainnya' : method;
  }
}

IconData paymentMethodIcon(String method) {
  switch (method) {
    case 'qris':
      return Icons.qr_code_2_rounded;
    case 'transfer':
      return Icons.account_balance_rounded;
    case 'cash':
    default:
      return Icons.payments_rounded;
  }
}

Color paymentMethodColor(String method) {
  switch (method) {
    case 'qris':
      return kAccentPurple;
    case 'transfer':
      return kPrimaryBlue;
    case 'cash':
    default:
      return kSuccessColor;
  }
}

String formatRupiah(num value) =>
    'Rp ${NumberFormat('#,###', 'id').format(value.round())}';

/// Daftar rincian pendapatan per metode pembayaran dengan bar proporsi,
/// supaya orang awam langsung paham "uang masuk lewat apa saja".
class PaymentMethodBreakdown extends StatelessWidget {
  final List<ReportPaymentMethod> methods;

  /// Total pembagi proporsi. Bila 0, dihitung otomatis dari [methods].
  final double total;

  const PaymentMethodBreakdown({
    super.key,
    required this.methods,
    this.total = 0,
  });

  @override
  Widget build(BuildContext context) {
    if (methods.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Text('Belum ada pembayaran pada periode ini.',
            style: TextStyle(color: kTextSecondary, fontSize: 12)),
      );
    }

    // Urutkan dari nominal terbesar agar paling penting di atas.
    final sorted = [...methods]..sort((a, b) => b.total.compareTo(a.total));
    final sum = total > 0
        ? total
        : sorted.fold<double>(0, (s, m) => s + m.total);

    return Column(
      children: [
        for (var i = 0; i < sorted.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          _MethodRow(method: sorted[i], total: sum),
        ],
      ],
    );
  }
}

class _MethodRow extends StatelessWidget {
  final ReportPaymentMethod method;
  final double total;
  const _MethodRow({required this.method, required this.total});

  @override
  Widget build(BuildContext context) {
    final color = paymentMethodColor(method.method);
    final pct = total > 0 ? (method.total / total).clamp(0.0, 1.0) : 0.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: color.withAlpha(25),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(paymentMethodIcon(method.method), size: 18, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      paymentMethodLabel(method.method),
                      style: const TextStyle(
                          color: kTextPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text(
                    formatRupiah(method.total),
                    style: TextStyle(
                        color: color, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: pct,
                  minHeight: 6,
                  backgroundColor: kBorderColor,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${method.trx} transaksi • ${(pct * 100).round()}%',
                style: const TextStyle(color: kTextSecondary, fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Dialog siap pakai untuk menampilkan rincian metode pembayaran
/// (mis. saat kartu "Pendapatan" atau "Makanan" di dashboard diklik).
Future<void> showPaymentMethodBreakdownDialog(
  BuildContext context, {
  required String title,
  String? subtitle,
  required List<ReportPaymentMethod> methods,
  double total = 0,
}) {
  return showDialog(
    context: context,
    builder: (_) => AlertDialog(
      backgroundColor: kSurface,
      title: Text(title, style: const TextStyle(color: kTextPrimary)),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (subtitle != null) ...[
              Text(subtitle,
                  style: const TextStyle(color: kTextSecondary, fontSize: 12)),
              const SizedBox(height: 14),
            ],
            PaymentMethodBreakdown(methods: methods, total: total),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Tutup'),
        ),
      ],
    ),
  );
}
