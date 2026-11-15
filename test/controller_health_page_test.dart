import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:kiosk_ps/providers/controller_health_provider.dart';
import 'package:kiosk_ps/screens/controller_health/controller_health_page.dart';

void main() {
  testWidgets('Controller Health Check tampil tanpa error', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => ControllerHealthProvider(),
        child: const MaterialApp(home: ControllerHealthPage()),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Cek Kesehatan Controller'), findsWidgets);
    expect(find.text('SIMULASI'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Lepas halaman → provider.stop() membatalkan timer simulasi.
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });

  _regressionTabSwitch();
}
/// Regresi: berpindah tab (isActive true -> false) memanggil stop() saat
/// fase build. Sebelumnya stop() memanggil notifyListeners() sehingga muncul
/// "setState() called during build" dari ControllerHealthProvider.
void _regressionTabSwitch() {
  testWidgets('pindah tab controller tidak memicu setState saat build',
      (tester) async {
    final provider = ControllerHealthProvider();

    Widget build(bool active) => ChangeNotifierProvider.value(
          value: provider,
          child: MaterialApp(
            home: ControllerHealthPage(isActive: active),
          ),
        );

    await tester.pumpWidget(build(true));
    await tester.pump(const Duration(milliseconds: 150));

    await tester.pumpWidget(build(false));
    await tester.pump();
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
}
