import 'package:flutter/material.dart';
import 'package:learn_anywhere_core/core.dart';

/// The accent colours that tell question, answer and remark fields apart, and
/// the tint drawn behind a field's value.
///
/// One definition for every screen that shows field rows, so the learn session
/// and the unit editor can't drift apart, and so a contrast check measures the
/// backgrounds a formatted value really sits on.
final class LearnAnywhereFieldAccents {
  const LearnAnywhereFieldAccents._();

  /// Accent of a question field.
  static const Color question = Color.fromRGBO(0, 150, 180, 1);

  /// Accent of an answer field.
  static const Color answer = Color.fromRGBO(0, 160, 80, 1);

  /// Accent of a remark field.
  static const Color remark = Color.fromRGBO(200, 140, 0, 1);

  /// The accent for a field playing [role].
  static Color accentFor(FieldRole role) {
    return switch (role) {
      FieldRole.question => question,
      FieldRole.answer => answer,
      FieldRole.remark => remark,
    };
  }

  /// The translucent tint behind a [role] field's value: the accent at 15 %
  /// on a light theme and 10 % on a dark one, over whatever surface the row
  /// is painted on.
  static Color backgroundFor(FieldRole role, Brightness brightness) {
    return accentFor(
      role,
    ).withValues(alpha: brightness == Brightness.light ? 0.15 : 0.10);
  }
}
