import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/config/theme/app_theme.dart';
import 'package:lifeos/services/api/api_client.dart';

final _contactsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  try {
    final dio = ref.watch(dioProvider);
    final res = await dio.get('/api/v1/contacts');
    return List<Map<String, dynamic>>.from(res.data as List);
  } catch (_) { return []; }
});

class ContactsScreen extends ConsumerStatefulWidget {
  const ContactsScreen({super.key});

  @override
  ConsumerState<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends ConsumerState<ContactsScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final contactsAsync = ref.watch(_contactsProvider);
    return Scaffold(
      backgroundColor: AppStyle.bg(context),
      appBar: AppBar(
        backgroundColor: AppStyle.surface(context),
        elevation: 0,
        title: Text('Contacts', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w800, color: AppStyle.text(context))),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v.toLowerCase()),
              style: TextStyle(color: AppStyle.text(context), fontFamily: 'Inter', fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search contacts...',
                hintStyle: TextStyle(color: AppStyle.textMuted(context), fontFamily: 'Inter'),
                prefixIcon: Icon(Icons.search_rounded, color: AppStyle.textMuted(context), size: 20),
                filled: true, fillColor: AppStyle.card(context),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
            ),
          ),
        ),
      ),
      body: contactsAsync.when(
        data: (contacts) {
          final filtered = contacts.where((c) {
            if (_query.isEmpty) return true;
            return (c['full_name'] as String? ?? '').toLowerCase().contains(_query) ||
                   (c['email'] as String? ?? '').toLowerCase().contains(_query);
          }).toList();
          if (filtered.isEmpty) return _buildEmpty(context);
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: filtered.length,
            itemBuilder: (_, i) => _ContactTile(contact: filtered[i], onDelete: () {
              ref.invalidate(_contactsProvider);
            }),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _buildEmpty(context),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddContact(context),
        backgroundColor: const Color(0xFF06B6D4),
        child: const Icon(Icons.person_add_rounded, color: Colors.white),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(width: 80, height: 80, decoration: BoxDecoration(color: const Color(0xFF06B6D4).withOpacity(0.10), borderRadius: BorderRadius.circular(24)), child: const Icon(Icons.contacts_rounded, color: Color(0xFF06B6D4), size: 40)),
          const SizedBox(height: 16),
          Text('No Contacts', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppStyle.text(context), fontFamily: 'Inter')),
          const SizedBox(height: 8),
          Text('Add your important contacts', style: TextStyle(color: AppStyle.textSub(context), fontFamily: 'Inter')),
        ],
      ),
    );
  }

  void _showAddContact(BuildContext context) {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final companyCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppStyle.card(context),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 20, right: 20, top: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('New Contact', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppStyle.text(context), fontFamily: 'Inter')),
            const SizedBox(height: 16),
            _field(ctx, nameCtrl, 'Full Name', Icons.person_outline),
            const SizedBox(height: 12),
            _field(ctx, emailCtrl, 'Email', Icons.email_outlined, type: TextInputType.emailAddress),
            const SizedBox(height: 12),
            _field(ctx, phoneCtrl, 'Phone', Icons.phone_outlined, type: TextInputType.phone),
            const SizedBox(height: 12),
            _field(ctx, companyCtrl, 'Company', Icons.business_outlined),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity, height: 52,
              child: ElevatedButton(
                onPressed: () async {
                  if (nameCtrl.text.isEmpty) return;
                  try {
                    final dio = ref.read(dioProvider);
                    await dio.post('/api/v1/contacts', data: {
                      'full_name': nameCtrl.text,
                      if (emailCtrl.text.isNotEmpty) 'email': emailCtrl.text,
                      if (phoneCtrl.text.isNotEmpty) 'phone': phoneCtrl.text,
                      if (companyCtrl.text.isNotEmpty) 'company': companyCtrl.text,
                    });
                    ref.invalidate(_contactsProvider);
                    if (ctx.mounted) Navigator.pop(ctx);
                  } catch (_) {}
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF06B6D4), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0),
                child: const Text('Add Contact', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _field(BuildContext ctx, TextEditingController ctrl, String label, IconData icon, {TextInputType? type}) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      style: TextStyle(color: AppStyle.text(ctx), fontFamily: 'Inter'),
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon, color: AppStyle.textMuted(ctx), size: 20), filled: true, fillColor: AppStyle.surface(ctx), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppStyle.border(ctx))), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppStyle.border(ctx))), labelStyle: TextStyle(color: AppStyle.textSub(ctx), fontFamily: 'Inter')),
    );
  }
}

class _ContactTile extends StatelessWidget {
  final Map<String, dynamic> contact;
  final VoidCallback onDelete;
  const _ContactTile({required this.contact, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final name = contact['full_name'] as String? ?? '';
    final initials = name.split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase();
    final colors = [const Color(0xFF6366F1), const Color(0xFF8B5CF6), const Color(0xFF06B6D4), const Color(0xFF10B981), const Color(0xFFF59E0B)];
    final color = colors[name.hashCode.abs() % colors.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: AppStyle.cardDecor(context, radius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
            child: Center(child: Text(initials, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: color, fontFamily: 'Inter'))),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppStyle.text(context), fontFamily: 'Inter')),
                if (contact['email'] != null || contact['phone'] != null)
                  Text(contact['email'] ?? contact['phone'] ?? '', style: TextStyle(fontSize: 12, color: AppStyle.textSub(context), fontFamily: 'Inter')),
                if (contact['company'] != null)
                  Text(contact['company'], style: TextStyle(fontSize: 11, color: AppStyle.textMuted(context), fontFamily: 'Inter')),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: AppStyle.textMuted(context)),
        ],
      ),
    );
  }
}
