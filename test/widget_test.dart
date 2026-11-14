import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kiosk_ps/config/app_theme.dart';

void main() {
  testWidgets('Tema aplikasi dapat dirender', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: appTheme(),
        home: const Scaffold(body: Text('Byone Arena')),
      ),
    );

    expect(find.text('Byone Arena'), findsOneWidget);
  });
}