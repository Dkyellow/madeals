import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:madeals/main.dart';

void main() {
  testWidgets('MADEALS Open Marketplace Home Feed loads directly without auth', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaDealsApp(),
      ),
    );
    await tester.pump();

    // Verify brand logo and persistent bottom nav tabs are loaded without any auth screen
    expect(find.text('DEALS'), findsAtLeastNWidgets(1));
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Search'), findsOneWidget);
    expect(find.text('Sell'), findsOneWidget);
    expect(find.text('Messages'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });
}
