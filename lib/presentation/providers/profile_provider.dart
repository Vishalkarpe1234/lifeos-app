import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/data/models/profile_model.dart';
import 'package:lifeos/services/api/api_client.dart';

final profileProvider = FutureProvider<ProfileModel?>((ref) async {
  final dio = ref.watch(dioProvider);
  try {
    final response = await dio.get('/api/v1/profile/');
    return ProfileModel.fromJson(response.data as Map<String, dynamic>);
  } catch (_) {
    return null;
  }
});
