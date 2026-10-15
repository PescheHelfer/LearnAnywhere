import 'package:learn_anywhere_core/core.dart';
import 'package:test/test.dart';

void main() {
  group('formatElapsedTime', () {
    test('shows m:ss below an hour', () {
      expect(formatElapsedTime(Duration.zero), '0:00');
      expect(formatElapsedTime(const Duration(minutes: 4, seconds: 59)), '4:59');
      expect(
        formatElapsedTime(const Duration(minutes: 59, seconds: 59)),
        '59:59',
      );
    });

    test('shows h:mm:ss from an hour on', () {
      expect(formatElapsedTime(const Duration(hours: 1)), '1:00:00');
      expect(
        formatElapsedTime(
          const Duration(hours: 12, minutes: 5, seconds: 42),
        ),
        '12:05:42',
      );
    });

    test('drops a part second rather than rounding it up', () {
      expect(
        formatElapsedTime(const Duration(seconds: 59, milliseconds: 999)),
        '0:59',
      );
    });
  });
}
