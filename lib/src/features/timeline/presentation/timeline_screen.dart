import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/app_error_view.dart';
import '../../../core/labels.dart';
import '../../../core/responsive.dart';
import '../application/events_controller.dart';
import '../data/event_repository.dart';

class TimelineScreen extends ConsumerWidget {
  const TimelineScreen({super.key, required this.tripRid});

  final String tripRid;

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
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, i) => _EventCard(event: list[i]),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({required this.event});

  final EventItem event;

  @override
  Widget build(BuildContext context) {
    final String locale = Localizations.localeOf(context).toLanguageTag();
    final String when = event.startTime == null
        ? ''
        : DateFormat.MMMEd(locale).add_Hm().format(event.startTime!.toLocal());
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
          foregroundColor: Theme.of(context).colorScheme.onTertiaryContainer,
          child: const Icon(Icons.event),
        ),
        title: Text(event.title),
        subtitle: Text('${Labels.eventType(context, event.eventType)}'
            '${when.isEmpty ? '' : ' · $when'}'),
      ),
    );
  }
}
