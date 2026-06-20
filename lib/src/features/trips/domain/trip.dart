/// A trip plus the caller's role in it (backend `TripResponse`). Addressed by `rid`.
class Trip {
  const Trip({
    required this.rid,
    required this.name,
    this.description,
    this.destination,
    required this.tripType,
    this.startDate,
    this.endDate,
    required this.timezone,
    required this.baseCurrency,
    required this.status,
    this.myRole,
  });

  final String rid;
  final String name;
  final String? description;
  final String? destination;
  final String tripType;
  final DateTime? startDate;
  final DateTime? endDate;
  final String timezone;
  final String baseCurrency;
  final String status;
  final String? myRole;

  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      rid: json['rid'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      destination: json['destination'] as String?,
      tripType: json['tripType'] as String? ?? 'OTHER',
      startDate: _date(json['startDate']),
      endDate: _date(json['endDate']),
      timezone: json['timezone'] as String? ?? 'Asia/Ho_Chi_Minh',
      baseCurrency: json['baseCurrency'] as String? ?? 'VND',
      status: json['status'] as String? ?? 'PLANNING',
      myRole: json['myRole'] as String?,
    );
  }

  static DateTime? _date(Object? value) {
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}
