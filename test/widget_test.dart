import 'package:flutter_test/flutter_test.dart';
import 'package:attendance_app/app.dart';

void main() {
  testWidgets('App launches', (WidgetTester tester) async {
    await tester.pumpWidget(const AttendanceApp());
    expect(find.text('AttendAce'), findsOneWidget);
  });
}
