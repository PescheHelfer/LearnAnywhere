import 'package:flutter/widgets.dart';
import 'package:learn_anywhere_core/core.dart';

import 'mobile_app_theme.dart';

/// Live app-level state — theme, locale, and the persisted
/// [LearnAnywhereSettings] — reachable from any route the app's `Navigator`
/// has pushed, including the `home` route.
///
/// `MaterialApp`/`Navigator` build a route's content once and cache it
/// (`ModalRoute`'s `_page ??= ...`); passing mutable values as plain
/// constructor props to a routed screen freezes them at that screen's first
/// build; further parent-level `setState` calls never reach it again. Reading
/// through this `InheritedWidget` instead (`MobileAppScope.of(context)`)
/// sidesteps that cache entirely — an `InheritedWidget` change marks its
/// dependents dirty and rebuilds them directly, regardless of how deep or how
/// long-lived their enclosing route is.
final class MobileAppScope extends InheritedWidget {
  /// Creates the app scope.
  const MobileAppScope({
    required this.theme,
    required this.locale,
    required this.settings,
    required this.onThemeChanged,
    required this.onLocaleChanged,
    required this.onSettingsChanged,
    required super.child,
    super.key,
  });

  /// Currently active theme.
  final MobileAppTheme theme;

  /// Currently active locale.
  final Locale locale;

  /// Currently active persisted settings: the guardrails from the Settings
  /// screen and the practice-setup choices (mode, direction, shuffle, mastery
  /// threshold) the setup screen remembers between sessions.
  final LearnAnywhereSettings settings;

  /// Called to change the active theme.
  final ValueChanged<MobileAppTheme> onThemeChanged;

  /// Called to change the active locale.
  final ValueChanged<Locale> onLocaleChanged;

  /// Called to change the active settings.
  final ValueChanged<LearnAnywhereSettings> onSettingsChanged;

  /// Returns the nearest [MobileAppScope], registering [context] to rebuild
  /// whenever it changes.
  static MobileAppScope of(BuildContext context) {
    final MobileAppScope? scope = context
        .dependOnInheritedWidgetOfExactType<MobileAppScope>();
    assert(scope != null, 'No MobileAppScope found in context');
    return scope!;
  }

  @override
  bool updateShouldNotify(MobileAppScope oldWidget) {
    return theme != oldWidget.theme ||
        locale != oldWidget.locale ||
        settings != oldWidget.settings;
  }
}
