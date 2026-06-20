import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_client.dart';

class FundBalance {
  const FundBalance(
      {required this.baseCurrency,
      required this.balance,
      required this.contributions,
      required this.spent});

  final String baseCurrency;
  final num balance;
  final num contributions;
  final num spent;

  factory FundBalance.fromJson(Map<String, dynamic> json) => FundBalance(
        baseCurrency: json['baseCurrency'] as String? ?? 'VND',
        balance: (json['balance'] as num?) ?? 0,
        contributions: (json['totalContributions'] as num?) ?? 0,
        spent: ((json['totalFundExpenses'] as num?) ?? 0) +
            ((json['totalPersonalPaidFromFund'] as num?) ?? 0),
      );
}

class Contribution {
  const Contribution(
      {required this.rid,
      required this.memberRid,
      required this.currency,
      required this.amount,
      required this.amountBase});

  final String rid;
  final String memberRid;
  final String currency;
  final num amount;
  final num amountBase;

  factory Contribution.fromJson(Map<String, dynamic> json) => Contribution(
        rid: json['rid'] as String,
        memberRid: json['memberRid'] as String? ?? '',
        currency: json['currency'] as String? ?? 'VND',
        amount: (json['amount'] as num?) ?? 0,
        amountBase: (json['amountBase'] as num?) ?? 0,
      );
}

class FundExpense {
  const FundExpense(
      {required this.rid,
      required this.title,
      required this.category,
      required this.currency,
      required this.amount,
      required this.amountBase});

  final String rid;
  final String title;
  final String category;
  final String currency;
  final num amount;
  final num amountBase;

  factory FundExpense.fromJson(Map<String, dynamic> json) => FundExpense(
        rid: json['rid'] as String,
        title: json['title'] as String? ?? '',
        category: json['category'] as String? ?? 'OTHER',
        currency: json['currency'] as String? ?? 'VND',
        amount: (json['amount'] as num?) ?? 0,
        amountBase: (json['amountBase'] as num?) ?? 0,
      );
}

class FundRepository {
  FundRepository(this._dio);

  final Dio _dio;

  Future<FundBalance> balance(String tripRid) =>
      _get('/trips/$tripRid/fund/balance', FundBalance.fromJson);

  Future<List<Contribution>> contributions(String tripRid) =>
      _getList('/trips/$tripRid/fund/contributions', Contribution.fromJson);

  Future<List<FundExpense>> fundExpenses(String tripRid) =>
      _getList('/trips/$tripRid/fund/expenses', FundExpense.fromJson);

  Future<void> addContribution(
      String tripRid, String memberRid, String currency, num amount) async {
    await _post('/trips/$tripRid/fund/contributions',
        {'memberRid': memberRid, 'currency': currency, 'amount': amount});
  }

  Future<void> addFundExpense(String tripRid, String title, String category,
      String currency, num amount) async {
    await _post('/trips/$tripRid/fund/expenses', {
      'title': title,
      'category': category,
      'currency': currency,
      'amount': amount
    });
  }

  Future<T> _get<T>(String path, T Function(Map<String, dynamic>) parse) async {
    try {
      final Response<dynamic> res = await _dio.get<dynamic>(path);
      return parse((res.data as Map)['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<List<T>> _getList<T>(
      String path, T Function(Map<String, dynamic>) parse) async {
    try {
      final Response<dynamic> res = await _dio.get<dynamic>(path);
      final List<dynamic> data = (res.data as Map)['data'] as List<dynamic>;
      return data.map((e) => parse(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<void> _post(String path, Map<String, dynamic> body) async {
    try {
      await _dio.post<dynamic>(path, data: body);
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }
}

final fundRepositoryProvider = Provider<FundRepository>((ref) {
  return FundRepository(ref.watch(dioProvider));
});

final fundBalanceProvider = FutureProvider.family<FundBalance, String>(
    (ref, tripRid) => ref.watch(fundRepositoryProvider).balance(tripRid));
final contributionsProvider = FutureProvider.family<List<Contribution>, String>(
    (ref, tripRid) => ref.watch(fundRepositoryProvider).contributions(tripRid));
final fundExpensesProvider = FutureProvider.family<List<FundExpense>, String>(
    (ref, tripRid) => ref.watch(fundRepositoryProvider).fundExpenses(tripRid));
