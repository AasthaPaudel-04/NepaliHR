import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LanguageProvider extends ChangeNotifier {
  static const _storage = FlutterSecureStorage();
  static const _key = 'app_language';

  Locale _locale = const Locale('en');
  Locale get locale => _locale;
  bool get isNepali => _locale.languageCode == 'ne';

  LanguageProvider() {
    _load();
  }

  Future<void> _load() async {
    final saved = await _storage.read(key: _key);
    if (saved != null && saved.isNotEmpty) {
      _locale = Locale(saved);
      notifyListeners();
    }
  }

  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;
    _locale = locale;
    await _storage.write(key: _key, value: locale.languageCode);
    notifyListeners();
  }

  Future<void> toggle() => setLocale(
    _locale.languageCode == 'en' ? const Locale('ne') : const Locale('en'),
  );
}
