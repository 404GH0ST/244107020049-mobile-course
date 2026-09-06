import 'package:flutter_test/flutter_test.dart';
import 'package:responsive_dashboard/main.dart';

void main() {
  testWidgets('ProfileApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ProfileApp());
    expect(find.byType(ProfileCard), findsOneWidget);
  });
}
