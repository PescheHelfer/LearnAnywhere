import 'package:flutter_test/flutter_test.dart';
import 'package:learn_anywhere_mobile/main.dart';

void main() {
  testWidgets('mobile shell launches', (WidgetTester tester) async {
    await tester.pumpWidget(const LearnAnywhereMobileApp());

    expect(find.text('Learn Anywhere'), findsOneWidget);
    expect(
      find.text('Mobile shell ready: learn_anywhere_core'),
      findsOneWidget,
    );
  });
}
