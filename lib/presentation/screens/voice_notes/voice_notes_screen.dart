import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/config/theme/app_theme.dart';
import 'package:lifeos/services/api/api_client.dart';
import 'package:intl/intl.dart';

final _voiceNotesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  try {
    final dio = ref.watch(dioProvider);
    final res = await dio.get('/api/v1/voice-notes');
    return List<Map<String, dynamic>>.from(res.data as List);
  } catch (_) { return []; }
});

class VoiceNotesScreen extends ConsumerStatefulWidget {
  const VoiceNotesScreen({super.key});

  @override
  ConsumerState<VoiceNotesScreen> createState() => _VoiceNotesScreenState();
}

class _VoiceNotesScreenState extends ConsumerState<VoiceNotesScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..repeat(reverse: true);
  bool _recording = false;
  int _recordingSeconds = 0;

  @override
  void dispose() { _pulseCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final notesAsync = ref.watch(_voiceNotesProvider);
    return Scaffold(
      backgroundColor: AppStyle.bg(context),
      appBar: AppBar(
        backgroundColor: AppStyle.surface(context),
        elevation: 0,
        title: Text('Voice Notes', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w800, color: AppStyle.text(context))),
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Divider(color: AppStyle.border(context), height: 1)),
      ),
      body: Column(
        children: [
          _buildRecordButton(context),
          const Divider(height: 1),
          Expanded(
            child: notesAsync.when(
              data: (notes) => notes.isEmpty ? _buildEmpty(context) : _buildNotesList(context, notes),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => _buildEmpty(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordButton(BuildContext context) {
    return Container(
      color: AppStyle.surface(context),
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          if (_recording) ...[
            Text('Recording... ${_formatDuration(_recordingSeconds)}', style: TextStyle(color: AppColors.error, fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 16),
          ],
          GestureDetector(
            onTap: () => setState(() { _recording = !_recording; if (!_recording) _recordingSeconds = 0; }),
            child: AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (_, child) => Container(
                width: 90, height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: _recording
                        ? [AppColors.error, const Color(0xFFEC4899)]
                        : [AppColors.primary, const Color(0xFF8B5CF6)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (_recording ? AppColors.error : AppColors.primary).withOpacity(_recording ? 0.35 + _pulseCtrl.value * 0.25 : 0.3),
                      blurRadius: _recording ? 30 + _pulseCtrl.value * 15 : 20,
                      spreadRadius: _recording ? _pulseCtrl.value * 8 : 0,
                    ),
                  ],
                ),
                child: Icon(_recording ? Icons.stop_rounded : Icons.mic_rounded, color: Colors.white, size: 40),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(_recording ? 'Tap to stop' : 'Tap to record', style: TextStyle(color: AppStyle.textSub(context), fontFamily: 'Inter', fontSize: 13)),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildNotesList(BuildContext context, List<Map<String, dynamic>> notes) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: notes.length,
      itemBuilder: (_, i) => _VoiceNoteTile(note: notes[i])
          .animate(delay: (40 * i).ms).fadeIn().slideY(begin: 0.05, end: 0),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(width: 80, height: 80, decoration: BoxDecoration(color: const Color(0xFF8B5CF6).withOpacity(0.10), borderRadius: BorderRadius.circular(24)), child: const Icon(Icons.mic_rounded, color: Color(0xFF8B5CF6), size: 40)),
          const SizedBox(height: 16),
          Text('No Voice Notes', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppStyle.text(context), fontFamily: 'Inter')),
          const SizedBox(height: 8),
          Text('Record your thoughts and ideas', style: TextStyle(color: AppStyle.textSub(context), fontFamily: 'Inter')),
        ],
      ),
    );
  }

  String _formatDuration(int s) => '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';
}

class _VoiceNoteTile extends StatefulWidget {
  final Map<String, dynamic> note;
  const _VoiceNoteTile({required this.note});

  @override
  State<_VoiceNoteTile> createState() => _VoiceNoteTileState();
}

class _VoiceNoteTileState extends State<_VoiceNoteTile> {
  bool _playing = false;

  @override
  Widget build(BuildContext context) {
    final duration = widget.note['duration'] as int? ?? 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: AppStyle.cardDecor(context, accent: const Color(0xFF8B5CF6)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => setState(() => _playing = !_playing),
                child: Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)]),
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: const Color(0xFF8B5CF6).withOpacity(0.3), blurRadius: 10)],
                  ),
                  child: Icon(_playing ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.white, size: 24),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.note['title'] ?? 'Voice Note', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppStyle.text(context), fontFamily: 'Inter')),
                    const SizedBox(height: 2),
                    Text(_formatDuration(duration), style: TextStyle(fontSize: 12, color: AppStyle.textMuted(context), fontFamily: 'Inter')),
                  ],
                ),
              ),
              Text(_formatDate(widget.note['created_at'] ?? ''), style: TextStyle(fontSize: 11, color: AppStyle.textMuted(context), fontFamily: 'Inter')),
            ],
          ),
          if (widget.note['transcript'] != null && (widget.note['transcript'] as String).isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: const Color(0xFF8B5CF6).withOpacity(0.06), borderRadius: BorderRadius.circular(10)),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome_rounded, color: Color(0xFF8B5CF6), size: 14),
                  const SizedBox(width: 6),
                  Expanded(child: Text(widget.note['transcript'], style: TextStyle(fontSize: 12, color: AppStyle.textSub(context), fontFamily: 'Inter', height: 1.4), maxLines: 3, overflow: TextOverflow.ellipsis)),
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: _playing ? 0.4 : 0,
              backgroundColor: AppStyle.border(context),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF8B5CF6)),
              minHeight: 3,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(int s) => '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';
  String _formatDate(String iso) { try { return DateFormat('MMM d').format(DateTime.parse(iso)); } catch (_) { return ''; } }
}
