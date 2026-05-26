import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:safetour/main.dart';

void main() {
  testWidgets('SafeTourApp renders', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: SafeTourApp()));
    await tester.pumpAndSettle();
    expect(find.text('SafeTour'), findsOneWidget);
  });
}
