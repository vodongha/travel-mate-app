import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'money.dart';

/// The input formatters for a money field: digits + an optional decimal point, then live thousands
/// grouping. The amount fields are numeric (a number keyboard), so this never touches a Vietnamese
/// IME composing region — it only ever rewrites digits, and it clears the composing range on the
/// result so the keyboard's suggestion strip can't reintroduce stale text.
List<TextInputFormatter> amountInputFormatters(String currency) => [
      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
      _GroupedAmountFormatter(Money.decimalsFor(currency)),
    ];

/// Inserts thousands separators as the user types, keeping the caret at the right digit.
/// e.g. typing `55665585` shows `55,665,585`; the decimal part (when the currency allows one) is
/// kept ungrouped and capped at the currency's decimal places.
class _GroupedAmountFormatter extends TextInputFormatter {
  _GroupedAmountFormatter(this.maxDecimals);

  final int maxDecimals;

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final String groupSep = NumberFormat.decimalPattern().symbols.GROUP_SEP;

    final String raw = newValue.text;
    // Count digits left of the caret so we can restore it after regrouping.
    final int caret = newValue.selection.end.clamp(0, raw.length);
    final int digitsBeforeCaret =
        raw.substring(0, caret).replaceAll(RegExp(r'[^0-9]'), '').length;

    // Keep digits and at most one decimal point.
    String cleaned =
        raw.replaceAll(groupSep, '').replaceAll(RegExp(r'[^0-9.]'), '');
    String intPart;
    String? decPart;
    final int dot = cleaned.indexOf('.');
    if (maxDecimals == 0) {
      // No decimals for this currency: ignore the dot and anything after it.
      intPart = dot < 0 ? cleaned : cleaned.substring(0, dot);
    } else if (dot < 0) {
      intPart = cleaned;
    } else {
      intPart = cleaned.substring(0, dot).replaceAll('.', '');
      decPart = cleaned.substring(dot + 1).replaceAll('.', '');
      if (decPart.length > maxDecimals) {
        decPart = decPart.substring(0, maxDecimals);
      }
    }

    // Drop leading zeros (but keep a single 0 if that's all there is).
    intPart = intPart.replaceFirst(RegExp(r'^0+(?=\d)'), '');

    // Group the integer part by hand (no int.parse — amounts can exceed 64-bit).
    final String groupedInt = intPart.isEmpty
        ? ''
        : intPart.replaceAllMapped(
            RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]}$groupSep');

    String result = groupedInt;
    if (decPart != null) {
      result = '$groupedInt.$decPart';
    }

    // Place the caret after the same number of digits it preceded before.
    int offset = 0;
    int seen = 0;
    if (digitsBeforeCaret > 0) {
      for (; offset < result.length; offset++) {
        if (RegExp(r'[0-9]').hasMatch(result[offset])) {
          seen++;
          if (seen == digitsBeforeCaret) {
            offset++;
            break;
          }
        }
      }
      if (seen < digitsBeforeCaret) {
        offset = result.length;
      }
    }

    return TextEditingValue(
      text: result,
      selection:
          TextSelection.collapsed(offset: offset.clamp(0, result.length)),
      composing: TextRange.empty,
    );
  }
}
