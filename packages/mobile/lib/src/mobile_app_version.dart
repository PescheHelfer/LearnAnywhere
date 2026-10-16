/// Version the About screen shows, kept in step with `pubspec.yaml`.
///
/// Deliberately a constant rather than a `package_info_plus` lookup: reading
/// the installed package's metadata would add a plugin to a shell whose whole
/// dependency list is meant to stay short enough to read, for one string that
/// changes once per release. `mobile_app_version_test.dart` parses
/// `pubspec.yaml` and fails if the two ever drift, which is the part that
/// actually matters.
///
/// Only the semantic version — the `+N` build number is Android's
/// `versionCode`, which the package manager reads and a user never sees.
const String kMobileAppVersion = '0.9.0';

/// Project home, shown on the About screen.
///
/// Shown as plain selectable text and never opened: the app has no URL
/// launcher, on either shell, so nothing here depends on a browser existing.
const String kMobileProjectUrl = 'https://github.com/PescheHelfer/LearnAnywhere';
