import 'package:flutter/material.dart';

/// [MenuAcceleratorLabel] builder that highlights the access letter with the
/// theme's primary colour instead of an underline, ensuring visibility across
/// light and dark themes alike.
Widget menuAcceleratorBuilder(BuildContext context, String label, int index) {
  if (index == -1) {
    return Text(label);
  }
  final Characters chars = label.characters;
  final String before = chars.take(index).string;
  final String access = chars.elementAt(index);
  final String after = chars.skip(index + 1).string;
  return RichText(
    text: TextSpan(
      style: DefaultTextStyle.of(context).style,
      children: <InlineSpan>[
        TextSpan(text: before),
        TextSpan(
          text: access,
          style: TextStyle(color: Theme.of(context).colorScheme.primary),
        ),
        TextSpan(text: after),
      ],
    ),
  );
}
