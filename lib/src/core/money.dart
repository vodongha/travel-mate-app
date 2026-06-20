import 'package:intl/intl.dart';

/// Formats money the backend already computed (it owns all money maths). Amounts arrive as major
/// units in `NUMBER(19,4)`; we just group them and append the currency code, with the right number
/// of decimals (0 for VND/JPY/KRW, 2 otherwise).
class Money {
  const Money._();

  static const Set<String> _zeroDecimal = {'VND', 'JPY', 'KRW', 'CLP', 'ISK'};

  static String format(num amount, String currency) {
    final int dec = _zeroDecimal.contains(currency) ? 0 : 2;
    final NumberFormat f = NumberFormat.decimalPattern()
      ..minimumFractionDigits = dec
      ..maximumFractionDigits = dec;
    return '${f.format(amount)} $currency';
  }
}
