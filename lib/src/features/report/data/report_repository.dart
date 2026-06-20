import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_client.dart';

class Report {
  const Report({
    required this.baseCurrency,
    required this.totalBudget,
    required this.totalActual,
    required this.overUnder,
    required this.byCategory,
    required this.unexpected,
    required this.debts,
  });

  final String baseCurrency;
  final num totalBudget;
  final num totalActual;
  final num overUnder;
  final List<CategoryLine> byCategory;
  final List<UnexpectedLine> unexpected;
  final List<DebtLine> debts;

  factory Report.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> summary =
        (json['summary'] as Map?)?.cast<String, dynamic>() ?? const {};
    List<T> parse<T>(String key, T Function(Map<String, dynamic>) f) =>
        ((json[key] as List<dynamic>?) ?? [])
            .map((e) => f(e as Map<String, dynamic>))
            .toList();
    return Report(
      baseCurrency: json['baseCurrency'] as String? ?? 'VND',
      totalBudget: (summary['totalBudget'] as num?) ?? 0,
      totalActual: (summary['totalActual'] as num?) ?? 0,
      overUnder: (summary['overUnder'] as num?) ?? 0,
      byCategory: parse('byCategory', CategoryLine.fromJson),
      unexpected: parse('unexpected', UnexpectedLine.fromJson),
      debts: parse('debts', DebtLine.fromJson),
    );
  }
}

class CategoryLine {
  const CategoryLine(
      {required this.category, required this.budget, required this.actual});

  final String category;
  final num budget;
  final num actual;

  factory CategoryLine.fromJson(Map<String, dynamic> json) => CategoryLine(
        category: json['category'] as String? ?? 'OTHER',
        budget: (json['budget'] as num?) ?? 0,
        actual: (json['actual'] as num?) ?? 0,
      );
}

class UnexpectedLine {
  const UnexpectedLine(
      {required this.title, required this.category, required this.amountBase});

  final String title;
  final String category;
  final num amountBase;

  factory UnexpectedLine.fromJson(Map<String, dynamic> json) => UnexpectedLine(
        title: json['title'] as String? ?? '',
        category: json['category'] as String? ?? 'OTHER',
        amountBase: (json['amountBase'] as num?) ?? 0,
      );
}

class DebtLine {
  const DebtLine(
      {required this.fromName, required this.toName, required this.amount});

  final String fromName;
  final String toName;
  final num amount;

  factory DebtLine.fromJson(Map<String, dynamic> json) => DebtLine(
        fromName: json['fromName'] as String? ?? '',
        toName: json['toName'] as String? ?? '',
        amount: (json['amount'] as num?) ?? 0,
      );
}

class ReportRepository {
  ReportRepository(this._dio);

  final Dio _dio;

  Future<Report> get(String tripRid) async {
    try {
      final Response<dynamic> res =
          await _dio.get<dynamic>('/trips/$tripRid/report');
      return Report.fromJson((res.data as Map)['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }
}

final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  return ReportRepository(ref.watch(dioProvider));
});

final reportProvider = FutureProvider.family<Report, String>((ref, tripRid) {
  return ref.watch(reportRepositoryProvider).get(tripRid);
});
