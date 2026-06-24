import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travel_mate_app/l10n/app_localizations.dart';
import 'package:travel_mate_app/src/core/api_client.dart';
import 'package:travel_mate_app/src/core/app_dropdown.dart';
import 'package:travel_mate_app/src/core/app_error_view.dart';
import 'package:travel_mate_app/src/core/money.dart';
import 'package:travel_mate_app/src/core/theme.dart';
import 'package:travel_mate_app/src/features/auth/presentation/login_screen.dart';

Widget _wrap(Widget child) => MaterialApp(
      theme: AppTheme.light(),
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );

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

  testWidgets('a connection error shows friendly copy', (tester) async {
    await tester.pumpWidget(_wrap(AppErrorView(
      error: ApiException('connection-error', isConnection: true),
      onRetry: () {},
    )));
    await tester.pumpAndSettle();

    expect(find.textContaining("can't reach the server", findRichText: true),
        findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('tapping retry shows a spinner and disables the button',
      (tester) async {
    await tester.pumpWidget(_wrap(AppErrorView(
      error: ApiException('boom'),
      onRetry:
          () {}, // a no-op retry, so the view stays put and we can inspect it
    )));
    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    await tester.tap(find.byType(OutlinedButton));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Retrying…'), findsOneWidget);
    final OutlinedButton button = tester.widget(find.byType(OutlinedButton));
    expect(button.onPressed, isNull); // disabled while retrying
  });

  testWidgets('AppDropdownField opens a rounded menu and selects an item',
      (tester) async {
    String? picked;
    await tester.pumpWidget(_wrap(AppDropdownField<String>(
      initialValue: 'a',
      items: const [
        DropdownMenuItem(value: 'a', child: Text('Apple')),
        DropdownMenuItem(value: 'b', child: Text('Banana')),
      ],
      onChanged: (v) => picked = v,
    )));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Apple'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Banana').last);
    await tester.pumpAndSettle();

    expect(picked, 'b');
  });

  test('Money.grouped adds thousands separators per currency', () {
    expect(Money.grouped('446566464', 'VND'), '446,566,464');
    expect(Money.grouped('1234.5', 'USD'), '1,234.5');
    expect(Money.grouped('', 'VND'), isNull);
  });

  test('Money.groupedWithCurrency appends the currency code', () {
    expect(Money.groupedWithCurrency('4687767', 'VND'), '4,687,767 VND');
    expect(Money.groupedWithCurrency('', 'VND'), isNull);
  });
}
