import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_client.dart';

/// A checklist item (backend `ChecklistItemResponse`).
class ChecklistItem {
  const ChecklistItem(
      {required this.rid, required this.title, required this.completed});

  final String rid;
  final String title;
  final bool completed;

  factory ChecklistItem.fromJson(Map<String, dynamic> json) => ChecklistItem(
        rid: json['rid'] as String,
        title: json['title'] as String? ?? '',
        completed: json['completed'] as bool? ?? false,
      );
}

class ChecklistRepository {
  ChecklistRepository(this._dio);

  final Dio _dio;

  Future<List<ChecklistItem>> list(String tripRid) async {
    try {
      final Response<dynamic> res =
          await _dio.get<dynamic>('/trips/$tripRid/checklist');
      final List<dynamic> data = (res.data as Map)['data'] as List<dynamic>;
      return data
          .map((e) => ChecklistItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<void> create(String tripRid, String title) async {
    try {
      await _dio
          .post<dynamic>('/trips/$tripRid/checklist', data: {'title': title});
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<void> setCompleted(
      String tripRid, String itemRid, bool completed) async {
    try {
      await _dio.patch<dynamic>('/trips/$tripRid/checklist/$itemRid',
          data: {'completed': completed});
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<void> rename(String tripRid, String itemRid, String title) async {
    try {
      await _dio.patch<dynamic>('/trips/$tripRid/checklist/$itemRid',
          data: {'title': title});
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<void> delete(String tripRid, String itemRid) async {
    try {
      await _dio.delete<dynamic>('/trips/$tripRid/checklist/$itemRid');
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }
}

final checklistRepositoryProvider = Provider<ChecklistRepository>((ref) {
  return ChecklistRepository(ref.watch(dioProvider));
});
