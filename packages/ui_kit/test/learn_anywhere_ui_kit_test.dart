import 'package:flutter_test/flutter_test.dart';
import 'package:learn_anywhere_ui_kit/learn_anywhere_ui_kit.dart';

void main() {
  test('shared themes are available', () {
    expect(LearnAnywhereTheme.light().brightness, isNotNull);
    expect(LearnAnywhereTheme.dark().brightness, isNotNull);
  });
}
