import 'package:flutter/material.dart';
import 'package:learn_anywhere_core/core.dart';
import 'package:learn_anywhere_ui_kit/learn_anywhere_ui_kit.dart';

import '../mobile_app_version.dart';

/// Minimal About screen: app name, version, licence and the project address.
///
/// Deliberately not desktop's About page. That one carries a scrolling
/// bilingual version history, which belongs to a product with years of
/// releases behind it and a user base that upgrades in place; the companion
/// ships separately, on its own version track, and its history would be a list
/// of two entries nobody needs.
final class MobileAboutScreen extends StatelessWidget {
  /// Creates the About screen.
  const MobileAboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final LearnAnywhereLocalizations messages = LearnAnywhereLocalizations.of(
      context,
    );
    final TextTheme textTheme = Theme.of(context).textTheme;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(messages.message(LearnAnywhereMessage.routeAboutTitle)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(LearnAnywhereTokens.gapLarge),
          children: <Widget>[
            // No app mark here: the artwork is a desktop-package asset, and
            // copying the binary into ui_kit to reach it would put a second
            // copy of the icon in the repo for one decorative header.
            Text(
              messages.message(LearnAnywhereMessage.appTitle),
              style: textTheme.headlineSmall,
            ),
            Text(
              messages
                  .message(LearnAnywhereMessage.mobileAboutVersion)
                  .replaceAll('{version}', kMobileAppVersion),
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: LearnAnywhereTokens.gapLarge),
            Text(
              messages.message(LearnAnywhereMessage.aboutIntro),
              style: textTheme.bodyLarge,
            ),
            const SizedBox(height: LearnAnywhereTokens.gapMedium),
            Text(
              messages.message(LearnAnywhereMessage.mobileAboutLicence),
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: LearnAnywhereTokens.gapLarge),
            Text(
              messages.message(LearnAnywhereMessage.mobileAboutProject),
              style: textTheme.titleSmall,
            ),
            const SizedBox(height: LearnAnywhereTokens.gapSmall),
            // Selectable, not tappable: there is no URL launcher in either
            // shell, so the address is offered for copying rather than
            // promising to open a browser that may not be there.
            SelectableText(
              kMobileProjectUrl,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
