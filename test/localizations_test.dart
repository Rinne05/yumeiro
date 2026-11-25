import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yumeiro/yumeiro.dart';

class _CustomJaLocalizations extends YumeiroLocalizationsEn {
  const _CustomJaLocalizations();

  @override
  String get localeName => 'ja';

  @override
  String get searchHint => '検索...';
}

class _CustomThemeLocalizations extends YumeiroLocalizationsEn {
  const _CustomThemeLocalizations();

  @override
  String get searchHint => 'Find records';

  @override
  String get familyNeumorphic => 'Soft Surfaces';

  @override
  String get presetNeumorphicDark => 'Night Surfaces';
}

class _EnglishYumeiroDelegate
    extends LocalizationsDelegate<YumeiroLocalizations> {
  const _EnglishYumeiroDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'en';

  @override
  Future<YumeiroLocalizations> load(Locale locale) =>
      SynchronousFuture(const _CustomThemeLocalizations());

  @override
  bool shouldReload(_EnglishYumeiroDelegate old) => false;
}

void main() {
  group('YumeiroLocalizations & Icon/Font config', () {
    testWidgets('app resolves fixed messages, host delegates, then defaults', (
      tester,
    ) async {
      Widget app(Locale locale, {YumeiroLocalizations? localizations}) =>
          YumeiroApp(
            locale: locale,
            localizations: localizations,
            localizationsDelegates: const [_EnglishYumeiroDelegate()],
            home: const Scaffold(body: YumeiroTextField.search()),
          );
      await tester.pumpWidget(app(const Locale('en')));
      await tester.pumpAndSettle();
      expect(find.text('Find records'), findsOneWidget);
      await tester.pumpWidget(app(const Locale('zh')));
      await tester.pumpAndSettle();
      expect(find.text('搜索...'), findsOneWidget);
      await tester.pumpWidget(
        app(const Locale('en'), localizations: const _CustomJaLocalizations()),
      );
      await tester.pumpAndSettle();
      expect(find.text('検索...'), findsOneWidget);
    });

    test('theme variant labels retain their saved preset IDs', () {
      const messages = _CustomThemeLocalizations();
      expect(
        messages.resolvePresetLabel('yumeiro.neumorphic', 'Default'),
        'Soft Surfaces · Light',
      );
      expect(
        messages.resolvePresetLabel('yumeiro.neumorphic.dark', 'Default'),
        'Night Surfaces',
      );
    });

    testWidgets('supports built-in en and zh locales and custom overrides', (
      tester,
    ) async {
      await tester.pumpWidget(
        const YumeiroApp(
          locale: Locale('zh'),
          home: Scaffold(body: YumeiroTextField.search()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('搜索...'), findsOneWidget);

      await tester.pumpWidget(
        const YumeiroApp(
          locale: Locale('en'),
          home: Scaffold(body: YumeiroTextField.search()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Search...'), findsOneWidget);

      await tester.pumpWidget(
        const YumeiroApp(
          localizations: _CustomJaLocalizations(),
          home: Scaffold(body: YumeiroTextField.search()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('検索...'), findsOneWidget);
    });

    testWidgets(
      'YumeiroIconSet and YumeiroFontConfig are configurable via YumeiroScope',
      (tester) async {
        final customIcons = YumeiroIconSet.material().copyWith(
          search: Icons.manage_search_rounded,
        );
        await tester.pumpWidget(
          YumeiroApp(
            icons: customIcons,
            fontConfig: const YumeiroFontConfig(fontFamily: 'CustomSans'),
            home: const Scaffold(body: YumeiroTextField.search()),
          ),
        );
        expect(find.byIcon(Icons.manage_search_rounded), findsOneWidget);
      },
    );

    test('resolves platform-appropriate font fallback stacks without cross-OS fuzzy matches', () {
      const defaults = YumeiroFontConfig();
      if (kIsWeb) {
        expect(defaults.resolvedFontFallback, kYumeiroFontFallback);
      } else {
        addTearDown(() => debugDefaultTargetPlatformOverride = null);

        debugDefaultTargetPlatformOverride = TargetPlatform.windows;
        expect(defaults.resolvedFontFallback.take(2), [
          'Segoe UI',
          'Microsoft YaHei UI',
        ]);

        debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
        expect(
          defaults.resolvedFontFallback,
          containsAllInOrder(['SF Pro Text', 'PingFang SC']),
        );

        debugDefaultTargetPlatformOverride = TargetPlatform.linux;
        final linuxStack = defaults.resolvedFontFallback;
        expect(linuxStack.first, 'sans-serif');
        expect(
          linuxStack,
          containsAll(['Noto Sans CJK SC', 'Source Han Sans SC']),
        );
        expect(linuxStack, isNot(contains('Segoe UI')));
        expect(linuxStack, isNot(contains('PingFang SC')));

        final tokens = YumeiroTypographyTokens.fromColors(
          text: Colors.white,
          muted: Colors.grey,
        );
        expect(tokens.textTheme.labelLarge?.fontFamily, 'sans-serif');
        expect(tokens.textTheme.labelMedium?.fontFamily, 'sans-serif');
        expect(tokens.textTheme.labelLarge?.fontFamilyFallback, linuxStack);
      }

      const custom = YumeiroFontConfig(
        fontFamily: 'CustomSans',
        fontFallback: <String>['CustomFallback', 'sans-serif'],
      );
      expect(custom.resolvedFontFallback, <String>[
        'CustomSans',
        'CustomFallback',
        'sans-serif',
      ]);
    });
  });
}
