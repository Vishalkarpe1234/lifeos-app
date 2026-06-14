import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/services/api/api_client.dart';

class AIChatNotifier extends StateNotifier<List<Map<String, dynamic>>> {
  final Ref ref;
  int? _chatId;

  AIChatNotifier(this.ref) : super([]);

  Future<void> sendMessage(String content) async {
    state = [...state, {'role': 'user', 'content': content}];
    try {
      final dio = ref.read(dioProvider);
      final r = await dio.post('/api/v1/ai/chat', data: {
        'message': content,
        if (_chatId != null) 'chat_id': _chatId,
        'model': 'claude-sonnet-4-6',
      });
      _chatId = r.data['chat_id'] as int?;
      state = [...state, {'role': 'assistant', 'content': r.data['response']}];
    } catch (e) {
      state = [...state, {'role': 'assistant', 'content': 'Sorry, I encountered an error: ${e.toString()}. Please ensure the AI API key is configured.'}];
    }
  }

  void clearChat() {
    state = [];
    _chatId = null;
  }
}

final aiChatProvider = StateNotifierProvider<AIChatNotifier, List<Map<String, dynamic>>>((ref) => AIChatNotifier(ref));
