import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lifeos/config/theme/app_theme.dart';
import 'package:lifeos/presentation/providers/connect_provider.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final int friendId;
  final Map<String, dynamic>? friend;
  const ChatScreen({super.key, required this.friendId, this.friend});

  @override
  ConsumerState<ChatScreen> createState() => _ChatState();
}

class _ChatState extends ConsumerState<ChatScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();

  @override
  void dispose() { _input.dispose(); _scroll.dispose(); super.dispose(); }

  void _send(int myUserId) {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    ref.read(chatControllerProvider((friendId: widget.friendId, myUserId: myUserId)).notifier).sendMessage(text);
    _input.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
    });
  }

  Future<void> _confirmDeleteHistory(int myUserId) async {
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      title: const Text('Delete Chat History', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700)),
      content: const Text('This deletes the chat history from your view only. Your friend will still see their copy.', style: TextStyle(fontFamily: 'Inter', color: C.textSub)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: C.error), onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
      ],
    ));
    if (ok == true) {
      await ref.read(chatControllerProvider((friendId: widget.friendId, myUserId: myUserId)).notifier).deleteHistory();
    }
  }

  @override
  Widget build(BuildContext context) {
    final userIdAsync = ref.watch(currentUserIdProvider);
    return userIdAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (myUserId) {
        final args = (friendId: widget.friendId, myUserId: myUserId);
        final chat = ref.watch(chatControllerProvider(args));

        ref.listen(chatControllerProvider(args), (prev, next) {
          if (prev != null && next.messages.length > prev.messages.length) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_scroll.hasClients) _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
            });
          }
        });

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18), onPressed: () => context.pop()),
            title: Row(children: [
              CircleAvatar(radius: 16, backgroundColor: C.primary.withOpacity(0.12),
                child: Text((widget.friend?['username'] ?? '?')[0].toString().toUpperCase(), style: const TextStyle(color: C.primary, fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 13))),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Text('@${widget.friend?['username'] ?? ''}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, fontFamily: 'Inter')),
                Text(chat.connected ? 'Online' : 'Connecting...', style: TextStyle(fontSize: 11, color: chat.connected ? C.success : C.textMuted, fontFamily: 'Inter')),
              ])),
            ]),
            actions: [
              IconButton(icon: const Icon(Icons.delete_outline_rounded, color: C.error), onPressed: () => _confirmDeleteHistory(myUserId)),
            ],
          ),
          body: Column(children: [
            Expanded(child: chat.loading
              ? const Center(child: CircularProgressIndicator())
              : chat.messages.isEmpty
                ? const Center(child: Text('No messages yet. Say hi!', style: TextStyle(color: C.textSub, fontFamily: 'Inter')))
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.all(16),
                    itemCount: chat.messages.length,
                    itemBuilder: (_, i) {
                      final m = chat.messages[i];
                      final mine = m.senderId == myUserId;
                      return Align(
                        alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                          decoration: BoxDecoration(
                            color: mine ? C.primary : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: mine ? null : Border.all(color: C.border),
                          ),
                          child: Text(m.content ?? '', style: TextStyle(color: mine ? Colors.white : C.text, fontFamily: 'Inter', fontSize: 14)),
                        ),
                      );
                    },
                  )),
            SafeArea(child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(children: [
                Expanded(child: TextField(
                  controller: _input,
                  decoration: const InputDecoration(hintText: 'Message...', contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                  onSubmitted: (_) => _send(myUserId),
                  textInputAction: TextInputAction.send,
                )),
                const SizedBox(width: 8),
                Container(decoration: const BoxDecoration(color: C.primary, shape: BoxShape.circle),
                  child: IconButton(icon: const Icon(Icons.send_rounded, color: Colors.white), onPressed: () => _send(myUserId))),
              ]),
            )),
          ]),
        );
      },
    );
  }
}
