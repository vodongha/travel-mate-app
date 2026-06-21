// Platform-dispatched WebView.
//
// On Android / iOS this resolves to a real `webview_flutter` view; on the web it
// resolves to an `<iframe>`. Both expose the same `AppWebView` widget so callers
// don't care which platform they're on. Mirrors family-budget-app's
// `privacy_web_view.dart` conditional export — `webview_flutter` is NEVER
// imported on a web-reachable path, so the web build still compiles.
export 'app_web_view_mobile.dart'
    if (dart.library.html) 'app_web_view_web.dart';
