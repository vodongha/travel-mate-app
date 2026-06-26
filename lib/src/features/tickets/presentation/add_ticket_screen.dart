import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/snackbars.dart';
import '../../../core/app_dropdown.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../core/app_error.dart';
import '../../../core/form_buttons.dart';
import '../../../core/labels.dart';
import '../../../core/qr_scan_screen.dart';
import '../../../core/responsive.dart';
import '../../accommodation/application/accommodation_controller.dart';
import '../../accommodation/data/accommodation_repository.dart';
import '../../expenses/presentation/itinerary_ref.dart';
import '../../members/application/members_controller.dart';
import '../../members/domain/member.dart';
import '../../timeline/application/events_controller.dart';
import '../../timeline/data/event_repository.dart';
import '../../transport/application/transport_controller.dart';
import '../../transport/data/transport_repository.dart';
import '../../trips/application/trips_controller.dart';
import '../application/tickets_controller.dart';
import '../data/ticket_repository.dart';

/// Add or edit a ticket. The QR is captured as a decoded string via [QrField] (scan with
/// mobile_scanner or type/paste). EDITOR/OWNER may assign the ticket to several members or make it a
/// group ticket; everyone else can only manage their own (picker hidden → the caller's own ticket).
class AddTicketScreen extends ConsumerStatefulWidget {
  const AddTicketScreen({
    super.key,
    required this.tripRid,
    this.existing,
    this.itineraryKind,
    this.itineraryRid,
    this.initialType,
  });

  final String tripRid;
  final Ticket? existing;

  /// When opened from a timeline item (event / transport / accommodation), the ticket is pre-attached
  /// to it. Both null means a standalone ticket. Ignored in edit mode (the existing link wins).
  final String? itineraryKind;
  final String? itineraryRid;

  /// Pre-selected ticket category, matching the itinerary item it was opened from (e.g. TRANSPORT
  /// for a flight leg, or the event's own category). Null leaves the default.
  final String? initialType;

  @override
  ConsumerState<AddTicketScreen> createState() => _AddTicketScreenState();
}

