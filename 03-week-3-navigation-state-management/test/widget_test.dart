
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:week3_todo/main.dart';
import 'package:week3_todo/providers/product_provider.dart';

void main() {
  testWidgets('debug timer', (tester) async {
    ProductsNotifier.simulateError = true;
    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2, milliseconds: 500));
    await tester.pump();
    print('Found text: ' + find.byType(Text).evaluate().map((e) => (e.widget as Text).data ?? '').toList().toString());
  });
}
