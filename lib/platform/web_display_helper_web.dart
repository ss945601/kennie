import 'dart:html' as html;

Future<void> enterLandscapeFullscreen() async {
  final document = html.document;
  final rootElement = document.documentElement;

  if (rootElement != null && document.fullscreenElement == null) {
    try {
      rootElement.requestFullscreen();
    } catch (_) {}
  }

  try {
    final dynamic screen = html.window.screen;
    final dynamic orientation = screen.orientation;
    if (orientation != null) {
      orientation.lock('landscape');
    }
  } catch (_) {}
}