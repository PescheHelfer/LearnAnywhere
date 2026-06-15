import 'package:flutter_test/flutter_test.dart';
import 'package:learn_anywhere_desktop/main.dart';

void main() {
  testWidgets('desktop shell launches', (WidgetTester tester) async {
    await tester.pumpWidget(const LearnAnywhereDesktopApp());

    expect(find.text('Learn Anywhere'), findsOneWidget);
    expect(
      find.text('Desktop shell ready: learn_anywhere_core'),
      findsOneWidget,
    );
  });
}
