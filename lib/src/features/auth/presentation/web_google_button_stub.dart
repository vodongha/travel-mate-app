import 'package:flutter/widgets.dart';

/// Non-web placeholder — the Google-rendered button only exists on web. Mobile uses the regular
/// OutlinedButton in [GoogleSignInButton].
Widget buildWebGoogleButton(Future<void> Function(String idToken) onIdToken) =>
    const SizedBox.shrink();
