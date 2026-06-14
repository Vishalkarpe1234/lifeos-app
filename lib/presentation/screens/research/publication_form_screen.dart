import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lifeos/config/theme/app_theme.dart';
import 'package:lifeos/presentation/providers/research_provider.dart';
import 'package:lifeos/presentation/widgets/common/loading_button.dart';

class PublicationFormScreen extends ConsumerStatefulWidget {
  final int? publicationId;
  const PublicationFormScreen({super.key, this.publicationId});

  @override
  ConsumerState<PublicationFormScreen> createState() => _PublicationFormScreenState();
}

class _PublicationFormScreenState extends ConsumerState<PublicationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _abstractCtrl = TextEditingController();
  final _journalCtrl = TextEditingController();
  final _doiCtrl = TextEditingController();
  final _yearCtrl = TextEditingController();
  final _authorsCtrl = TextEditingController();
  String _pubType = 'journal';
  bool _isIndexed = false;
  String _indexType = '';
  bool _isFeatured = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _abstractCtrl.dispose();
    _journalCtrl.dispose();
    _doiCtrl.dispose();
    _yearCtrl.dispose();
    _authorsCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    await ref.read(publicationsProvider.notifier).create({
      'title': _titleCtrl.text,
      'abstract': _abstractCtrl.text,
      'authors': _authorsCtrl.text.split(',').map((e) => e.trim()).toList(),
      if (_pubType == 'journal') 'journal_name': _journalCtrl.text,
      if (_pubType == 'conference') 'conference_name': _journalCtrl.text,
      'doi': _doiCtrl.text,
      'year': int.tryParse(_yearCtrl.text),
      'pub_type': _pubType,
      'is_indexed': _isIndexed,
      'index_type': _indexType,
      'is_featured': _isFeatured,
      'status': 'published',
    });
    setState(() => _isSaving = false);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(title: const Text('Add Publication', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(controller: _titleCtrl, style: const TextStyle(color: Colors.white, fontFamily: 'Inter'), decoration: const InputDecoration(labelText: 'Title *'), validator: (v) => v?.isEmpty ?? true ? 'Required' : null, maxLines: 3),
              const SizedBox(height: 16),
              TextFormField(controller: _authorsCtrl, style: const TextStyle(color: Colors.white, fontFamily: 'Inter'), decoration: const InputDecoration(labelText: 'Authors (comma separated)')),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _pubType,
                style: const TextStyle(color: Colors.white, fontFamily: 'Inter'),
                dropdownColor: AppColors.darkCard,
                decoration: const InputDecoration(labelText: 'Publication Type'),
                items: ['journal', 'conference', 'book_chapter', 'thesis'].map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(color: Colors.white)))).toList(),
                onChanged: (v) => setState(() => _pubType = v!),
              ),
              const SizedBox(height: 16),
              TextFormField(controller: _journalCtrl, style: const TextStyle(color: Colors.white, fontFamily: 'Inter'), decoration: InputDecoration(labelText: _pubType == 'conference' ? 'Conference Name' : 'Journal Name')),
              const SizedBox(height: 16),
              TextFormField(controller: _doiCtrl, style: const TextStyle(color: Colors.white, fontFamily: 'Inter'), decoration: const InputDecoration(labelText: 'DOI')),
              const SizedBox(height: 16),
              TextFormField(controller: _yearCtrl, style: const TextStyle(color: Colors.white, fontFamily: 'Inter'), decoration: const InputDecoration(labelText: 'Year'), keyboardType: TextInputType.number),
              const SizedBox(height: 16),
              TextFormField(controller: _abstractCtrl, style: const TextStyle(color: Colors.white, fontFamily: 'Inter'), decoration: const InputDecoration(labelText: 'Abstract'), maxLines: 5),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Indexed Publication', style: TextStyle(color: Colors.white, fontFamily: 'Inter')),
                subtitle: Text(_isIndexed ? 'Indexed' : 'Not indexed', style: TextStyle(color: AppColors.textMuted, fontFamily: 'Inter')),
                value: _isIndexed,
                activeColor: AppColors.primary,
                onChanged: (v) => setState(() => _isIndexed = v),
                contentPadding: EdgeInsets.zero,
              ),
              if (_isIndexed)
                TextFormField(
                  style: const TextStyle(color: Colors.white, fontFamily: 'Inter'),
                  decoration: const InputDecoration(labelText: 'Index Type (Scopus, SCI, etc.)'),
                  onChanged: (v) => _indexType = v,
                ),
              SwitchListTile(
                title: const Text('Featured', style: TextStyle(color: Colors.white, fontFamily: 'Inter')),
                value: _isFeatured,
                activeColor: AppColors.primary,
                onChanged: (v) => setState(() => _isFeatured = v),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 24),
              LoadingButton(isLoading: _isSaving, onPressed: _save, child: const Text('Save Publication', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 15))),
            ],
          ),
        ),
      ),
    );
  }
}
