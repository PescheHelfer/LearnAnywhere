/// How a unit's time becomes learning time (ADR-0006).
library;

import 'dart:math';

/// The most one rated unit adds to any learning time, in seconds: five
/// minutes.
///
/// A constant, not a setting. Beyond it the learner is taken to have been
/// away. It governs learning time only — the unit-time pill still shows the
/// real elapsed time, and the time limit is measured against that.
const int kUnitLearningSecondsCap = 300;

/// The learning time a unit adds when it is rated, from its unit time
/// [unitSeconds]: that time, but never more than [kUnitLearningSecondsCap].
///
/// Sitting, statistics and total time all grow by exactly this, so the three
/// can never disagree about one unit.
int unitLearningSeconds(int unitSeconds) =>
    min(unitSeconds, kUnitLearningSecondsCap);
