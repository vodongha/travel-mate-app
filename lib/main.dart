import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'src/app.dart';
import 'src/core/prefs.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Load prefs before the first frame so the chosen theme/language apply immediately.
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const TravelMateApp(),
    ),
  );
}
