import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:learn_anywhere_mobile/src/mobile_app_version.dart';

/// Guards the one place the About screen's version could silently go stale.
///
/// [kMobileAppVersion] is a hand-written constant, so nothing but this test
/// stops a release from bumping `pubspec.yaml` and leaving About showing the
/// previous number. Read package-root-relative, like the other suites read
/// their fixtures, so it works under `melos` and a bare `flutter test` alike.
void main() {
  test('the About version matches pubspec.yaml', () {
    final String pubspec = File('pubspec.yaml').readAsStringSync();
    final RegExpMatch? match = RegExp(
      r'^version:\s*(\S+)\s*$',
      multiLine: true,
    ).firstMatch(pubspec);

    expect(match, isNotNull, reason: 'pubspec.yaml must declare a version');

    // pubspec carries `X.Y.Z+B`; About shows the semantic part only, because
    // the build number after the `+` is Android's versionCode and means
    // nothing to a reader.
    final String semanticVersion = match!.group(1)!.split('+').first;

    expect(
      kMobileAppVersion,
      semanticVersion,
      reason: 'kMobileAppVersion in lib/src/mobile_app_version.dart is what '
          'the About screen shows; bump it together with pubspec.yaml.',
    );
  });
}
