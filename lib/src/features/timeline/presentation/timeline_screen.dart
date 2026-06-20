import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/actions.dart';
import '../../../core/app_error.dart';
import '../../../core/app_error_view.dart';
import '../../../core/labels.dart';
import '../../../core/responsive.dart';
import '../application/events_controller.dart';
import '../data/event_repository.dart';

class TimelineScreen extends ConsumerWidget {
  const TimelineScreen({super.key, required this.tripRid});

  final String tripRid;

  Future<void> _rowActions(
      BuildContext context, WidgetRef ref, EventItem event) async {
    final RowAction? action = await showRowActions(context, title: event.title);
    if (action == null || !context.mounted) {
      return;
    }
    if (action == RowAction.edit) {
      context.go('/trips/$tripRid/timeline/${event.rid}/edit', extra: event);
      return;
    }
    if (!await confirmDelete(context) || !context.mounted) {
      return;
    }
    try {
      await ref
          .read(eventsControllerProvider(tripRid).notifier)
          .delete(event.rid);
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(friendlyError(context, error))));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AsyncValue<List<EventItem>> events =
        ref.watch(eventsControllerProvider(tripRid));
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navTimeline)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/trips/$tripRid/timeline/new'),
        icon: const Icon(Icons.add),
        label: Text(l10n.eventNew),
      ),
      body: SafeArea(
        child: ResponsiveCenter(
          child: events.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => AppErrorView(
                error: e,
                onRetry: () =>
                    ref.invalidate(eventsControllerProvider(tripRid))),
            data: (list) => list.isEmpty
                ? Center(child: Text(l10n.timelineEmpty))
                : RefreshIndicator(
                    onRefresh: () async =>
                        ref.invalidate(eventsControllerProvider(tripRid)),
                    child: _Timeline(
                      events: list,
                      onTap: (e) => _rowActions(context, ref, e),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

/// Splits events into Upcoming / Past and renders each group as a connected vertical timeline.
class _Timeline extends StatelessWidget {
  const _Timeline({required this.events, required this.onTap});

  final List<EventItem> events;
  final void Function(EventItem) onTap;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final DateTime now = DateTime.now();
    // Events arrive ordered by start time ascending.
    final List<EventItem> upcoming = events
        .where(
            (e) => e.startTime == null || !e.startTime!.toLocal().isBefore(now))
        .toList();
    final List<EventItem> past = events
        .where(
            (e) => e.startTime != null && e.startTime!.toLocal().isBefore(now))
        .toList();

    final List<Widget> children = [];
    if (upcoming.isNotEmpty) {
      children.add(_header(context, l10n.timelineUpcoming));
      for (int i = 0; i < upcoming.length; i++) {
        children.add(_TimelineTile(
          event: upcoming[i],
          isFirst: i == 0,
          isLast: i == upcoming.length - 1,
          highlight: i == 0, // the very next event
          onTap: () => onTap(upcoming[i]),
        ));
      }
    }
    if (past.isNotEmpty) {
      children.add(_header(context, l10n.timelinePast));
      for (int i = 0; i < past.length; i++) {
        children.add(_TimelineTile(
          event: past[i],
          isFirst: i == 0,
          isLast: i == past.length - 1,
          highlight: false,
          dimmed: true,
          onTap: () => onTap(past[i]),
        ));
      }
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      children: children,
    );
  }

  Widget _header(BuildContext context, String text) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
        child: Text(text,
            style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w700,
                fontSize: 13)),
      );
}

class _TimelineTile extends StatelessWidget {
  const _TimelineTile({
    required this.event,
    required this.isFirst,
    required this.isLast,
    required this.highlight,
    required this.onTap,
    this.dimmed = false,
  });

  final EventItem event;
  final bool isFirst;
  final bool isLast;
  final bool highlight;
  final bool dimmed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final String locale = Localizations.localeOf(context).toLanguageTag();
    final String when = event.startTime == null
        ? ''
        : DateFormat.MMMEd(locale).add_Hm().format(event.startTime!.toLocal());
    final Color line = scheme.outlineVariant;
    final Color dotColor = highlight
        ? scheme.primary
        : (dimmed ? scheme.outline : scheme.tertiary);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // The rail: a vertical line with a dot, joined to neighbours.
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Expanded(
                    child: Container(
                        width: 2, color: isFirst ? Colors.transparent : line)),
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: scheme.surface, width: 2),
                  ),
                ),
                Expanded(
                    child: Container(
                        width: 2, color: isLast ? Colors.transparent : line)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Card(
                color: highlight ? scheme.primaryContainer : null,
                child: ListTile(
                  title: Text(event.title,
                      style: dimmed
                          ? TextStyle(color: scheme.onSurfaceVariant)
                          : null),
                  subtitle: Text('${Labels.eventType(context, event.eventType)}'
                      '${when.isEmpty ? '' : ' · $when'}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.more_vert),
                    tooltip: AppLocalizations.of(context).actionEdit,
                    onPressed: onTap,
                  ),
                  onTap: onTap,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
