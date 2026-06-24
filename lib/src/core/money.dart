import 'package:intl/intl.dart';

/// Formats money the backend already computed (it owns all money maths). Amounts arrive as major
/// units in `NUMBER(19,4)`; we just group them and append the currency code, with the right number
/// of decimals (0 for VND/JPY/KRW, 2 otherwise).
class Money {
  const Money._();

  static const Set<String> _zeroDecimal = {'VND', 'JPY', 'KRW', 'CLP', 'ISK'};

  /// Decimal places to show for [currency] (0 for VND/JPY/KRW/CLP/ISK, 2 otherwise).
  static int decimalsFor(String currency) =>
      _zeroDecimal.contains(currency) ? 0 : 2;

  /// Strips grouping separators from a (possibly already grouped) amount string and parses it.
  /// e.g. `"55,665,585"` → `55665585`. Returns null for empty/invalid input. Use this to read the
  /// numeric value out of an amount field that shows live thousands separators.
  static num? parseAmount(String input) {
    final String sep = NumberFormat.decimalPattern().symbols.GROUP_SEP;
    final String cleaned = input.replaceAll(sep, '').trim();
    return cleaned.isEmpty ? null : num.tryParse(cleaned);
  }

  static String format(num amount, String currency) {
    final int dec = decimalsFor(currency);
    final NumberFormat f = NumberFormat.decimalPattern()
      ..minimumFractionDigits = dec
      ..maximumFractionDigits = dec;
    return '${f.format(amount)} $currency';
  }

  /// Grouped digits only (no currency code), for a live preview under an amount
  /// input — e.g. `90000` → `90,000`. Tolerates input that already has separators.
  /// Returns null for empty/invalid input.
  static String? grouped(String input, String currency) {
    final num? n = parseAmount(input);
    if (n == null) {
      return null;
    }
    final NumberFormat f = NumberFormat.decimalPattern()
      ..maximumFractionDigits = decimalsFor(currency);
    return f.format(n);
  }

  /// Like [grouped] but with the currency code appended — e.g. `446566464` → `446,566,464 VND`.
  /// For the live preview under an amount input. Returns null for empty/invalid input.
  static String? groupedWithCurrency(String input, String currency) {
    final String? g = grouped(input, currency);
    return g == null ? null : '$g $currency';
  }
}
