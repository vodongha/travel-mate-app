import 'package:flutter/material.dart';

import 'app_web_view.dart';

/// A generic in-app page that shows an external [url] in a WebView. Used on
/// mobile for the community/support forum and the publisher website; on web the
/// caller opens the URL in a new tab instead (see `openWebPage`).
class WebPageScreen extends StatelessWidget {
  const WebPageScreen({super.key, required this.title, required this.url});

  final String title;
  final String url;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: AppWebView(url: url),
    );
  }
}
