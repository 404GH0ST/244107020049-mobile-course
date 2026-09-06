import 'package:flutter_test/flutter_test.dart';
import 'package:responsive_dashboard/main.dart';

void main() {
  testWidgets('DashboardApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const DashboardApp());
    expect(find.byType(DashboardCard), findsWidgets);
  });
}
