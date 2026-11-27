import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yumeiro/src/components/controls/selection_control.dart';
import 'package:yumeiro/yumeiro.dart';

void main() {
  for (final modality in YumeiroModality.values) {
    testWidgets('single and multiple rows share height in ${modality.name}', (
      tester,
    ) async {
      const singleKey = ValueKey('single');
      const multipleKey = ValueKey('multiple');
      final changes = <bool>[];
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          modality: modality,
          width: 200,
          child: Column(
            children: [
              YumeiroSelectionRow(
                key: singleKey,
                title: const Text('Single'),
                multiple: false,
                selected: true,
                onChanged: changes.add,
              ),
              YumeiroSelectionRow(
                key: multipleKey,
                title: const Text('Multiple'),
                selected: true,
                onChanged: changes.add,
              ),
            ],
          ),
        ),
      );

      final single = tester.getRect(find.byKey(singleKey));
      final multiple = tester.getRect(find.byKey(multipleKey));
      expect(multiple.height, single.height);
      expect(multiple.height, 48);
      expect(
        tester.getSemantics(find.byKey(multipleKey)),
        isSemantics(
          hasCheckedState: true,
          isChecked: true,
          hasTapAction: true,
          hasEnabledState: true,
          isEnabled: true,
        ),
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(changes, [true]);

      // Activation belongs to the row even outside the indicator and text.
      await tester.tapAt(Offset(multiple.left + 2, multiple.center.dy));
      expect(changes, [true, false]);
      semantics.dispose();
    });
  }

  testWidgets('disabled single rows retain selection and independent actions', (
    tester,
  ) async {
    const disabled = ValueKey('disabled');
    const readOnly = ValueKey('read-only');
    const customForeground = Color(0xff682ba0);
    var selected = 0;
    var opened = 0;
    await tester.pumpWidget(
      _host(
        modality: YumeiroModality.pointer,
        child: Column(
          children: [
            YumeiroVisualScope(
              visualOverride: YumeiroVisualOverride(
                states: WidgetStateProperty.resolveWith(
                  (states) => states.contains(WidgetState.disabled)
                      ? const YumeiroVisualDelta(foreground: customForeground)
                      : null,
                ),
              ),
              child: YumeiroSelectionRow(
                key: disabled,
                title: const Text('Locked choice'),
                multiple: false,
                enabled: false,
                selected: true,
                trailing: YumeiroButton(
                  label: 'Details',
                  onPressed: () => opened++,
                ),
                onChanged: (_) => selected++,
              ),
            ),
            const YumeiroSelectionRow(
              key: readOnly,
              title: Text('Saved choice'),
              multiple: false,
              readOnly: true,
              selected: true,
              onChanged: null,
            ),
          ],
        ),
      ),
    );

    final mark = find.byType(UnavailableSelectionMark);
    expect(mark, findsOneWidget);
    expect(tester.widget<UnavailableSelectionMark>(mark).selected, isTrue);
    final surface = find.descendant(
      of: find.byKey(disabled),
      matching: find.byType(YumeiroResolvedVisualSurface),
    );
    final appearance = tester
        .widget<YumeiroResolvedVisualSurface>(surface.first)
        .appearance;
    expect(appearance.foreground, customForeground);
    expect(appearance.opacity, 1);
    final checkmark = YumeiroTheme.of(tester.element(find.byKey(readOnly)))
        .icons
        .check;
    expect(
      find.descendant(
        of: find.byKey(readOnly),
        matching: find.byIcon(checkmark),
      ),
      findsOneWidget,
    );
    expect(
      tester.getSemantics(find.byKey(disabled)),
      isSemantics(
        isSelected: true,
        hasEnabledState: true,
        isEnabled: false,
        hasTapAction: false,
      ),
    );
    await tester.tap(find.text('Locked choice'));
    await tester.tap(find.text('Details'));
    expect(selected, 0);
    expect(opened, 1);
  });

  for (final direction in TextDirection.values) {
    testWidgets('row footer follows its text column in ${direction.name}', (
      tester,
    ) async {
      const titleKey = ValueKey('title');
      const footerKey = ValueKey('footer');
      const subtitle = 'Receive notifications for tasks that are still active.';
      var toggles = 0;
      var opened = 0;
      await tester.pumpWidget(
        _host(
          modality: YumeiroModality.touch,
          child: Directionality(
            textDirection: direction,
            child: YumeiroSelectionRow(
              title: const Text('Notifications', key: titleKey),
              subtitle: const Text(subtitle),
              leading: const SizedBox(width: 37, height: 18),
              trailing: YumeiroButton(label: 'Open', onPressed: () => opened++),
              footer: const Text('Weekdays', key: footerKey),
              leadingCheckbox: true,
              selected: true,
              onChanged: (_) => toggles++,
            ),
          ),
        ),
      );

      final title = tester.getRect(find.byKey(titleKey));
      final footer = tester.getRect(find.byKey(footerKey));
      double start(Rect rect) => switch (direction) {
        TextDirection.ltr => rect.left,
        TextDirection.rtl => rect.right,
      };
      expect(start(footer), start(title));
      expect(tester.getSize(find.text(subtitle)).height, greaterThan(32));
      expect(
        footer.top,
        greaterThan(tester.getBottomLeft(find.text(subtitle)).dy),
      );

      await tester.tap(find.text('Open'));
      expect(opened, 1);
      expect(toggles, 0);
      await tester.tapAt(tester.getCenter(find.byType(Checkbox)));
      expect(toggles, 1);
    });
  }
}

Widget _host({
  required YumeiroModality modality,
  required Widget child,
  double width = 360,
}) => YumeiroApp(
  modality: modality,
  home: Scaffold(
    body: Align(
      alignment: Alignment.topCenter,
      child: SizedBox(width: width, child: child),
    ),
  ),
);
