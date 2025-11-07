/// Material Icons code points for use in PluginUIDescriptor.
///
/// This class provides named constants for Material Icons without requiring
/// Flutter dependency. Use these instead of magic numbers for better readability.
///
/// ## Usage:
/// ```dart
/// PluginUIDescriptor(
///   iconCode: MaterialIconCodes.copyAll,  // Instead of 0xe197
///   iconFamily: 'MaterialIcons',
///   ...
/// )
/// ```
///
/// ## Icon Preview:
/// You can preview these icons at: https://fonts.google.com/icons?icon.set=Material+Icons
abstract final class MaterialIconCodes {
  // ============================================================================
  // Files and Folders
  // ============================================================================

  /// 📄 Single file icon
  static const int insertDriveFile = 0xe24d;

  /// 📁 Closed folder icon
  static const int folder = 0xe2c7;

  /// 📂 Open folder icon
  static const int folderOpen = 0xe2c8;

  /// 📋 Multiple files/documents icon (stack of papers)
  static const int copyAll = 0xe197;

  // ============================================================================
  // Actions
  // ============================================================================

  /// 💾 Save icon
  static const int save = 0xe161;

  /// 🗑️ Delete/trash icon
  static const int delete = 0xe872;

  /// ✏️ Edit/pencil icon
  static const int edit = 0xe3c9;

  /// 🔄 Refresh/reload icon
  static const int refresh = 0xe5d5;

  /// ➕ Add/create new icon
  static const int add = 0xe145;

  /// 🔍 Search icon
  static const int search = 0xe8b6;

  // ============================================================================
  // Charts and Statistics
  // ============================================================================

  /// 📊 Bar chart with three vertical bars of different heights
  static const int barChart = 0xe0cc;

  /// 📈 Line/area chart icon
  static const int insertChart = 0xe873;

  /// 📊 Analytics icon
  static const int analytics = 0xe76c;

  // ============================================================================
  // Common UI Icons
  // ============================================================================

  /// ⚙️ Settings/gear icon
  static const int settings = 0xe8b8;

  /// 💻 Code/programming icon
  static const int code = 0xe86f;

  /// ❌ Error icon
  static const int error = 0xe000;

  /// ⚠️ Warning icon
  static const int warning = 0xe002;

  /// ℹ️ Info icon
  static const int info = 0xe88e;

  /// ✓ Check/success icon
  static const int check = 0xe5ca;

  /// ✕ Close/cancel icon
  static const int close = 0xe5cd;

  // ============================================================================
  // Navigation
  // ============================================================================

  /// ← Back arrow
  static const int arrowBack = 0xe5c4;

  /// → Forward arrow
  static const int arrowForward = 0xe5c8;

  /// ↓ Expand more icon
  static const int expandMore = 0xe5cf;

  /// ↑ Expand less icon
  static const int expandLess = 0xe5ce;
}
