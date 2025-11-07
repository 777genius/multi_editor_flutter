import 'package:multi_editor_plugins/multi_editor_plugins.dart';
import 'package:multi_editor_ui/multi_editor_ui.dart';

/// Application implementation of FileNavigationService
class AppFileNavigationService implements FileNavigationService {
  final EditorController _editorController;

  AppFileNavigationService(this._editorController);

  @override
  Future<void> openFile(String fileId) async {
    await _editorController.loadFile(fileId);
  }

  @override
  bool get isAvailable => true;
}
