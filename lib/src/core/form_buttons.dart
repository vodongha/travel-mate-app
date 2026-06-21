import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// The single, app-wide form action layout: a primary button (Add / Save / Join …) on top and a
/// Cancel button directly below it — both full-width and the same height, with a fixed gap. Use
/// this everywhere (dialogs and full-screen forms) so every form's buttons look identical.
class FormButtons extends StatelessWidget {
  const FormButtons({
    super.key,
    required this.primaryLabel,
    required this.onPrimary,
    this.onCancel,
    this.cancelLabel,
    this.loading = false,
    this.primaryDanger = false,
  });

  final String primaryLabel;
  final VoidCallback? onPrimary;
  final VoidCallback? onCancel;
  final String? cancelLabel;
  final bool loading;

  /// Render the primary action in the error colour (for destructive confirms).
  final bool primaryDanger;

  static const double _height = 50;
  static const double _gap = 12;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton(
          onPressed: loading ? null : onPrimary,
          style: primaryDanger
              ? FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(_height),
                  backgroundColor: scheme.error,
                  foregroundColor: scheme.onError)
              : FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(_height)),
          child: loading
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.4))
              : Text(primaryLabel),
        ),
        const SizedBox(height: _gap),
        OutlinedButton(
          onPressed: loading
              ? null
              : (onCancel ?? () => Navigator.of(context).maybePop()),
          style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(_height)),
          child: Text(cancelLabel ?? l10n.actionCancel),
        ),
      ],
    );
  }
}
