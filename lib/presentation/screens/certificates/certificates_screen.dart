import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/config/theme/app_theme.dart';
import 'package:lifeos/presentation/widgets/animations/shimmer_loading.dart';
import 'package:lifeos/presentation/widgets/common/glass_card.dart';
import 'package:lifeos/services/api/api_client.dart';
import 'package:url_launcher/url_launcher.dart';

class CertificatesScreen extends ConsumerWidget {
  const CertificatesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_certsProvider);

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        title: const Text('Certificates', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700)),
        actions: [IconButton(icon: const Icon(Icons.add), onPressed: () {})],
      ),
      body: async.when(
        data: (certs) => certs.isEmpty
            ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.workspace_premium_outlined, size: 60, color: AppColors.textMuted), const SizedBox(height: 16), Text('No certificates', style: TextStyle(color: AppColors.textSecondary, fontFamily: 'Inter'))]))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: certs.length,
                itemBuilder: (_, i) => _CertCard(cert: certs[i]).animate(delay: (40 * i).ms).fadeIn().slideX(begin: 0.05),
              ),
        loading: () => const ShimmerLoading(count: 6),
        error: (e, _) => Center(child: Text(e.toString())),
      ),
    );
  }
}

class _CertCard extends StatelessWidget {
  final Map<String, dynamic> cert;
  const _CertCard({required this.cert});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 50, height: 50,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [const Color(0xFF8B5CF6), AppColors.primary], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.workspace_premium, color: Colors.white, size: 26),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(cert['title'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontFamily: 'Inter', fontSize: 14, height: 1.3), maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          if (cert['issuing_organization'] != null) Text(cert['issuing_organization'].toString(), style: TextStyle(color: AppColors.primary, fontSize: 12, fontFamily: 'Inter', fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Row(children: [
            if (cert['issue_date'] != null) ...[Icon(Icons.calendar_today_outlined, size: 11, color: AppColors.textMuted), const SizedBox(width: 3), Text(cert['issue_date'].toString(), style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontFamily: 'Inter')), const SizedBox(width: 8)],
            if (cert['credential_url'] != null)
              GestureDetector(
                onTap: () async {
                  final uri = Uri.parse(cert['credential_url'].toString());
                  if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
                },
                child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: AppColors.success.withOpacity(0.12), borderRadius: BorderRadius.circular(6), border: Border.all(color: AppColors.success.withOpacity(0.3))), child: const Text('Verify', style: TextStyle(color: AppColors.success, fontSize: 10, fontFamily: 'Inter', fontWeight: FontWeight.w500))),
              ),
          ]),
        ])),
        if (cert['is_featured'] == true) const Icon(Icons.star, color: AppColors.warning, size: 16),
      ]),
    );
  }
}

final _certsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final dio = ref.watch(dioProvider);
  final r = await dio.get('/api/v1/certificates/', queryParameters: {'page_size': 100});
  return (r.data['items'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
});
