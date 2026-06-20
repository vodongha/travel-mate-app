/// Trip dashboard summary (backend `DashboardResponse`). Money values are major-unit numbers in the
/// trip's base currency; the app only formats them.
class Dashboard {
  const Dashboard({
    required this.baseCurrency,
    this.countdownDays,
    required this.totalBudget,
    required this.totalSpent,
    required this.fundBalance,
    this.nextEvent,
  });

  final String baseCurrency;
  final int? countdownDays;
  final num totalBudget;
  final num totalSpent;
  final num fundBalance;
  final NextEvent? nextEvent;

  factory Dashboard.fromJson(Map<String, dynamic> json) {
    final Object? event = json['nextEvent'];
    return Dashboard(
      baseCurrency: json['baseCurrency'] as String? ?? 'VND',
      countdownDays: (json['countdownDays'] as num?)?.toInt(),
      totalBudget: (json['totalBudget'] as num?) ?? 0,
      totalSpent: (json['totalSpent'] as num?) ?? 0,
      fundBalance: (json['fundBalance'] as num?) ?? 0,
      nextEvent:
          event is Map<String, dynamic> ? NextEvent.fromJson(event) : null,
    );
  }
}

class NextEvent {
  const NextEvent(
      {required this.rid, required this.title, this.eventType, this.startTime});

  final String rid;
  final String title;
  final String? eventType;
  final DateTime? startTime;

  factory NextEvent.fromJson(Map<String, dynamic> json) {
    final Object? start = json['startTime'];
    return NextEvent(
      rid: json['rid'] as String? ?? '',
      title: json['title'] as String? ?? '',
      eventType: json['eventType'] as String?,
      startTime: start is String ? DateTime.tryParse(start) : null,
    );
  }
}