class _AddTicketScreenState extends ConsumerState<AddTicketScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _note = TextEditingController();
  final _code = TextEditingController();
  final _seat = TextEditingController();
  final _provider = TextEditingController();
  final _bookingCode = TextEditingController();
  final _memberSearch = TextEditingController();
  String _memberQuery = '';
  String _type = 'OTHER';
  // Who the ticket covers: a set of member rids, or a group ticket (whole trip). Empty set (and not
  // group) ⇒ the caller's own ticket. The two are mutually exclusive.
  final Set<String> _memberRids = {};
  bool _group = false;
  // The itinerary item this ticket is for (a flight leg, stay, event), if any.
  String? _itineraryKind;
  String? _itineraryRid;
  bool _submitting = false;

  bool get _editing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final Ticket? t = widget.existing;
    if (t != null) {
      _title.text = t.title;
      _note.text = t.note ?? '';
      _type = t.ticketType;
      _code.text = t.qrData ?? '';
      _seat.text = t.seat ?? '';
      _provider.text = t.provider ?? '';
      _bookingCode.text = t.bookingCode ?? '';
      _group = t.shared;
      if (!t.shared) {
        _memberRids.addAll(t.memberRids);
      }
      _itineraryKind = t.itineraryKind;
      _itineraryRid = t.itineraryRid;
    } else {
      // New ticket opened from a timeline item: pre-attach to it + match its category.
      _itineraryKind = widget.itineraryKind;
      _itineraryRid = widget.itineraryRid;
      if (widget.initialType != null &&
          Labels.categories.contains(widget.initialType)) {
        _type = widget.initialType!;
      }
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _note.dispose();
    _code.dispose();
    _seat.dispose();
    _provider.dispose();
    _bookingCode.dispose();
    _memberSearch.dispose();
    super.dispose();
  }

  String? _trim(TextEditingController c) =>
      c.text.trim().isEmpty ? null : c.text.trim();

  Future<void> _scanCode() async {
    final String? code = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const QrScanScreen()),
    );
    if (code != null && code.isNotEmpty) {
      setState(() => _code.text = code);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _submitting = true);
    final String? myRole =
        ref.read(tripProvider(widget.tripRid)).valueOrNull?.myRole;
    final bool canAssign = myRole == 'OWNER' || myRole == 'EDITOR';
    // Only an EDITOR/OWNER controls who a ticket covers; otherwise it's the caller's own (don't send
    // members, so an edit leaves them unchanged and a create defaults to the caller).
    final bool shared = canAssign && _group;
    final List<String>? memberRids =
        !canAssign ? null : (_group ? null : _memberRids.toList());
    try {
      final controller =
          ref.read(allTicketsControllerProvider(widget.tripRid).notifier);
      if (_editing) {
        await controller.edit(
          rid: widget.existing!.rid,
          memberRids: memberRids,
          shared: shared,
          title: _title.text.trim(),
          ticketType: _type,
          qrData: _trim(_code),
          seat: _type == 'TRANSPORT' ? _trim(_seat) : null,
          provider: _type == 'TRANSPORT' ? _trim(_provider) : null,
          bookingCode: (_type == 'TRANSPORT' || _type == 'ACCOMMODATION')
              ? _trim(_bookingCode)
              : null,
          itineraryKind: _itineraryKind,
          itineraryRid: _itineraryRid,
          note: _trim(_note),
        );
      } else {
        await controller.create(
          memberRids: memberRids,
          shared: shared,
          title: _title.text.trim(),
          ticketType: _type,
          qrData: _trim(_code),
          seat: _type == 'TRANSPORT' ? _trim(_seat) : null,
          provider: _type == 'TRANSPORT' ? _trim(_provider) : null,
          bookingCode: (_type == 'TRANSPORT' || _type == 'ACCOMMODATION')
              ? _trim(_bookingCode)
              : null,
          itineraryKind: _itineraryKind,
          itineraryRid: _itineraryRid,
          note: _trim(_note),
        );
      }
      if (mounted) {
        showOkSnack(context, AppLocalizations.of(context).msgSaved);
        context.canPop()
            ? context.pop()
            : context.go('/trips/${widget.tripRid}/tickets');
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(friendlyError(context, error))));
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final String? myRole =
        ref.watch(tripProvider(widget.tripRid)).valueOrNull?.myRole;
    final bool canAssign = myRole == 'OWNER' || myRole == 'EDITOR';
    final AsyncValue<List<Member>> members =
        ref.watch(membersControllerProvider(widget.tripRid));
    return Scaffold(
      appBar:
          AppBar(title: Text(_editing ? l10n.ticketEditTitle : l10n.ticketNew)),
      body: SafeArea(
        child: ResponsiveCenter(
          maxWidth: 520,
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                TextFormField(
                  controller: _title,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                      labelText: l10n.fieldName,
                      prefixIcon:
                          const Icon(Icons.confirmation_number_outlined)),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? l10n.validationRequired
                      : null,
                ),
                const SizedBox(height: 16),
                AppDropdownField<String>(
                  initialValue: _type,
                  decoration: InputDecoration(
                      labelText: l10n.fieldType,
                      prefixIcon: const Icon(Icons.category_outlined)),
                  items: Labels.ticketTypes
                      .map((t) => DropdownMenuItem(
                          value: t, child: Text(Labels.ticketType(context, t))))
                      .toList(),
                  onChanged: (v) => setState(() => _type = v ?? 'OTHER'),
                ),
                const SizedBox(height: 16),
                // A ticket can be a plain code (typed) or a scanned QR string.
                TextFormField(
                  controller: _code,
                  decoration: InputDecoration(
                    labelText: l10n.ticketCode,
                    hintText: l10n.ticketCodeHint,
                    prefixIcon: const Icon(Icons.qr_code_2),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.qr_code_scanner),
                      tooltip: l10n.qrScan,
                      onPressed: _scanCode,
                    ),
                  ),
                ),
                if (_type == 'TRANSPORT') ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _provider,
                    decoration: InputDecoration(
                        labelText: l10n.transportProvider,
                        prefixIcon: const Icon(Icons.business_outlined)),
                  ),
                ],
                // Booking/PNR code applies to both transport and accommodation tickets.
                if (_type == 'TRANSPORT' || _type == 'ACCOMMODATION') ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _bookingCode,
                    decoration: InputDecoration(
                        labelText: l10n.fieldBookingCode,
                        prefixIcon:
                            const Icon(Icons.confirmation_number_outlined)),
                  ),
                ],
                if (_type == 'TRANSPORT') ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _seat,
                    decoration: InputDecoration(
                        labelText: l10n.fieldSeat,
                        prefixIcon: const Icon(Icons.event_seat_outlined)),
                  ),
                ],
                const SizedBox(height: 16),
                // Attach the pass to a flight/stay/event so it shows under that itinerary item.
                _attachItineraryField(context, l10n),
                const SizedBox(height: 16),
                if (canAssign)
                  members.when(
                    loading: () => const LinearProgressIndicator(),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (list) => _assignee(context, l10n, list),
                  ),
                if (canAssign) const SizedBox(height: 16),
                TextFormField(
                  controller: _note,
                  minLines: 2,
                  maxLines: 5,
                  keyboardType: TextInputType.multiline,
                  decoration: InputDecoration(
                      labelText: l10n.eventNote,
                      prefixIcon: const Icon(Icons.notes_outlined)),
                ),
                const SizedBox(height: 24),
                FormButtons(
                  primaryLabel: l10n.actionSave,
                  loading: _submitting,
                  onPrimary: _submit,
                  onCancel: () =>
                      context.canPop() ? context.pop() : context.go('/'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// The combined itinerary (events + transport + accommodation) the ticket can attach to.
  List<ItineraryRef> _itineraryRefs() {
    final List<EventItem> events =
        ref.watch(eventsControllerProvider(widget.tripRid)).valueOrNull ??
            const [];
    final List<TransportItem> transports =
        ref.watch(transportControllerProvider(widget.tripRid)).valueOrNull ??
            const [];
    final List<AccommodationItem> stays = ref
            .watch(accommodationControllerProvider(widget.tripRid))
            .valueOrNull ??
        const [];
    return buildItineraryRefs(context, events, transports, stays);
  }

  Widget _attachItineraryField(BuildContext context, AppLocalizations l10n) {
    final List<ItineraryRef> refs = _itineraryRefs();
    final bool attached = _itineraryRid != null;
    String? label;
    if (attached) {
      for (final ItineraryRef r in refs) {
        if (r.kind == _itineraryKind && r.rid == _itineraryRid) {
          label = r.label;
          break;
        }
      }
    }
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () => _pickItinerary(refs),
      borderRadius: BorderRadius.circular(14),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: l10n.ticketForItinerary,
          prefixIcon: const Icon(Icons.timeline_outlined),
          suffixIcon: !attached
              ? const Icon(Icons.chevron_right)
              : IconButton(
                  icon: const Icon(Icons.clear),
                  tooltip: l10n.actionRemove,
                  onPressed: () => setState(() {
                    _itineraryKind = null;
                    _itineraryRid = null;
                  }),
                ),
        ),
        child: Text(
          // A stale link (item deleted) still shows "attached"; fall back to its kind.
          label ??
              (attached
                  ? itinerarySectionLabel(context, _itineraryKind ?? '')
                  : l10n.ticketForItineraryNone),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: attached ? null : TextStyle(color: scheme.onSurfaceVariant),
        ),
      ),
    );
  }

  Future<void> _pickItinerary(List<ItineraryRef> refs) async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ItineraryRef? picked = await showModalBottomSheet<ItineraryRef>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) {
        String? lastKind;
        final List<Widget> tiles = [
          ListTile(
            leading: const Icon(Icons.block_outlined),
            title: Text(l10n.ticketForItineraryNone),
            // Sentinel (empty rid) = explicitly clear, distinct from dismissing the sheet (null).
            onTap: () => Navigator.pop(
                ctx,
                const ItineraryRef(
                    kind: '', rid: '', label: '', icon: Icons.block)),
          ),
        ];
        for (final ItineraryRef r in refs) {
          if (r.kind != lastKind) {
            lastKind = r.kind;
            tiles.add(Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(itinerarySectionLabel(ctx, r.kind),
                  style: Theme.of(ctx)
                      .textTheme
                      .labelMedium
                      ?.copyWith(color: Theme.of(ctx).colorScheme.primary)),
            ));
          }
          tiles.add(ListTile(
            leading: Icon(r.icon),
            title: Text(r.label, maxLines: 1, overflow: TextOverflow.ellipsis),
            onTap: () => Navigator.pop(ctx, r),
          ));
        }
        return SafeArea(child: ListView(shrinkWrap: true, children: tiles));
      },
    );
    if (picked == null) {
      return;
    }
    setState(() {
      if (picked.rid.isEmpty) {
        _itineraryKind = null;
        _itineraryRid = null;
      } else {
        _itineraryKind = picked.kind;
        _itineraryRid = picked.rid;
      }
    });
  }

  /// "Belongs to" — pick several members (checkboxes), or the whole group (a separate, mutually
  /// exclusive option). No members + not group = the caller's own ticket. With many members the list
  /// gets a search box and is height-capped so it scrolls inside the form instead of pushing it down.
  Widget _assignee(
      BuildContext context, AppLocalizations l10n, List<Member> list) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    // Only bother with search once the list is long enough to be awkward to scan.
    final bool searchable = list.length > 6;
    final String q = _memberQuery.trim().toLowerCase();
    final List<Member> filtered = q.isEmpty
        ? list
        : list.where((m) => m.displayName.toLowerCase().contains(q)).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.ticketAssignee,
            style: Theme.of(context).textTheme.labelLarge),
        // "Cả nhóm" is a distinct option, not a per-member checkbox; turning it on clears members.
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          secondary: const Icon(Icons.groups_outlined),
          title: Text(l10n.ticketAssigneeGroup),
          value: _group,
          onChanged: (v) => setState(() {
            _group = v;
            if (v) _memberRids.clear();
          }),
        ),
        if (!_group) ...[
          if (searchable)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: TextField(
                controller: _memberSearch,
                onChanged: (v) => setState(() => _memberQuery = v),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: l10n.ticketsSearchHint,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _memberQuery.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _memberSearch.clear();
                            setState(() => _memberQuery = '');
                          }),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          // Cap the height so a big trip (100+ members) scrolls here, not in the whole form.
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 260),
            child: filtered.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(l10n.ticketsNoMatch,
                        style: TextStyle(
                            fontSize: 13, color: scheme.onSurfaceVariant)),
                  )
                : Scrollbar(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: filtered.length,
                      itemBuilder: (context, i) {
                        final Member m = filtered[i];
                        return CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                          value: _memberRids.contains(m.rid),
                          title: Text(m.mine
                              ? '${m.displayName} (${l10n.ticketAssigneeMyself})'
                              : m.displayName),
                          onChanged: (v) => setState(() {
                            if (v == true) {
                              _memberRids.add(m.rid);
                            } else {
                              _memberRids.remove(m.rid);
                            }
                          }),
                        );
                      },
                    ),
                  ),
          ),
          if (_memberRids.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(l10n.ticketAssigneeHint,
                  style:
                      TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
            ),
        ],
      ],
    );
  }
}
