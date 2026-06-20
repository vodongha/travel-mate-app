import 'package:intl/intl.dart';

/// Currency catalogue used by the display-currency picker and the converter.
///
/// This complements [Money] (which only formats backend-computed amounts): it
/// knows the **list** of selectable currencies, their decimals and symbols, and
/// how to format an arbitrary major-unit value for the client-side converter.
/// Money arithmetic for real balances still belongs on the backend — this is
/// only the display-only converter tool.
class Currencies {
  const Currencies._();

  static const String baseCurrency = 'VND';

  /// ISO-4217 → number of decimal places. Mirrors the backend currency set.
  static const Map<String, int> _decimals = {
    // Zero-decimal.
    'VND': 0,
    'JPY': 0,
    'KRW': 0,
    'CLP': 0,
    'ISK': 0,
    // Three-decimal.
    'KWD': 3,
    'BHD': 3,
    'OMR': 3,
    'JOD': 3,
    // Two-decimal.
    'USD': 2,
    'EUR': 2,
    'GBP': 2,
    'AUD': 2,
    'CAD': 2,
    'CHF': 2,
    'CNY': 2,
    'HKD': 2,
    'NZD': 2,
    'SGD': 2,
    'TWD': 2,
    'SEK': 2,
    'NOK': 2,
    'DKK': 2,
    'PLN': 2,
    'CZK': 2,
    'HUF': 2,
    'RON': 2,
    'BGN': 2,
    'TRY': 2,
    'RUB': 2,
    'UAH': 2,
    'THB': 2,
    'IDR': 2,
    'MYR': 2,
    'PHP': 2,
    'INR': 2,
    'PKR': 2,
    'BDT': 2,
    'LKR': 2,
    'AED': 2,
    'SAR': 2,
    'QAR': 2,
    'ILS': 2,
    'EGP': 2,
    'ZAR': 2,
    'NGN': 2,
    'KES': 2,
    'MAD': 2,
    'MXN': 2,
    'BRL': 2,
    'ARS': 2,
    'COP': 2,
    'PEN': 2,
  };

  /// Well-known symbols; currencies without one fall back to their code.
  static const Map<String, String> _symbols = {
    'VND': '₫',
    'USD': r'$',
    'EUR': '€',
    'JPY': '¥',
    'GBP': '£',
    'AUD': r'A$',
    'CAD': r'C$',
    'CHF': 'Fr',
    'CNY': '¥',
    'HKD': r'HK$',
    'NZD': r'NZ$',
    'SGD': r'S$',
    'TWD': r'NT$',
    'KRW': '₩',
    'THB': '฿',
    'INR': '₹',
    'RUB': '₽',
    'TRY': '₺',
    'UAH': '₴',
    'PLN': 'zł',
    'SEK': 'kr',
    'NOK': 'kr',
    'DKK': 'kr',
    'CZK': 'Kč',
    'HUF': 'Ft',
    'ILS': '₪',
    'PHP': '₱',
    'IDR': 'Rp',
    'MYR': 'RM',
    'ZAR': 'R',
    'NGN': '₦',
    'BRL': r'R$',
    'MXN': r'$',
    'AED': 'د.إ',
    'SAR': '﷼',
  };

  /// A few widely-used currencies surfaced first in pickers.
  static const List<String> _popularOrder = [
    'VND', 'USD', 'EUR', 'JPY', 'GBP', 'CNY', 'KRW', 'AUD', //
    'CAD', 'CHF', 'SGD', 'HKD', 'THB', 'TWD',
  ];

  /// Supported currencies, popular ones first, then the rest A–Z.
  static List<String> get supported {
    final List<String> all = _decimals.keys.toList();
    final List<String> rest =
        all.where((c) => !_popularOrder.contains(c)).toList()..sort();
    return [
      ..._popularOrder.where(all.contains),
      ...rest,
    ];
  }

  static bool isSupported(String code) => _decimals.containsKey(code);

  static int decimalsFor(String currency) => _decimals[currency] ?? 2;

  static String symbolFor(String currency) => _symbols[currency] ?? currency;

  /// A picker label for a currency: `"USD  $"`, or just the code when there's
  /// no distinct symbol (`"PEN"`).
  static String label(String currency) {
    final String s = symbolFor(currency);
    return s == currency ? currency : '$currency  $s';
  }

  /// Formats a **major-unit** value with the currency's symbol and decimals,
  /// e.g. `format(10.5, 'USD')` → `$10.50`, `format(50000, 'VND')` → `50.000 ₫`.
  static String format(num amount, String currency) {
    final int dec = decimalsFor(currency);
    final NumberFormat f = NumberFormat.currency(
      symbol: symbolFor(currency),
      decimalDigits: dec,
    );
    return f.format(amount);
  }

  /// An example amount for a field hint, with the right decimals for [currency].
  static String hintExample(String currency) {
    final int dec = decimalsFor(currency);
    final NumberFormat f = NumberFormat.decimalPattern()
      ..minimumFractionDigits = dec
      ..maximumFractionDigits = dec;
    return f.format(100);
  }
}
