// Smoke test — verifies the app entry point builds without crashing.
// Full UI tests require a running Supabase instance and are out of scope here.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:eda/main.dart';

void main() {
  testWidgets('App entry point renders without crashing',
      (WidgetTester tester) async {
    // MyApp is a ConsumerStatefulWidget; it needs a ProviderScope ancestor,
    // just as main.dart provides one before running the app.
    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    // One pump — enough to catch build() exceptions without triggering
    // Supabase network calls that would time out in the test environment.
    await tester.pump();

    expect(find.byType(ProviderScope), findsOneWidget);
  });
}
