import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_client.dart';

/// One participant's share input (value meaning depends on split type; ignored for EQUAL).
class ParticipantInput {
  const ParticipantInput(this.memberRid, [this.value]);
  final String memberRid;
  final num? value;

  Map<String, dynamic> toJson() =>
      {'memberRid': memberRid, if (value != null) 'value': value};
}

/// An expense as listed (subset of backend `ExpenseResponse`).
class ExpenseItem {
  const ExpenseItem({
    required this.rid,
    required this.title,
    required this.category,
    required this.expenseType,
    required this.currency,
    required this.amount,
    required this.amountBase,
    this.spentAt,
    this.itineraryKind,
    this.itineraryRid,
  });

  final String rid;
  final String title;
  final String category;
  final String expenseType;
  final String currency;
  final num amount;
  final num amountBase;
  final DateTime? spentAt;

  /// The itinerary item this expense is attached to (a timeline event, transport leg, or
  /// accommodation stay), or null for a standalone expense. [itineraryKind] is EVENT / TRANSPORT /
  /// ACCOMMODATION and [itineraryRid] is that item's rid; the pair together identifies the target.
  final String? itineraryKind;
  final String? itineraryRid;

  factory ExpenseItem.fromJson(Map<String, dynamic> json) {
    final Object? spent = json['spentAt'];
    return ExpenseItem(
      rid: json['rid'] as String,
      title: json['title'] as String? ?? '',
      category: json['category'] as String? ?? 'OTHER',
      expenseType: json['expenseType'] as String? ?? 'PLANNED',
      currency: json['currency'] as String? ?? 'VND',
      amount: (json['amount'] as num?) ?? 0,
      amountBase: (json['amountBase'] as num?) ?? 0,
      spentAt: spent is String ? DateTime.tryParse(spent) : null,
      itineraryKind: json['itineraryKind'] as String?,
      itineraryRid: json['itineraryRid'] as String?,
    );
  }
}

class ExpenseRepository {
  ExpenseRepository(this._dio);

  final Dio _dio;

  Future<List<ExpenseItem>> list(String tripRid) async {
    try {
      final Response<dynamic> res =
          await _dio.get<dynamic>('/trips/$tripRid/expenses');
      final List<dynamic> data = (res.data as Map)['data'] as List<dynamic>;
      return data
          .map((e) => ExpenseItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<void> create(
    String tripRid, {
    required String title,
    required String category,
    required String expenseType,
    required String currency,
    required num amount,
    required String payerRid,
    required String splitType,
    required List<ParticipantInput> participants,
    required String spentAtIso,
    String? itineraryKind,
    String? itineraryRid,
  }) async {
    try {
      await _dio.post<dynamic>('/trips/$tripRid/expenses', data: {
        'title': title,
        'category': category,
        'expenseType': expenseType,
        'currency': currency,
        'amount': amount,
        'payerRid': payerRid,
        'paidFromFund': false,
        'splitType': splitType,
        'participants': participants.map((p) => p.toJson()).toList(),
        'spentAt': spentAtIso,
        if (itineraryRid != null && itineraryRid.isNotEmpty) ...{
          'itineraryKind': itineraryKind,
          'itineraryRid': itineraryRid,
        },
      });
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  /// Updates an expense's metadata only (title, category, type). The backend's
  /// `PATCH /expenses/{rid}` cannot change the money or split — those require
  /// delete + re-create — so this never touches amount/currency/participants.
  Future<void> update(
    String tripRid,
    String expenseRid, {
    required String title,
    required String category,
    required String expenseType,
  }) async {
    try {
      await _dio.patch<dynamic>('/trips/$tripRid/expenses/$expenseRid', data: {
        'title': title,
        'category': category,
        'expenseType': expenseType,
      });
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<void> delete(String tripRid, String expenseRid) async {
    try {
      await _dio.delete<dynamic>('/trips/$tripRid/expenses/$expenseRid');
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }
}

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  return ExpenseRepository(ref.watch(dioProvider));
});
