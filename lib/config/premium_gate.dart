import 'package:flutter/foundation.dart';

class PremiumGate {
  const PremiumGate._();

  static bool get bypassForLocalTesting => kDebugMode;
}
