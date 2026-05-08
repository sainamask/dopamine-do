import 'package:dopamine_do/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('Splash screen renders the brand mark',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: DopamineDoApp()));
    await tester.pump();

    expect(find.text('DOPAMINE-DO'), findsOneWidget);

    // Drain the splash's pending Future.delayed so the test exits cleanly.
    await tester.pump(const Duration(milliseconds: 2400));
  });

  testWidgets('After the splash, the Hype Desk shell appears',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: DopamineDoApp()));
    // Splash auto-advances after 2s + a short transition.
    await tester.pump(const Duration(milliseconds: 2400));

    expect(find.text('THE HYPE DESK'), findsOneWidget);
    expect(find.text('QUICK NUDGE'), findsOneWidget);
    expect(find.text('HYPE'), findsOneWidget);
    expect(find.text('ACTION'), findsOneWidget);
    expect(find.text('GLORY'), findsOneWidget);
  });
}
