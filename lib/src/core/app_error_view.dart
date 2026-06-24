import 'dart:async';

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import 'app_error.dart';

/// A centered error state with a retry button — used for failed async loads. Tapping retry shows a
/// spinner in the button so the user gets immediate feedback that the reload is in progress (the
/// view is normally replaced by the parent's loading state moments later).
class AppErrorView extends StatefulWidget {
  const AppErrorView({super.key, required this.error, this.onRetry});

  final Object error;
  final VoidCallback? onRetry;

  @override
  State<AppErrorView> createState() => _AppErrorViewState();
}

class _AppErrorViewState extends State<AppErrorView> {
  bool _retrying = false;
  Timer? _safety;

  @override
  void dispose() {
    _safety?.cancel();
    super.dispose();
  }

  void _retry() {
    if (_retrying || widget.onRetry == null) {
      return;
    }
    setState(() => _retrying = true);
    widget.onRetry!.call();
    // The reload normally rebuilds this widget away into a loading state; if it somehow doesn't
    // (e.g. the error returns without a loading frame), re-enable the button so we never get stuck.
    _safety = Timer(const Duration(seconds: 8), () {
      if (mounted) {
        setState(() => _retrying = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_outlined,
                size: 56, color: scheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(friendlyError(context, widget.error),
                textAlign: TextAlign.center),
            if (widget.onRetry != null) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _retrying ? null : _retry,
                icon: _retrying
                    ? SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: scheme.primary,
                        ),
                      )
                    : const Icon(Icons.refresh),
                label: Text(_retrying ? l10n.retrying : l10n.actionRetry),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
