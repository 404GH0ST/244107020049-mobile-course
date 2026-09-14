import 'package:flutter_test/flutter_test.dart';
import 'package:week3_todo/main.dart';

void main() {
  testWidgets('Praktikum 1: Navigasi GoRouter dari Home ke Detail',
      (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Item 1'), findsOneWidget);

    // Tap on Item 1 to navigate to detail
    await tester.tap(find.text('Item 1'));
    await tester.pumpAndSettle();

    expect(find.text('Detail 1'), findsOneWidget);
    expect(find.text('Anda membuka item dengan id: 1'), findsOneWidget);
  });
}
