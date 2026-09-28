/// App Colors
///
/// Text colors of the light screens (home, lists, settings, stats, tests),
/// chosen for a contrast of at least 4.5:1 on white even at small sizes.
library;

import 'package:flutter/painting.dart';

abstract final class AppColors {
  /// Secondary text: subtitles, labels, hints, counts (about 6:1 on white)
  static const secondaryText = Color(0xFF616161);
}
