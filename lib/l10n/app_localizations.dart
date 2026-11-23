import 'package:flutter/widgets.dart';
import 'strings_en.dart';
import 'strings_gu.dart';
import 'strings_hi.dart';
import 'strings_ar.dart';
import 'strings_bn.dart';
import 'strings_de.dart';
import 'strings_es.dart';
import 'strings_fr.dart';
import 'strings_id.dart';
import 'strings_it.dart';
import 'strings_ja.dart';
import 'strings_ko.dart';
import 'strings_kn.dart';
import 'strings_ml.dart';
import 'strings_mr.dart';
import 'strings_pa.dart';
import 'strings_pt.dart';
import 'strings_ru.dart';
import 'strings_ta.dart';
import 'strings_te.dart';
import 'strings_tr.dart';
import 'strings_zh.dart';

class AppLanguage {
  const AppLanguage(this.code, this.name, this.phase);
  final String code;
  final String name;
  final int phase;
  Locale get locale {
    final parts = code.split('_');
    return parts.length == 2 ? Locale(parts[0], parts[1]) : Locale(parts[0]);
  }
}

const supportedLanguageOptions = <AppLanguage>[
  AppLanguage('en', 'English', 0),
  AppLanguage('en_US', 'English (United States)', 1),
  AppLanguage('es_US', 'Español (Estados Unidos)', 1),
  AppLanguage('ar', 'العربية', 2),
  AppLanguage('en_GB', 'English (United Kingdom)', 2),
  AppLanguage('hi', 'हिन्दी', 3),
  AppLanguage('gu', 'ગુજરાતી', 3),
  AppLanguage('bn', 'বাংলা', 3),
  AppLanguage('mr', 'मराठी', 3),
  AppLanguage('ta', 'தமிழ்', 3),
  AppLanguage('te', 'తెలుగు', 3),
  AppLanguage('kn', 'ಕನ್ನಡ', 3),
  AppLanguage('ml', 'മലയാളം', 3),
  AppLanguage('pa', 'ਪੰਜਾਬੀ', 3),
  AppLanguage('de', 'Deutsch', 4),
  AppLanguage('fr', 'Français', 4),
  AppLanguage('es', 'Español', 4),
  AppLanguage('pt_BR', 'Português (Brasil)', 4),
  AppLanguage('ja', '日本語', 4),
  AppLanguage('ko', '한국어', 4),
  AppLanguage('id', 'Bahasa Indonesia', 4),
  AppLanguage('tr', 'Türkçe', 4),
  AppLanguage('ru', 'Русский', 4),
  AppLanguage('zh_CN', '简体中文', 4),
];

Locale localeForLanguageCode(String code) =>
    supportedLanguageOptions.firstWhere((item) => item.code == code, orElse: () => supportedLanguageOptions.first).locale;

Map<String, String> translationsFor(String code) {
  switch (code) {
    case 'hi': return stringsHi;
    case 'gu': return stringsGu;
    case 'ar': return stringsAr;
    case 'bn': return stringsBn;
    case 'de': return stringsDe;
    case 'es':
    case 'es_US': return stringsEs;
    case 'fr': return stringsFr;
    case 'id': return stringsId;
    case 'ja': return stringsJa;
    case 'ko': return stringsKo;
    case 'kn': return stringsKn;
    case 'ml': return stringsMl;
    case 'mr': return stringsMr;
    case 'pa': return stringsPa;
    case 'pt_BR': return stringsPt;
    case 'ru': return stringsRu;
    case 'ta': return stringsTa;
    case 'te': return stringsTe;
    case 'tr': return stringsTr;
    case 'zh_CN': return stringsZh;
    default: return stringsEn;
  }
}

class LocaleScope extends InheritedWidget {
  const LocaleScope({super.key, required this.languageCode, required this.onLanguageChanged, required super.child});
  final String languageCode;
  final ValueChanged<String> onLanguageChanged;
  static LocaleScope of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<LocaleScope>()!;
  @override bool updateShouldNotify(LocaleScope oldWidget) => languageCode != oldWidget.languageCode;
}

extension LocalizedText on BuildContext {
  String tr(String key) {
    final translations = translationsFor(LocaleScope.of(this).languageCode);
    return translations[key] ?? stringsEn[key] ?? key;
  }
}
