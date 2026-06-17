import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:lifeos/core/constants/app_constants.dart';
import 'package:lifeos/services/api/api_client.dart';

class ConnectService {
  final Dio _dio;
  ConnectService(this._dio);

  Future<Map<String, dynamic>> getProfile() async {
    final r = await _dio.get('/api/v1/connect/profile');
    return Map<String, dynamic>.from(r.data);
  }

  Future<void> updateProfile({String? username, String? bio}) async {
    await _dio.patch('/api/v1/connect/profile', data: {
      if (username != null) 'username': username,
      if (bio != null) 'bio': bio,
    });
  }

  Future<List<Map<String, dynamic>>> search(String q) async {
    final r = await _dio.get('/api/v1/connect/search', queryParameters: {'q': q});
    return List<Map<String, dynamic>>.from(r.data['items']);
  }

  Future<void> sendFriendRequest(String username) async {
    await _dio.post('/api/v1/connect/friend-requests', data: {'username': username});
  }

  Future<Map<String, dynamic>> listFriendRequests() async {
    final r = await _dio.get('/api/v1/connect/friend-requests');
    return Map<String, dynamic>.from(r.data);
  }

  Future<void> respondFriendRequest(int id, String action) async {
    await _dio.post('/api/v1/connect/friend-requests/$id/respond', data: {'action': action});
  }

  Future<List<Map<String, dynamic>>> listFriends() async {
    final r = await _dio.get('/api/v1/connect/friends');
    return List<Map<String, dynamic>>.from(r.data['items']);
  }

  Future<void> removeFriend(int friendId) async {
    await _dio.delete('/api/v1/connect/friends/$friendId');
  }

  Future<List<Map<String, dynamic>>> getMessages(int friendId) async {
    final r = await _dio.get('/api/v1/connect/messages/$friendId');
    return List<Map<String, dynamic>>.from(r.data['items']);
  }

  Future<void> deleteChatHistory(int friendId) async {
    await _dio.delete('/api/v1/connect/messages/$friendId');
  }

  Future<void> markRead(int friendId) async {
    await _dio.post('/api/v1/connect/messages/$friendId/read');
  }

  Future<Map<String, dynamic>> getNotifications() async {
    final r = await _dio.get('/api/v1/connect/notifications');
    return Map<String, dynamic>.from(r.data);
  }

  Future<Map<String, dynamic>> uploadChatFile(String filePath) async {
    final form = FormData.fromMap({'file': await MultipartFile.fromFile(filePath, filename: filePath.split('/').last)});
    final r = await _dio.post('/api/v1/connect/upload', data: form,
      options: Options(contentType: 'multipart/form-data'));
    return Map<String, dynamic>.from(r.data);
  }
}

final connectServiceProvider = Provider<ConnectService>((ref) => ConnectService(ref.watch(dioProvider)));

final currentUserIdProvider = FutureProvider<int>((ref) async {
  final r = await ref.watch(dioProvider).get('/api/v1/auth/me');
  return r.data['id'] as int;
});

class ChatMessage {
  final int id;
  final int senderId;
  final int receiverId;
  final String? content;
  final String? fileUrl;
  final String? fileType;
  final String? timestamp;
  final bool isRead;
  ChatMessage({required this.id, required this.senderId, required this.receiverId, this.content, this.fileUrl, this.fileType, this.timestamp, this.isRead = false});

  factory ChatMessage.fromJson(Map<String, dynamic> j) => ChatMessage(
    id: j['id'], senderId: j['sender_id'], receiverId: j['receiver_id'],
    content: j['content'], fileUrl: j['file_url'], fileType: j['file_type'], timestamp: j['timestamp']?.toString(),
    isRead: j['is_read'] == true,
  );
}

class ChatState {
  final List<ChatMessage> messages;
  final bool loading;
  final bool connected;
  ChatState({this.messages = const [], this.loading = true, this.connected = false});
  ChatState copyWith({List<ChatMessage>? messages, bool? loading, bool? connected}) =>
    ChatState(messages: messages ?? this.messages, loading: loading ?? this.loading, connected: connected ?? this.connected);
}

class ChatController extends StateNotifier<ChatState> {
  final ConnectService _service;
  final int friendId;
  final int myUserId;
  WebSocketChannel? _channel;
  final _storage = const FlutterSecureStorage();

  ChatController(this._service, this.friendId, this.myUserId) : super(ChatState()) {
    _init();
  }

  Future<void> _init() async {
    try {
      final history = await _service.getMessages(friendId);
      state = state.copyWith(messages: history.map(ChatMessage.fromJson).toList(), loading: false);
    } catch (_) {
      state = state.copyWith(loading: false);
    }
    try { await _service.markRead(friendId); } catch (_) {}
    await _connect();
  }

  Future<void> _connect() async {
    final token = await _storage.read(key: AppConstants.keyToken);
    if (token == null) return;
    final base = AppConstants.baseUrl.replaceFirst('https://', 'wss://').replaceFirst('http://', 'ws://');
    final uri = Uri.parse('$base/api/v1/connect/ws?token=$token');
    try {
      _channel = WebSocketChannel.connect(uri);
      await _channel!.ready.timeout(const Duration(seconds: 12));
      state = state.copyWith(connected: true);
      _channel!.stream.listen((event) {
        try {
          final data = jsonDecode(event as String) as Map<String, dynamic>;
          if (data['type'] == 'message') {
            final msg = ChatMessage.fromJson(Map<String, dynamic>.from(data['message']));
            if (msg.senderId == friendId || msg.receiverId == friendId) {
              state = state.copyWith(messages: [...state.messages, msg]);
              if (msg.senderId == friendId) {
                _service.markRead(friendId).catchError((_) {});
              }
            }
          }
        } catch (_) {}
      }, onDone: () {
        state = state.copyWith(connected: false);
      }, onError: (_) {
        state = state.copyWith(connected: false);
      });
    } catch (_) {
      state = state.copyWith(connected: false);
    }
  }

  void sendMessage(String content) {
    final channel = _channel;
    if (channel == null) return;
    channel.sink.add(jsonEncode({'type': 'message', 'to': friendId, 'content': content}));
  }

  Future<void> sendFile(String filePath) async {
    final result = await _service.uploadChatFile(filePath);
    final channel = _channel;
    if (channel == null) return;
    channel.sink.add(jsonEncode({
      'type': 'message',
      'to': friendId,
      'file_url': result['file_url'],
      'file_type': result['file_type'],
    }));
  }

  Future<void> deleteHistory() async {
    await _service.deleteChatHistory(friendId);
    state = state.copyWith(messages: []);
  }

  @override
  void dispose() {
    _channel?.sink.close();
    super.dispose();
  }
}

final chatControllerProvider = StateNotifierProvider.family<ChatController, ChatState, ({int friendId, int myUserId})>(
  (ref, args) => ChatController(ref.watch(connectServiceProvider), args.friendId, args.myUserId),
);

final connectNotificationsProvider = StreamProvider.autoDispose<Map<String, dynamic>>((ref) async* {
  final service = ref.watch(connectServiceProvider);
  while (true) {
    try {
      yield await service.getNotifications().timeout(const Duration(seconds: 10));
    } catch (_) {
      yield const {'pending_requests': 0, 'unread_messages': 0, 'unread_by_friend': {}};
    }
    await Future.delayed(const Duration(seconds: 45));
  }
});
