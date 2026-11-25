import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yumeiro/yumeiro.dart';

void main() {
  testWidgets('both selection forms use the active option foreground', (
    tester,
  ) async {
    await tester.pumpWidget(
      _page(
        Column(
          children: [
            YumeiroSelectionList.form(
              initialValue: 'a',
              options: const [
                YumeiroSelectionOption(
                  value: 'a',
                  label: 'Single A',
                  subtitle: 'Single detail',
                ),
                YumeiroSelectionOption(value: 'b', label: 'Single B'),
              ],
            ),
            YumeiroSelectionList.multiForm(
              initialValue: const {'a'},
              options: const [
                YumeiroSelectionOption(
                  value: 'a',
                  label: 'Multiple A',
                  subtitle: 'Multiple detail',
                ),
                YumeiroSelectionOption(value: 'b', label: 'Multiple B'),
              ],
            ),
          ],
        ),
      ),
    );
    final theme = YumeiroTheme.of(tester.element(find.text('Single A')));
    final idle = theme.visuals.item(YumeiroItemRole.selection, {}).foreground;
    final active = theme.visuals.item(YumeiroItemRole.selection, {
      WidgetState.selected,
    }).foreground;
    expect(active, isNot(idle));
    for (final text in [
      'Single A',
      'Single detail',
      'Multiple A',
      'Multiple detail',
    ]) {
      expect(_color(tester, text), active, reason: text);
    }
    for (final text in ['Single B', 'Multiple B']) {
      expect(_color(tester, text), idle, reason: text);
      await tester.tap(find.text(text));
      await tester.pumpAndSettle();
      expect(_color(tester, text), active, reason: text);
    }
    expect(_color(tester, 'Single A'), idle);
    expect(_color(tester, 'Multiple A'), active);
  });

  testWidgets(
    'selected rows keep their supporting and trailing content legible',
    (tester) async {
      final selection = YumeiroTableSelection<String>(
        mode: YumeiroTableSelectionMode.multiple,
        selectedKeys: {const ValueKey('a')},
        onChanged: (_) {},
      );
      await tester.pumpWidget(
        _page(
          Column(
            children: [
              YumeiroListTile(
                title: const Text('List title'),
                subtitle: const Text('List detail'),
                selected: true,
                onTap: () {},
              ),
              YumeiroSelectionRow(
                title: const Text('Selection title'),
                subtitle: const Text('Selection detail'),
                selected: true,
                onChanged: (_) {},
              ),
              YumeiroSegmentedControl.vertical(
                value: 'a',
                options: const [
                  YumeiroSegmentOption(
                    value: 'a',
                    label: 'Segment title',
                    subtitle: 'Segment detail',
                  ),
                ],
                onChanged: (_) {},
              ),
              YumeiroDataTable<String>(
                variant: YumeiroTableVariant.compact,
                columns: [
                  YumeiroTableColumn(
                    cellBuilder: (_, _, _) => const Text('Cell'),
                  ),
                ],
                items: const ['a'],
                compactRowBuilder: (_, _, _) => const YumeiroDataRow(
                  title: Text('Summary title'),
                  subtitle: Text('Summary detail'),
                  metadata: Text('Summary metadata'),
                ),
                selection: selection,
              ),
              YumeiroDataTable<String>(
                variant: YumeiroTableVariant.compact,
                columns: [
                  YumeiroTableColumn(
                    cellBuilder: (_, _, _) => const Text('Table title'),
                  ),
                ],
                trailingColumns: [
                  YumeiroTableColumn(
                    fixedWidth: 130,
                    cellBuilder: (_, _, _) => const Text('Trailing text'),
                  ),
                ],
                items: const ['a'],
                selection: selection,
              ),
            ],
          ),
          modality: YumeiroModality.touch,
        ),
      );
      for (final text in [
        'List title',
        'List detail',
        'Selection title',
        'Selection detail',
        'Segment detail',
        'Summary title',
        'Summary detail',
        'Summary metadata',
        'Trailing text',
      ]) {
        final theme = YumeiroTheme.of(tester.element(find.text(text)));
        expect(_color(tester, text), theme.onAccent, reason: text);
      }
    },
  );

  for (final modality in YumeiroModality.values) {
    testWidgets(
      'active menu placeholder follows the ${modality.name} surface',
      (tester) async {
        await tester.pumpWidget(
          _page(
            YumeiroSelect.menu(
              value: null,
              selected: true,
              placeholder: 'Active filter',
              options: const [
                YumeiroSelectionOption(value: 'a', label: 'Option A'),
              ],
              onChanged: (_) {},
            ),
            modality: modality,
          ),
        );
        final theme = YumeiroTheme.of(
          tester.element(find.text('Active filter')),
        );
        expect(_color(tester, 'Active filter'), theme.onAccent);
      },
    );
  }
}

Widget _page(
  Widget child, {
  YumeiroModality modality = YumeiroModality.pointer,
}) => YumeiroApp(
  preset: YumeiroThemePresets.pixelDark,
  modality: modality,
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

Color? _color(WidgetTester tester, String text) => tester
    .widget<RichText>(
      find.descendant(of: find.text(text), matching: find.byType(RichText)),
    )
    .text
    .style
    ?.color;
