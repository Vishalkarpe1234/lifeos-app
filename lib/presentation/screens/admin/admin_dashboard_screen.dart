import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:lifeos/config/theme/app_theme.dart';
import 'package:lifeos/services/api/api_client.dart';
import 'package:lifeos/presentation/providers/profile_provider.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  bool _uploadingPhoto = false;
  bool _uploadingCover = false;

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);
    final overviewAsync = ref.watch(_adminOverviewProvider);

    return Scaffold(
      backgroundColor: AppStyle.bg(context),
      appBar: AppBar(
        backgroundColor: AppStyle.surface(context),
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Text('Admin Panel', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w800, color: AppStyle.text(context), fontSize: 18)),
          ],
        ),
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Divider(color: AppStyle.border(context), height: 1)),
        actions: [
          IconButton(
            icon: Icon(Icons.dashboard_rounded, color: AppStyle.textSub(context)),
            tooltip: 'User Dashboard',
            onPressed: () => context.go('/dashboard'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Photo Upload Card ────────────────────────────────────
            _buildPhotoUploadCard(context, profileAsync),
            const SizedBox(height: 20),

            // ── Stats ────────────────────────────────────────────────
            _buildLabel(context, 'Overview'),
            const SizedBox(height: 12),
            overviewAsync.when(
              data: (d) => _buildStatsGrid(context, d),
              loading: () => const SizedBox(height: 120, child: Center(child: CircularProgressIndicator())),
              error: (_, __) => const SizedBox(),
            ),
            const SizedBox(height: 20),

            // ── Content Management ───────────────────────────────────
            _buildLabel(context, 'Content Management'),
            const SizedBox(height: 12),
            _buildAdminGrid(context),
            const SizedBox(height: 20),

            // ── System ───────────────────────────────────────────────
            _buildLabel(context, 'System'),
            const SizedBox(height: 12),
            _buildSystemGrid(context),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoUploadCard(BuildContext context, AsyncValue profileAsync) {
    final photoUrl = profileAsync.asData?.value?.profilePhotoUrl;

    return Container(
      decoration: AppStyle.cardDecor(context),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.photo_camera_rounded, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text('Profile Photos', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppStyle.text(context), fontFamily: 'Inter')),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Profile photo
              Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 80, height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppColors.primaryGradient,
                          boxShadow: AppStyle.accentShadow(context, AppColors.primary),
                        ),
                        child: photoUrl != null
                            ? ClipOval(child: Image.network(photoUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.person, color: Colors.white, size: 36)))
                            : const Icon(Icons.person_rounded, color: Colors.white, size: 36),
                      ),
                      if (_uploadingPhoto)
                        Positioned.fill(child: Container(
                          decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0x80000000)),
                          child: const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))),
                        )),
                    ],
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _uploadingPhoto ? null : () => _pickAndUpload(context, 'photo'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.primary.withOpacity(0.25)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.upload_rounded, size: 14, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text('Photo', style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600, fontFamily: 'Inter')),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 20),
              // Cover image info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Profile & Cover', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppStyle.text(context), fontFamily: 'Inter')),
                    const SizedBox(height: 4),
                    Text('Tap buttons to upload. Supports JPG, PNG, WebP.', style: TextStyle(fontSize: 12, color: AppStyle.textMuted(context), fontFamily: 'Inter')),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: _uploadingCover ? null : () => _pickAndUpload(context, 'cover'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.accent.withOpacity(0.25)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_uploadingCover)
                              const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent))
                            else
                              Icon(Icons.wallpaper_rounded, size: 14, color: AppColors.accent),
                            const SizedBox(width: 6),
                            Text('Upload Cover Image', style: TextStyle(fontSize: 12, color: AppColors.accent, fontWeight: FontWeight.w600, fontFamily: 'Inter')),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0);
  }

  Future<void> _pickAndUpload(BuildContext context, String type) async {
    final picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85, maxWidth: 1200);
    if (img == null) return;

    setState(() {
      if (type == 'photo') _uploadingPhoto = true;
      else _uploadingCover = true;
    });

    try {
      final dio = ref.read(dioProvider);
      final file = await MultipartFile.fromFile(img.path, filename: img.name);
      final form = FormData.fromMap({'file': file});
      final endpoint = type == 'photo' ? '/api/v1/profile/photo' : '/api/v1/profile/cover';
      await dio.post(endpoint, data: form);

      ref.invalidate(profileProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(type == 'photo' ? 'Profile photo updated!' : 'Cover image updated!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() { _uploadingPhoto = false; _uploadingCover = false; });
    }
  }

  Widget _buildLabel(BuildContext context, String text) {
    return Text(text, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppStyle.text(context), fontFamily: 'Inter'));
  }

  Widget _buildStatsGrid(BuildContext context, Map<String, dynamic> data) {
    final items = [
      _Stat('Tasks',    '${data['tasks']}',        AppColors.primary,            Icons.task_alt_rounded),
      _Stat('Notes',    '${data['notes']}',         AppColors.accent,             Icons.sticky_note_2_rounded),
      _Stat('Papers',   '${data['publications']}',  AppColors.success,            Icons.article_rounded),
      _Stat('Projects', '${data['projects']}',      AppColors.warning,            Icons.folder_rounded),
      _Stat('Certs',    '${data['certificates']}',  const Color(0xFF8B5CF6),      Icons.workspace_premium_rounded),
      _Stat('Files',    '${data['media_files']}',   AppColors.info,               Icons.perm_media_rounded),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 1.15),
      itemCount: items.length,
      itemBuilder: (_, i) => _StatCard(stat: items[i]).animate(delay: (30 * i).ms).fadeIn().scale(begin: const Offset(0.9, 0.9)),
    );
  }

  Widget _buildAdminGrid(BuildContext context) {
    final sections = [
      _Section(Icons.person_rounded,             'Profile',      'Personal info & photos',     AppColors.primary,           '/profile'),
      _Section(Icons.science_rounded,            'Research',     'Publications & conferences',  AppColors.success,           '/research'),
      _Section(Icons.school_rounded,             'Teaching',     'Subjects & lectures',         AppColors.accent,            '/teaching'),
      _Section(Icons.folder_rounded,             'Projects',     'Portfolio projects',          AppColors.warning,           '/projects'),
      _Section(Icons.workspace_premium_rounded,  'Certificates', 'Certifications',              const Color(0xFF8B5CF6),     '/certificates'),
      _Section(Icons.perm_media_rounded,         'Media',        'Files & images',              AppColors.info,              '/media'),
      _Section(Icons.account_balance_wallet_rounded, 'Finance',  'Expenses & budget',           AppColors.error,             '/finance'),
      _Section(Icons.loop_rounded,               'Habits',       'Daily habits tracker',        AppColors.success,           '/habits'),
      _Section(Icons.auto_stories_rounded,       'Journal',      'Daily journal',               AppColors.primary,           '/journal'),
      _Section(Icons.bookmark_rounded,           'Bookmarks',    'Saved links',                 AppColors.warning,           '/bookmarks'),
      _Section(Icons.sticky_note_2_rounded,      'Notes',        'All notes',                   AppColors.accent,            '/notes'),
      _Section(Icons.settings_rounded,           'Settings',     'App configuration',           AppColors.lightTextSub,      '/settings'),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 2.3),
      itemCount: sections.length,
      itemBuilder: (_, i) => _SectionTile(section: sections[i]).animate(delay: (25 * i).ms).fadeIn().scale(begin: const Offset(0.95, 0.95)),
    );
  }

  Widget _buildSystemGrid(BuildContext context) {
    final items = [
      _Section(Icons.analytics_rounded,  'Analytics',  'Activity & usage logs', AppColors.primary,  '/admin'),
      _Section(Icons.people_rounded,     'Users',      'User management',       AppColors.accent,   '/admin'),
      _Section(Icons.auto_awesome_rounded, 'AI',       'Chat history',          const Color(0xFF8B5CF6), '/ai'),
      _Section(Icons.dashboard_rounded,  'Dashboard',  'Go to user view',       AppColors.success,  '/dashboard'),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 2.3),
      itemCount: items.length,
      itemBuilder: (_, i) => _SectionTile(section: items[i]),
    );
  }
}

