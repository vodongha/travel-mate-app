import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import 'currencies.dart';

/// Opens a searchable currency picker (a bottom sheet with a search field over the supported set)
/// and returns the chosen ISO code, or null if dismissed. Reused everywhere a currency is selected.
Future<String?> showCurrencyPicker(BuildContext context, String current) {
  return showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (ctx) => _CurrencyPickerSheet(current: current),
  );
}

class _CurrencyPickerSheet extends StatefulWidget {
  const _CurrencyPickerSheet({required this.current});
  final String current;

  @override
  State<_CurrencyPickerSheet> createState() => _CurrencyPickerSheetState();
}

class _CurrencyPickerSheetState extends State<_CurrencyPickerSheet> {
  final TextEditingController _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<String> get _filtered {
    final String q = _query.trim().toUpperCase();
    if (q.isEmpty) {
      return Currencies.supported;
    }
    return Currencies.supported
        .where((c) =>
            c.toUpperCase().contains(q) ||
            Currencies.label(c).toUpperCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final List<String> items = _filtered;
    return Padding(
      // Lift the sheet above the keyboard.
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                controller: _search,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: l10n.currencySearchHint,
                  prefixIcon: const Icon(Icons.search),
                  isDense: true,
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            Expanded(
              child: items.isEmpty
                  ? Center(child: Text(l10n.currencyNoMatch))
                  : ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (context, i) {
                        final String c = items[i];
                        return ListTile(
                          title: Text(Currencies.label(c)),
                          trailing: c == widget.current
                              ? const Icon(Icons.check)
                              : null,
                          onTap: () => Navigator.pop(context, c),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
