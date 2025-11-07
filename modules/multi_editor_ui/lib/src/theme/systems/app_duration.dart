/// Duration system - consistent animation and transition timing.
class AppDuration {
  AppDuration._();

  /// Instant (0ms) - no animation
  static const instant = Duration(milliseconds: 0);

  /// Extra fast (100ms) - micro interactions
  static const xfast = Duration(milliseconds: 100);

  /// Fast (150ms) - quick transitions
  static const fast = Duration(milliseconds: 150);

  /// Normal (300ms) - standard animations
  static const normal = Duration(milliseconds: 300);

  /// Slow (500ms) - deliberate animations
  static const slow = Duration(milliseconds: 500);

  /// Extra slow (1000ms) - very deliberate
  static const xslow = Duration(milliseconds: 1000);
}
