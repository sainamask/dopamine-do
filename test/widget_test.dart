import 'package:dopamine_do/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Home screen renders headline and trigger buttons',
      (WidgetTester tester) async {
    await tester.pumpWidget(const DopamineDoApp());
    await tester.pump();

    expect(find.text('DOPAMINE-DO'), findsOneWidget);
    expect(find.text('TRIGGER TAKEOVER'), findsOneWidget);
  });
}
