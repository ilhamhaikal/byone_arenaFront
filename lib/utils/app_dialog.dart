import 'package:flutter/material.dart';
import '../config/app_theme.dart';

/// Global navigator key agar dialog notifikasi bisa tampil dari mana saja,
/// termasuk setelah sebuah form/dialog di-pop.
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

/// Menampilkan dialog notifikasi sukses (hijau).
Future<void> showSuccessDialog(String message, {String title = 'Berhasil'}) {
  return _showAppDialog(
    icon: Icons.check_circle_rounded,
    color: kSuccessColor,
    title: title,
    message: message,
  );
}

/// Menampilkan dialog notifikasi gagal (merah).
Future<void> showErrorDialog(String message, {String title = 'Gagal'}) {
  return _showAppDialog(
    icon: Icons.cancel_rounded,
    color: kErrorColor,
    title: title,
    message: message,
  );
}

/// Menampilkan dialog notifikasi peringatan (kuning).
Future<void> showWarningDialog(String message, {String title = 'Perhatian'}) {
  return _showAppDialog(
    icon: Icons.warning_rounded,
    color: kWarningColor,
    title: title,
    message: message,
  );
}

Future<void> _showAppDialog({
  required IconData icon,
  required Color color,
  required String title,
  required String message,
}) async {
  final ctx = appNavigatorKey.currentContext;
  if (ctx == null) return;

  await showDialog<void>(
    context: ctx,
    barrierDismissible: true,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: kSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: kBorderColor),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withAlpha(30),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
          ),
        ],
      ),
      content: Text(
        message,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14,
          color: kTextPrimary,
          height: 1.4,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}