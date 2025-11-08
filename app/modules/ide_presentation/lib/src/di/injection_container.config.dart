// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:editor_core/editor_core.dart' as _i218;
import 'package:get_it/get_it.dart' as _i174;
import 'package:ide_presentation/src/stores/editor/editor_store.dart' as _i571;
import 'package:ide_presentation/src/stores/lsp/lsp_store.dart' as _i1016;
import 'package:injectable/injectable.dart' as _i526;
import 'package:lsp_application/lsp_application.dart' as _i220;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    gh.factory<_i571.EditorStore>(
      () => _i571.EditorStore(
        editorRepository: gh<_i218.ICodeEditorRepository>(),
      ),
    );
    gh.factory<_i1016.LspStore>(
      () => _i1016.LspStore(
        initializeSessionUseCase: gh<_i220.InitializeLspSessionUseCase>(),
        shutdownSessionUseCase: gh<_i220.ShutdownLspSessionUseCase>(),
        getCompletionsUseCase: gh<_i220.GetCompletionsUseCase>(),
        getHoverInfoUseCase: gh<_i220.GetHoverInfoUseCase>(),
        getDiagnosticsUseCase: gh<_i220.GetDiagnosticsUseCase>(),
        goToDefinitionUseCase: gh<_i220.GoToDefinitionUseCase>(),
        findReferencesUseCase: gh<_i220.FindReferencesUseCase>(),
      ),
    );
    return this;
  }
}
