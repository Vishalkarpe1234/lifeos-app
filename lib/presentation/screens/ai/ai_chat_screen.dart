import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/config/theme/app_theme.dart';
import 'package:lifeos/presentation/providers/ai_provider.dart';

class AIChatScreen extends ConsumerStatefulWidget {
  const AIChatScreen({super.key});

  @override
  ConsumerState<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends ConsumerState<AIChatScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _isSending = false;

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  Future<void> _send() async {
    final msg = _msgCtrl.text.trim();
    if (msg.isEmpty || _isSending) return;
    _msgCtrl.clear();
    setState(() => _isSending = true);
    await ref.read(aiChatProvider.notifier).sendMessage(msg);
    setState(() => _isSending = false);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(aiChatProvider);

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), gradient: AppColors.primaryGradient),
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('AI Assistant', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, fontFamily: 'Inter')),
                Text('Claude Sonnet', style: TextStyle(fontSize: 11, color: AppColors.textMuted, fontFamily: 'Inter')),
              ],
            ),
          ],
        ),
        actions: [
          PopupMenuButton(
            icon: const Icon(Icons.more_vert),
            color: AppColors.darkCard,
            itemBuilder: (_) => [
              PopupMenuItem(
                child: const Text('Clear Chat', style: TextStyle(color: Colors.white, fontFamily: 'Inter')),
                onTap: () => ref.read(aiChatProvider.notifier).clearChat(),
              ),
              PopupMenuItem(
                child: const Text('Generate Lecture Plan', style: TextStyle(color: Colors.white, fontFamily: 'Inter')),
                onTap: () => _showQuickPrompt('Generate a detailed lecture plan for topic: '),
              ),
              PopupMenuItem(
                child: const Text('Generate MCQs', style: TextStyle(color: Colors.white, fontFamily: 'Inter')),
                onTap: () => _showQuickPrompt('Generate 10 MCQs on topic: '),
              ),
              PopupMenuItem(
                child: const Text('Write Blog Post', style: TextStyle(color: Colors.white, fontFamily: 'Inter')),
                onTap: () => _showQuickPrompt('Write a professional blog post about: '),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (_, i) => _MessageBubble(message: messages[i]).animate(delay: 50.ms).fadeIn().slideY(begin: 0.1),
                  ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final suggestions = [
      '📚 Create a lecture plan on Machine Learning',
      '🔬 Summarize my latest research paper',
      '✍️ Write a blog post on AI in Education',
      '❓ Generate MCQs on Data Science',
      '📊 Analyze my research gap',
    ];
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), gradient: AppColors.primaryGradient),
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 40),
            ),
            const SizedBox(height: 24),
            const Text('AI Assistant', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white, fontFamily: 'Inter')),
            const SizedBox(height: 8),
            Text('Your intelligent research and teaching companion', style: TextStyle(color: AppColors.textSecondary, fontSize: 14, fontFamily: 'Inter'), textAlign: TextAlign.center),
            const SizedBox(height: 32),
            ...suggestions.map((s) => GestureDetector(
              onTap: () { _msgCtrl.text = s.substring(2).trim(); },
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(color: AppColors.darkCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.darkBorder, width: 0.5)),
                child: Row(
                  children: [
                    Text(s.substring(0, 2), style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Expanded(child: Text(s.substring(2).trim(), style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontFamily: 'Inter'))),
                    Icon(Icons.arrow_forward_ios, color: AppColors.textMuted, size: 12),
                  ],
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        border: Border(top: BorderSide(color: AppColors.darkBorder, width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _msgCtrl,
              maxLines: 4,
              minLines: 1,
              style: const TextStyle(color: Colors.white, fontFamily: 'Inter', fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Ask anything...',
                hintStyle: TextStyle(color: AppColors.textMuted, fontFamily: 'Inter'),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: AppColors.darkBorder, width: 0.5)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: AppColors.darkBorder, width: 0.5)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: AppColors.primary, width: 1.5)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                filled: true, fillColor: AppColors.darkCard,
              ),
              onSubmitted: (_) => _send(),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _send,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44, height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: _isSending ? null : AppColors.primaryGradient,
                color: _isSending ? AppColors.darkCard : null,
              ),
              child: _isSending
                  ? const Padding(padding: EdgeInsets.all(10), child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                  : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  void _showQuickPrompt(String prefix) {
    _msgCtrl.text = prefix;
    _msgCtrl.selection = TextSelection.fromPosition(TextPosition(offset: _msgCtrl.text.length));
  }
}

class _MessageBubble extends StatelessWidget {
  final Map<String, dynamic> message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message['role'] == 'user';
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), gradient: AppColors.primaryGradient),
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: GestureDetector(
              onLongPress: () {
                Clipboard.setData(ClipboardData(text: message['content'].toString()));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied to clipboard')));
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: isUser ? AppColors.primaryGradient : null,
                  color: isUser ? null : AppColors.darkCard,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(isUser ? 18 : 4),
                    topRight: Radius.circular(isUser ? 4 : 18),
                    bottomLeft: const Radius.circular(18),
                    bottomRight: const Radius.circular(18),
                  ),
                  border: isUser ? null : Border.all(color: AppColors.darkBorder, width: 0.5),
                ),
                child: isUser
                    ? Text(message['content'].toString(), style: const TextStyle(color: Colors.white, fontSize: 14, fontFamily: 'Inter', height: 1.5))
                    : MarkdownBody(
                        data: message['content'].toString(),
                        styleSheet: MarkdownStyleSheet(
                          p: const TextStyle(color: AppColors.textPrimary, fontFamily: 'Inter', fontSize: 14, height: 1.6),
                          code: const TextStyle(color: AppColors.accent, backgroundColor: AppColors.darkBg, fontFamily: 'monospace', fontSize: 13),
                          h1: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800, fontFamily: 'Inter'),
                          h2: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700, fontFamily: 'Inter'),
                          h3: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600, fontFamily: 'Inter'),
                          strong: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontFamily: 'Inter'),
                        ),
                      ),
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 10),
        ],
      ),
    );
  }
}
