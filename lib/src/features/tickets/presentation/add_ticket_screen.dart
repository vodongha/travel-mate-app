import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/app_error.dart';
import '../../../core/form_buttons.dart';
import '../../../core/labels.dart';
import '../../../core/qr_scan_screen.dart';
import '../../../core/responsive.dart';
import '../../members/application/members_controller.dart';
import '../../members/domain/member.dart';
import '../../trips/application/trips_controller.dart';
import '../application/tickets_controller.dart';
import '../data/ticket_repository.dart';

/// Add or edit a ticket. The QR is captured as a decoded string via [QrField] (scan with
/// mobile_scanner or type/paste). EDITOR/OWNER may assign the ticket to another member; everyone
/// else can only manage their own (assignee picker hidden → server treats it as the caller's own).
class AddTicketScreen extends ConsumerStatefulWidget {
  const AddTicketScreen({super.key, required this.tripRid, this.existing});

  final String tripRid;
  final Ticket? existing;

  @override
  ConsumerState<AddTicketScreen> createState() => _AddTicketScreenState();
}

class _AddTicketScreenState extends ConsumerState<AddTicketScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _note = TextEditingController();
  final _code = TextEditingController();
  final _seat = TextEditingController();
  String _type = 'OTHER';
  // null ⇒ "myself" (server omits memberRid); otherwise the chosen member's rid.
  String? _memberRid;
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
      _memberRid = t.mine ? null : t.memberRid;
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _note.dispose();
    _code.dispose();
    _seat.dispose();
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
    try {
      final controller =
          ref.read(allTicketsControllerProvider(widget.tripRid).notifier);
      if (_editing) {
        await controller.edit(
          rid: widget.existing!.rid,
          memberRid: _memberRid,
          title: _title.text.trim(),
          ticketType: _type,
          qrData: _trim(_code),
          seat: _type == 'TRANSPORT' ? _trim(_seat) : null,
          note: _trim(_note),
        );
      } else {
        await controller.create(
          memberRid: _memberRid,
          title: _title.text.trim(),
          ticketType: _type,
          qrData: _trim(_code),
          seat: _type == 'TRANSPORT' ? _trim(_seat) : null,
          note: _trim(_note),
        );
      }
      if (mounted) {
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
                DropdownButtonFormField<String>(
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
                    controller: _seat,
                    decoration: InputDecoration(
                        labelText: l10n.fieldSeat,
                        prefixIcon: const Icon(Icons.event_seat_outlined)),
                  ),
                ],
                const SizedBox(height: 16),
                if (canAssign)
                  members.when(
                    loading: () => const LinearProgressIndicator(),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (list) => _AssigneeField(
                      // Exclude the caller's own membership — the "Myself" option
                      // already covers it (no duplicate name).
                      members: list.where((m) => !m.mine).toList(),
                      value: _memberRid,
                      onChanged: (v) => setState(() => _memberRid = v),
                    ),
                  ),
                if (canAssign) const SizedBox(height: 16),
                TextFormField(
                  controller: _note,
                  maxLines: 2,
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
}

/// Picks who the ticket belongs to. The default (null value) is "myself" — the server reads an
/// omitted memberRid as the caller's own ticket.
class _AssigneeField extends StatelessWidget {
  const _AssigneeField({
    required this.members,
    required this.value,
    required this.onChanged,
  });

  final List<Member> members;
  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    // Guard against a stale rid that's no longer in the list.
    final bool valid = value == null || members.any((m) => m.rid == value);
    return DropdownButtonFormField<String?>(
      initialValue: valid ? value : null,
      decoration: InputDecoration(
          labelText: l10n.ticketAssignee,
          prefixIcon: const Icon(Icons.person_outline)),
      items: [
        DropdownMenuItem<String?>(
            value: null, child: Text(l10n.ticketAssigneeMyself)),
        ...members.map((m) => DropdownMenuItem<String?>(
            value: m.rid, child: Text(m.displayName))),
      ],
      onChanged: onChanged,
    );
  }
}
