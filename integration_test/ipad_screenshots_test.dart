import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mleysoft_aidat/main.dart' as app;

Future<void> settle(WidgetTester tester, [Duration wait = const Duration(seconds: 2)]) async {
  await tester.pumpAndSettle(const Duration(milliseconds: 250));
  await Future<void>.delayed(wait);
  await tester.pumpAndSettle(const Duration(milliseconds: 250));
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('App Store iPad screenshots', (tester) async {
    app.main();
    await settle(tester, const Duration(seconds: 3));
    await binding.takeScreenshot('01-login-ipad');

    // Demo daire hesabı. Backend demo hesabında OTP istemeden token döndürüyor.
    final daire = find.text('Daire Girişi');
    if (daire.evaluate().isNotEmpty) {
      await tester.tap(daire.first);
      await settle(tester, const Duration(milliseconds: 700));
    }
    final phone = find.byType(TextField);
    if (phone.evaluate().isNotEmpty) {
      await tester.enterText(phone.first, '05555555555');
      await tester.pump();
    }
    final send = find.text('WhatsApp Kodunu Gönder');
    if (send.evaluate().isNotEmpty) {
      await tester.tap(send.first);
      await settle(tester, const Duration(seconds: 8));
      await binding.takeScreenshot('02-resident-dashboard-ipad');
    }
  });
}
