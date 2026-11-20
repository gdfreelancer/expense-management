import 'package:flutter/widgets.dart';
import 'strings_en.dart';
import 'strings_gu.dart';
import 'strings_hi.dart';

class LocaleScope extends InheritedWidget {
  const LocaleScope({super.key, required this.languageCode, required this.onLanguageChanged, required super.child});
  final String languageCode;
  final ValueChanged<String> onLanguageChanged;
  static LocaleScope of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<LocaleScope>()!;
  @override bool updateShouldNotify(LocaleScope oldWidget) => languageCode != oldWidget.languageCode;
}

extension LocalizedText on BuildContext {
  String tr(String key) {
    final code = LocaleScope.of(this).languageCode;
    final maps = {'en': stringsEn, 'hi': stringsHi, 'gu': stringsGu};
    return maps[code]?[key] ?? stringsEn[key] ?? key;
  }
}