// ── Providers ──────────────────────────────────────────────────────────────
final _adminOverviewProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final dio = ref.watch(dioProvider);
  final r = await dio.get('/api/v1/admin/analytics/overview');
  return Map<String, dynamic>.from(r.data as Map);
});

// ── Sub-widgets ────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final _Stat stat;
  const _StatCard({required this.stat});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: AppStyle.cardDecor(context, accent: stat.color, radius: BorderRadius.circular(14)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(stat.icon, color: stat.color, size: 22),
          const SizedBox(height: 6),
          Text(stat.value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppStyle.text(context), fontFamily: 'Inter')),
          Text(stat.label, style: TextStyle(fontSize: 10, color: AppStyle.textMuted(context), fontFamily: 'Inter')),
        ],
      ),
    );
  }
}

class _SectionTile extends StatelessWidget {
  final _Section section;
  const _SectionTile({required this.section});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go(section.path),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: AppStyle.cardDecor(context, accent: section.color, radius: BorderRadius.circular(14)),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: section.color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
              child: Icon(section.icon, color: section.color, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(section.title, style: TextStyle(color: AppStyle.text(context), fontSize: 13, fontWeight: FontWeight.w700, fontFamily: 'Inter'), maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(section.subtitle, style: TextStyle(color: AppStyle.textMuted(context), fontSize: 10, fontFamily: 'Inter'), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppStyle.textMuted(context), size: 16),
          ],
        ),
      ),
    );
  }
}

class _Stat    { final String label, value; final Color color; final IconData icon; const _Stat(this.label, this.value, this.color, this.icon); }
class _Section { final IconData icon; final String title, subtitle, path; final Color color; const _Section(this.icon, this.title, this.subtitle, this.color, this.path); }
