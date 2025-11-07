import 'editor_event.dart';

abstract class EventBus {
  void publish(EditorEvent event);

  Stream<EditorEvent> get stream;

  Stream<T> on<T extends EditorEvent>();

  void dispose();
}
