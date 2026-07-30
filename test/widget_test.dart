import 'package:flutter_test/flutter_test.dart';
import 'package:jawda_care/app.dart';

void main() {
  testWidgets('App loads successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const JawdaCareApp());
    expect(find.byType(JawdaCareApp), findsOneWidget);
  });
}
