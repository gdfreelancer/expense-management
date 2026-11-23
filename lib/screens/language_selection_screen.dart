import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../l10n/app_localizations.dart';

class LanguageSelectionScreen extends StatefulWidget {
  const LanguageSelectionScreen({
    super.key,
    required this.initialCode,
    required this.onSelected,
    this.showBackButton = true,
  });
  final String initialCode;
  final Future<void> Function(String) onSelected;
  final bool showBackButton;

  @override
  State<LanguageSelectionScreen> createState() => _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  late String _selectedCode;
  String _query = '';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selectedCode = widget.initialCode;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tr;
    final query = _query.trim().toLowerCase();
    final options = supportedLanguageOptions.where((item) =>
      query.isEmpty || item.name.toLowerCase().contains(query) || item.code.toLowerCase().contains(query)).toList();
    final groups = <int, List<AppLanguage>>{};
    for (final item in options) {
      groups.putIfAbsent(item.phase, () => []).add(item);
    }
    const groupTitles = {
      0: 'Default',
      1: 'United States',
      2: 'Middle East & Europe',
      3: 'India',
      4: 'More languages',
    };

    return Scaffold(
      appBar: widget.showBackButton
          ? AppBar(title: Text(t('Select language')))
          : AppBar(automaticallyImplyLeading: false, title: Text(t('Choose your language'))),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(t('Use the app in your preferred language.'), style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 15),
            TextField(
              onChanged: (value) => setState(() => _query = value),
              decoration: InputDecoration(
                hintText: t('Search languages'),
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: _query.isEmpty ? null : IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => setState(() => _query = '')),
              ),
            ),
          ]),
        ),
        Expanded(
          child: options.isEmpty
              ? Center(child: Text(t('No languages found'), style: Theme.of(context).textTheme.bodyMedium))
              : ListView(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
                  children: [
                    for (final entry in groups.entries) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(2, 12, 2, 8),
                        child: Text(t(groupTitles[entry.key]!), style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppTheme.muted, fontWeight: FontWeight.w800, letterSpacing: .9)),
                      ),
                      for (final item in entry.value) _languageTile(item),
                    ],
                  ],
                ),
        ),
        SafeArea(
          top: false,
          minimum: const EdgeInsets.fromLTRB(18, 8, 18, 14),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _saving ? null : () async {
                setState(() => _saving = true);
                try {
                  await widget.onSelected(_selectedCode);
                  if (widget.showBackButton && mounted) Navigator.of(context).pop();
                } finally {
                  if (mounted) setState(() => _saving = false);
                }
              },
              child: _saving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(t('Continue')),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _languageTile(AppLanguage language) {
    final selected = _selectedCode == language.code;
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Material(
        color: selected ? AppTheme.softGreen : Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => setState(() => _selectedCode = language.code),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: selected ? AppTheme.brand : AppTheme.border, width: selected ? 1.4 : .8),
            ),
            child: Row(children: [
              Expanded(child: Text(
                language.name,
                textDirection: language.code == 'ar' ? TextDirection.rtl : TextDirection.ltr,
                style: TextStyle(fontSize: 14, fontWeight: selected ? FontWeight.w800 : FontWeight.w600, color: selected ? AppTheme.brandDark : AppTheme.ink),
              )),
              const SizedBox(width: 12),
              AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? AppTheme.brand : Colors.transparent,
                  border: Border.all(color: selected ? AppTheme.brand : AppTheme.muted.withValues(alpha: .45), width: 1.4),
                ),
                child: selected ? const Icon(Icons.check_rounded, color: Colors.white, size: 15) : null,
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
