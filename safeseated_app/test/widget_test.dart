import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safeseated_app/main.dart';

void main() {
  testWidgets('SafeSeated opens on onboarding', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: SafeSeatedApp()));
    await tester.pumpAndSettle();

    expect(find.text('Women-only rides'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
  });
}
