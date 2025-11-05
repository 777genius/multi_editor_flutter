enum PluginState {
  uninitialized,
  initializing,
  ready,
  error,
  disposed;

  bool get isUninitialized => this == PluginState.uninitialized;
  bool get isInitializing => this == PluginState.initializing;
  bool get isReady => this == PluginState.ready;
  bool get isError => this == PluginState.error;
  bool get isDisposed => this == PluginState.disposed;

  bool get canInitialize => isUninitialized || isError;
  bool get canDispose => isReady || isError;
  bool get isActive => isReady;
}
