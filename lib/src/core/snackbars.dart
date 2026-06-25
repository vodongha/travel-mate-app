import 'package:flutter/material.dart';

/// A success snackbar for completed CRUD actions. The app's [ScaffoldMessenger] is app-level, so the
/// message survives a `pop()`/`go()` — call it right before navigating away and the user still sees
/// it on the destination screen. Styling comes from the theme (floating + rounded).
void showOkSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(SnackBar(content: Text(message)));
}
