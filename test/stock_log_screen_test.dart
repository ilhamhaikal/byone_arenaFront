import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'package:kiosk_ps/providers/capital_provider.dart';
import 'package:kiosk_ps/screens/stock/stock_log_screen.dart';

/// Regresi untuk crash:
/// "setState() or markNeedsBuild() called during build" dari CapitalProvider
/// saat StockLogScreen memanggil provider di initState.
void main() {
  setUpAll(() async {
    await initializeDateFormatting('id', null);
  });

  testWidgets('StockLogScreen aman dimuat tanpa notify saat build',
      (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => CapitalProvider(),
        child: const MaterialApp(home: StockLogScreen()),
      ),
    );

    // Frame pertama selesai; post-frame callback mengisi data.
    await tester.pump();
    expect(tester.takeException(), isNull,
        reason: 'tidak boleh ada exception saat build pertama');

    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull,
        reason: 'tidak boleh ada exception setelah data dimuat');
  });
}