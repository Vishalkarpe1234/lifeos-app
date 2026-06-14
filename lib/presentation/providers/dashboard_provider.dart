import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/services/api/api_client.dart';

final dashboardSummaryProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get('/api/v1/dashboard/summary');
  return Map<String, dynamic>.from(response.data as Map);
});
