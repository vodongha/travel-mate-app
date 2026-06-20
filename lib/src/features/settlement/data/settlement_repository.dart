import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_client.dart';

class Settlement {
  const Settlement(
      {required this.baseCurrency,
      required this.balances,
      required this.transactions});

  final String baseCurrency;
  final List<Balance> balances;
  final List<SettlementTransaction> transactions;

  factory Settlement.fromJson(Map<String, dynamic> json) => Settlement(
        baseCurrency: json['baseCurrency'] as String? ?? 'VND',
        balances: ((json['balances'] as List<dynamic>?) ?? [])
            .map((e) => Balance.fromJson(e as Map<String, dynamic>))
            .toList(),
        transactions: ((json['transactions'] as List<dynamic>?) ?? [])
            .map((e) =>
                SettlementTransaction.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class Balance {
  const Balance({required this.displayName, required this.net});

  final String displayName;
  final num net;

  factory Balance.fromJson(Map<String, dynamic> json) => Balance(
        displayName: json['displayName'] as String? ?? '',
        net: (json['net'] as num?) ?? 0,
      );
}

class SettlementTransaction {
  const SettlementTransaction(
      {required this.fromName, required this.toName, required this.amount});

  final String fromName;
  final String toName;
  final num amount;

  factory SettlementTransaction.fromJson(Map<String, dynamic> json) =>
      SettlementTransaction(
        fromName: json['fromName'] as String? ?? '',
        toName: json['toName'] as String? ?? '',
        amount: (json['amount'] as num?) ?? 0,
      );
}

class SettlementRepository {
  SettlementRepository(this._dio);

  final Dio _dio;

  Future<Settlement> get(String tripRid) async {
    try {
      final Response<dynamic> res =
          await _dio.get<dynamic>('/trips/$tripRid/settlement');
      return Settlement.fromJson(
          (res.data as Map)['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }
}

final settlementRepositoryProvider = Provider<SettlementRepository>((ref) {
  return SettlementRepository(ref.watch(dioProvider));
});

final settlementProvider =
    FutureProvider.family<Settlement, String>((ref, tripRid) {
  return ref.watch(settlementRepositoryProvider).get(tripRid);
});
