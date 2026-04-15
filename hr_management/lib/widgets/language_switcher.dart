import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../app_colors.dart';
import '../l10n/app_localizations.dart';

class LanguageSwitcher extends StatelessWidget {
  final bool compact;
  const LanguageSwitcher({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    if (compact) {
      return GestureDetector(
        onTap: () => _showDialog(context, lang),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            lang.isNepali ? 'EN' : 'ने',
            style: const TextStyle(
                color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
          ),
        ),
      );
    }

    final l = AppLocalizations.of(context);
    return GestureDetector(
      onTap: () => _showDialog(context, lang),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.language_rounded,
                color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l.language,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppColors.textPrimary)),
              Text(lang.isNepali ? l.nepali : l.english,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
            ]),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(l.changeLanguage,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary)),
          ),
        ]),
      ),
    );
  }

  void _showDialog(BuildContext context, LanguageProvider lang) {
    final l = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l.changeLanguage,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          _option(context, lang, const Locale('en'), '🇬🇧  English'),
          const SizedBox(height: 8),
          _option(context, lang, const Locale('ne'), '🇳🇵  नेपाली'),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l.close,
                style: const TextStyle(color: AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }

  Widget _option(BuildContext ctx, LanguageProvider lang, Locale locale,
      String label) {
    final active = lang.locale.languageCode == locale.languageCode;
    return GestureDetector(
      onTap: () {
        lang.setLocale(locale);
        Navigator.pop(ctx);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: active ? AppColors.primary.withOpacity(0.07) : AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: active ? AppColors.primary : AppColors.border,
              width: active ? 1.5 : 1),
        ),
        child: Row(children: [
          Expanded(
            child: Text(label,
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    color: active ? AppColors.primary : AppColors.textPrimary)),
          ),
          if (active)
            const Icon(Icons.check_circle_rounded,
                color: AppColors.primary, size: 20),
        ]),
      ),
    );
  }
}
