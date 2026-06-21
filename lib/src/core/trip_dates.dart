/// Bounds for a date picker used to choose a date/time **inside a trip**.
///
/// When the trip has both a start and end date, the picker is clamped to that
/// range and opens on it (so the user sees the trip's days instead of having to
/// scroll from today to the right month/year). Otherwise it falls back to a wide
/// range around [current]/today.
({DateTime first, DateTime last, DateTime initial}) tripPickerBounds({
  DateTime? tripStart,
  DateTime? tripEnd,
  DateTime? current,
}) {
  DateTime first;
  DateTime last;
  if (tripStart != null && tripEnd != null) {
    first = DateTime(tripStart.year, tripStart.month, tripStart.day);
    last = DateTime(tripEnd.year, tripEnd.month, tripEnd.day, 23, 59);
  } else {
    final DateTime ref = current ?? DateTime.now();
    first = DateTime(ref.year - 1);
    last = DateTime(ref.year + 5);
  }
  DateTime initial = current ?? first;
  if (initial.isBefore(first)) {
    initial = first;
  }
  if (initial.isAfter(last)) {
    initial = last;
  }
  return (first: first, last: last, initial: initial);
}
