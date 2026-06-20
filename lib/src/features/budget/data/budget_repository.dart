import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_client.dart';

/// A planned budget line (backend `BudgetResponse`).
class Budget {
  const Budget(
      {required this.rid, required this.category, required this.plannedAmount});

  final String rid;
  final String category;
  final num plannedAmount;

  factory Budget.fromJson(Map<String, dynamic> json) => Budget(
        rid: json['rid'] as String,
        category: json['category'] as String? ?? 'OTHER',
        plannedAmount: (json['plannedAmount'] as num?) ?? 0,
      );
}

class BudgetRepository {
  BudgetRepository(this._dio);

  final Dio _dio;

  Future<List<Budget>> list(String tripRid) async {
    try {
      final Response<dynamic> res =
          await _dio.get<dynamic>('/trips/$tripRid/budgets');
      final List<dynamic> data = (res.data as Map)['data'] as List<dynamic>;
      return data
          .map((e) => Budget.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<Budget> create(
      String tripRid, String category, num plannedAmount) async {
    try {
      final Response<dynamic> res = await _dio.post<dynamic>(
        '/trips/$tripRid/budgets',
        data: {'category': category, 'plannedAmount': plannedAmount},
      );
      return Budget.fromJson((res.data as Map)['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }
}

final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  return BudgetRepository(ref.watch(dioProvider));
});
