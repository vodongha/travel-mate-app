import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travel_mate_app/l10n/app_localizations.dart';
import 'package:travel_mate_app/src/core/theme.dart';
import 'package:travel_mate_app/src/features/auth/presentation/login_screen.dart';

void main() {
  testWidgets(
      'login screen renders email + password fields and a sign-in button',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light(),
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const LoginScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.byType(FilledButton), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
  });
}
