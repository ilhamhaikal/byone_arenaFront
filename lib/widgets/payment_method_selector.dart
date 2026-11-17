import 'package:flutter/material.dart';

import '../config/app_theme.dart';

/// Pilihan metode pembayaran: Tunai atau QRIS.
///
/// Hanya metodenya yang dipilih; tidak ada tampilan QR (QRIS dibayar di
/// perangkat/EDC terpisah).
class PaymentMethodSelector extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  final bool enabled;

  const PaymentMethodSelector({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  static const String cash = 'cash';
  static const String qris = 'qris';

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _option(
            id: cash,
            label: 'Tunai',
            icon: Icons.payments_rounded,
            color: kSuccessColor,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _option(
            id: qris,
            label: 'QRIS',
            icon: Icons.qr_code_2_rounded,
            color: kAccentPurple,
          ),
        ),
      ],
    );
  }

  Widget _option({
    required String id,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    final selected = value == id;
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: InkWell(
        onTap: enabled ? () => onChanged(id) : null,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? color.withAlpha(28) : kCardColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? color : kBorderColor,
              width: selected ? 1.4 : 1,
            ),
            boxShadow: selected
                ? [BoxShadow(color: color.withAlpha(45), blurRadius: 12)]
                : null,
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: selected ? color : kTextSecondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected ? kTextPrimary : kTextSecondary,
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
              if (selected)
                Icon(Icons.check_circle_rounded, size: 16, color: color),
            ],
          ),
        ),
      ),
    );
  }
}