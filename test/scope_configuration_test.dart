import 'dart:async' show Completer;

import 'package:flutter/foundation.dart' show SynchronousFuture;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yumeiro/yumeiro.dart';

class _HostColors extends ThemeExtension<_HostColors> {
  const _HostColors(this.notice);

  final Color notice;

  @override
  _HostColors copyWith({Color? notice}) => _HostColors(notice ?? this.notice);

  @override
  _HostColors lerp(covariant _HostColors? other, double t) =>
      _HostColors(Color.lerp(notice, other?.notice ?? notice, t)!);
}

class _HostMaterialMessages extends DefaultMaterialLocalizations {
  const _HostMaterialMessages();

  @override
  String get datePickerHelpText => '宿主日期';
}

class _HostMaterialDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const _HostMaterialDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'zh';

  @override
  Future<MaterialLocalizations> load(Locale locale) =>
      SynchronousFuture(const _HostMaterialMessages());

  @override
  bool shouldReload(covariant _HostMaterialDelegate old) => false;
}

class _HostMessages {
  const _HostMessages(this.locale);

  final Locale locale;
}

class _AsyncHostDelegate extends LocalizationsDelegate<_HostMessages> {
  const _AsyncHostDelegate(this.loads, {this.pendingChinese});

  final List<Locale> loads;
  final Future<void>? pendingChinese;

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<_HostMessages> load(Locale locale) async {
    loads.add(locale);
    if (locale.languageCode == 'zh' && pendingChinese != null) {
      await pendingChinese;
    } else {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    return _HostMessages(locale);
  }

  @override
  bool shouldReload(covariant _AsyncHostDelegate old) => false;
}

void main() {
  for (final modality in YumeiroModality.values) {
    testWidgets(
      'floats shared route content in the origin direction ($modality)',
      (tester) async {
        await tester.pumpWidget(
          YumeiroApp(
            locale: const Locale('en'),
            modality: modality,
            home: Scaffold(
              body: Directionality(
                textDirection: TextDirection.rtl,
                child: Builder(
                  builder: (context) => Wrap(
                    children: [
                      TextButton(
                        onPressed: () => YumeiroDialog.show<void>(
                          context: context,
                          builder: (_) => const YumeiroDialog(
                            title: 'Modal',
                            child: Text('Dialog content'),
                          ),
                        ),
                        child: const Text('Open dialog'),
                      ),
                      TextButton(
                        onPressed: () => YumeiroEditor.show<void>(
                          context: context,
                          builder: (_) => const YumeiroEditor(
                            title: 'Edit',
                            child: Text('Editor content'),
                          ),
                        ),
                        child: const Text('Open editor'),
                      ),
                      TextButton(
                        onPressed: () => YumeiroActionMenu.show(
                          context: context,
                          globalPosition: const Offset(400, 200),
                          items: [
                            YumeiroMenuAction(
                              label: 'Menu content',
                              onPressed: () {},
                            ),
                          ],
                        ),
                        child: const Text('Open menu'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        final navigator = tester.state<NavigatorState>(find.byType(Navigator));
        Future<void> checkDirection(String label, String content) async {
          await tester.tap(find.text(label));
          await tester.pumpAndSettle();
          expect(
            Directionality.of(tester.element(find.text(content))),
            TextDirection.rtl,
          );
        }

        await checkDirection('Open dialog', 'Dialog content');
        navigator.pop();
        await tester.pumpAndSettle();
        await checkDirection('Open editor', 'Editor content');
        navigator.pop();
        await tester.pumpAndSettle();
        await checkDirection('Open menu', 'Menu content');
        await tester.tap(find.text('Menu content'));
        await tester.pumpAndSettle();
      },
    );
  }

  testWidgets('scope preserves host theme extensions by default', (
    tester,
  ) async {
    const host = _HostColors(Colors.pink);
    late ThemeData theme;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: const [host]),
        builder: (context, child) => YumeiroScope(
          preset: YumeiroThemePresets.classicDark,
          child: child!,
        ),
        home: Builder(
          builder: (context) {
            theme = Theme.of(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    expect(theme.extension<_HostColors>(), same(host));
    expect(
      theme.extension<YumeiroThemeExtension>()?.presetId,
      YumeiroThemePresetIds.classicDark,
    );
  });

  testWidgets('app builder theme extensions reach the navigator scope', (
    tester,
  ) async {
    const host = _HostColors(Colors.pink);
    await tester.pumpWidget(
      YumeiroApp(
        builder: (context, child) => Theme(
          data: Theme.of(context).copyWith(extensions: const [host]),
          child: child!,
        ),
        home: const Text('Host extension'),
      ),
    );
    final theme = Theme.of(tester.element(find.text('Host extension')));
    expect(theme.extension<_HostColors>(), same(host));
    expect(theme.extension<YumeiroThemeExtension>(), isNotNull);
  });

  testWidgets(
    'host mode keeps active Material themes and their Yumeiro tokens',
    (tester) async {
      const background = Color(0xFFFFEEDD);
      const darkBackground = Color(0xFF123456);
      final dark = yumeiroThemeData(preset: YumeiroThemePresets.geek)
          .copyWith(scaffoldBackgroundColor: darkBackground);
      late ThemeData scoped;
      Widget app(ThemeMode mode) => MaterialApp(
        theme: ThemeData(scaffoldBackgroundColor: background),
        darkTheme: dark,
        themeMode: mode,
        builder: (context, child) => YumeiroScope(
          inheritTheme: true,
          preset: YumeiroThemePresets.classicLight,
          child: child!,
        ),
        home: Builder(
          builder: (context) {
            scoped = Theme.of(context);
            return const SizedBox.shrink();
          },
        ),
      );
      await tester.pumpWidget(app(ThemeMode.light));
      expect(scoped.scaffoldBackgroundColor, background);
      expect(
        scoped.extension<YumeiroThemeExtension>()?.presetId,
        YumeiroThemePresetIds.classicLight,
      );

      await tester.pumpWidget(app(ThemeMode.dark));
      await tester.pumpAndSettle();
      expect(scoped.scaffoldBackgroundColor, darkBackground);
      expect(
        scoped.extension<YumeiroThemeExtension>()?.presetId,
        YumeiroThemePresetIds.geek,
      );
    },
  );

  testWidgets('a local Chinese locale can open a localized date picker', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: YumeiroScope(
          locale: const Locale('zh'),
          child: Center(
            child: YumeiroDatePicker.form(
              key: const ValueKey('localized-date-picker'),
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
              currentDate: DateTime(2027, 1, 14),
              initialEntryMode: DatePickerEntryMode.calendarOnly,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final field = find.byKey(const ValueKey('localized-date-picker'));
    final fieldContext = tester.element(field);
    final translations = MaterialLocalizations.of(fieldContext);
    expect(Localizations.localeOf(fieldContext), const Locale('zh'));
    expect(
      translations.datePickerHelpText,
      isNot(const DefaultMaterialLocalizations().datePickerHelpText),
    );

    await tester.tap(find.text(translations.datePickerHelpText));
    await tester.pumpAndSettle();
    final monthHeader = find.byKey(
      const ValueKey('yumeiro-calendar-month-2027-1'),
    );
    expect(monthHeader, findsOneWidget);
    expect(find.byType(DatePickerDialog), findsNothing);
    final dialogContext = tester.element(monthHeader);
    expect(
      MaterialLocalizations.of(dialogContext).datePickerHelpText,
      translations.datePickerHelpText,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('a supported host delegate takes precedence over the fallback', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [_HostMaterialDelegate()],
        home: YumeiroScope(
          locale: const Locale('zh'),
          child: Center(
            child: YumeiroDatePicker.form(
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('宿主日期'), findsOneWidget);
  });

  testWidgets(
    'explicit scope locale preserves a draft when host locale changes',
    (tester) async {
      const english = Locale('en');
      const chinese = Locale('zh');
      Widget app(Locale locale) => YumeiroApp(
        locale: locale,
        home: const YumeiroScope(
          locale: english,
          child: Scaffold(body: TextField()),
        ),
      );

      await tester.pumpWidget(app(english));
      final field = find.byType(EditableText);
      await tester.enterText(field, 'draft');
      final state = tester.state(field);

      await tester.pumpWidget(app(chinese));
      await tester.pumpAndSettle();
      expect(Localizations.localeOf(tester.element(field)), english);
      expect(tester.state(field), same(state));
      expect(tester.widget<EditableText>(field).controller.text, 'draft');
    },
  );

  testWidgets('adding and removing a local locale preserves a draft', (
    tester,
  ) async {
    const english = Locale('en');
    const chinese = Locale('zh');
    final loads = <Locale>[];
    final delegate = _AsyncHostDelegate(loads);
    Widget app(Locale? locale) => MaterialApp(
      locale: english,
      localizationsDelegates: [
        delegate,
        YumeiroLocalizations.delegate,
        ...GlobalMaterialLocalizations.delegates,
      ],
      supportedLocales: const [english, chinese],
      home: YumeiroScope(
        locale: locale,
        child: const Scaffold(body: TextField()),
      ),
    );

    await tester.pumpWidget(app(null));
    await tester.pump(const Duration(milliseconds: 10));
    await tester.pumpAndSettle();
    final field = find.byType(EditableText);
    await tester.enterText(field, 'draft');
    final state = tester.state(field);

    void expectLocaleAndDraft(Locale locale) {
      expect(Localizations.localeOf(tester.element(field)), locale);
      expect(
        Localizations.of<_HostMessages>(
          tester.element(field),
          _HostMessages,
        )?.locale,
        locale,
      );
      expect(tester.state(field), same(state));
      expect(tester.widget<EditableText>(field).controller.text, 'draft');
    }

    expectLocaleAndDraft(english);
    await tester.pumpWidget(app(chinese));
    expectLocaleAndDraft(english);
    await tester.pump(const Duration(milliseconds: 10));
    await tester.pumpAndSettle();
    expectLocaleAndDraft(chinese);
    await tester.pumpWidget(app(null));
    await tester.pumpAndSettle();
    expectLocaleAndDraft(english);
    expect(loads, [english, chinese]);
  });

  testWidgets('app builds visual recipes once per theme change', (
    tester,
  ) async {
    var builds = 0;
    Widget app(YumeiroThemePreset preset) => YumeiroApp(
      preset: preset,
      visualsAugmenter: (visuals, _, _) {
        builds++;
        return visuals;
      },
      home: const SizedBox.shrink(),
    );

    await tester.pumpWidget(app(YumeiroThemePresets.classicLight));
    await tester.pumpAndSettle();
    expect(builds, 1);
    builds = 0;
    await tester.pumpWidget(app(YumeiroThemePresets.classicDark));
    expect(builds, 1);
    builds = 0;
    for (var frame = 0; frame < 12; frame++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    await tester.pumpAndSettle();
    expect(builds, 0);
  });

  testWidgets('a late locale load cannot replace the restored host language', (
    tester,
  ) async {
    const english = Locale('en');
    const chinese = Locale('zh');
    final pending = Completer<void>();
    final delegate = _AsyncHostDelegate([], pendingChinese: pending.future);
    Widget app(Locale? locale) => MaterialApp(
      locale: english,
      localizationsDelegates: [
        delegate,
        YumeiroLocalizations.delegate,
        ...GlobalMaterialLocalizations.delegates,
      ],
      supportedLocales: const [english, chinese],
      home: YumeiroScope(
        locale: locale,
        child: const Scaffold(body: TextField()),
      ),
    );

    await tester.pumpWidget(app(null));
    await tester.pump(const Duration(milliseconds: 10));
    await tester.pumpAndSettle();
    final field = find.byType(EditableText);
    await tester.enterText(field, 'draft');
    final state = tester.state(field);

    await tester.pumpWidget(app(chinese));
    expect(Localizations.localeOf(tester.element(field)), english);
    expect(delegate.loads, [english, chinese]);
    await tester.pumpWidget(app(null));
    pending.complete();
    await tester.pumpAndSettle();

    final context = tester.element(field);
    expect(Localizations.localeOf(context), english);
    expect(
      Localizations.of<_HostMessages>(context, _HostMessages)?.locale,
      english,
    );
    expect(tester.state(field), same(state));
    expect(tester.widget<EditableText>(field).controller.text, 'draft');
  });
}
