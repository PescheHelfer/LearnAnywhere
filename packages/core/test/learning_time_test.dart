import 'package:learn_anywhere_core/core.dart';
import 'package:test/test.dart';

void main() {
  group('unitLearningSeconds', () {
    test('the cap is five minutes', () {
      expect(kUnitLearningSecondsCap, 300);
    });

    test('passes a unit time below the cap through unchanged', () {
      expect(unitLearningSeconds(0), 0);
      expect(unitLearningSeconds(42), 42);
      expect(unitLearningSeconds(299), 299);
    });

    test('counts a unit time at or beyond the cap as the cap', () {
      expect(unitLearningSeconds(300), 300);
      expect(unitLearningSeconds(360), 300);
      expect(unitLearningSeconds(3 * 60 * 60), 300);
    });
  });
}
