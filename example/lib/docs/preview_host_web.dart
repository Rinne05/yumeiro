import 'dart:js_interop';

@JS('window')
external _Window get _window;

extension type _Window(JSObject _) implements JSObject {
  external _Window get parent;
  external _Location get location;
  external void postMessage(JSAny? data, String targetOrigin);
}

extension type _Location(JSObject _) implements JSObject {
  external String get origin;
}

bool get isPreviewEmbedded => _window.strictNotEquals(_window.parent).toDart;

void reportPreviewSize(int height) {
  _window.parent.postMessage(
    {'type': 'yumeiro.previewSize', 'height': height}.jsify(),
    _window.location.origin,
  );
}
