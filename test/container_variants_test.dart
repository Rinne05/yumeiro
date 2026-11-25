import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yumeiro/yumeiro.dart';

void main() {
  for (final modality in [YumeiroModality.pointer, YumeiroModality.touch]) {
    testWidgets('passive containers retain their $modality defaults', (
      tester,
    ) async {
      await tester.pumpWidget(
        YumeiroApp(
          modality: modality,
          home: const Scaffold(
            body: DividerTheme(
              data: DividerThemeData(color: Colors.red, thickness: 3),
              child: Column(
                children: [
                  YumeiroCard.panel(
                    clipBehavior: Clip.hardEdge,
                    child: Text('Panel'),
                  ),
                  YumeiroDivider(height: 24, touchHeight: 1),
                  YumeiroFieldLayout.readOnly(
                    label: 'File path',
                    value: '/media/poster.png',
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      final card = find.byType(YumeiroCard);
      final panel = tester.widget<YumeiroVisualSurface>(
        find.descendant(of: card, matching: find.byType(YumeiroVisualSurface)),
      );
      expect(panel.role, YumeiroSurfaceRole.panel);
      expect(panel.clipBehavior, Clip.hardEdge);
      expect(panel.padding, const EdgeInsets.all(20));

      final field = find.byType(YumeiroFieldLayout);
      final label = find.text('File path');
      final value = find.byType(SelectableText);
      final theme = YumeiroTheme.of(tester.element(field));
      final touch = modality == YumeiroModality.touch;
      expect(find.bySemanticsLabel('File path'), findsOneWidget);
      expect(tester.widget<SelectableText>(value).data, '/media/poster.png');
      expect(tester.widget<SelectableText>(value).maxLines, 2);
      expect(
        tester.getTopLeft(value).dy - tester.getBottomLeft(label).dy,
        closeTo(touch ? theme.spacing.sm : theme.spacing.xs, 0.01),
      );
      expect(
        tester.getBottomLeft(field).dy - tester.getBottomLeft(value).dy,
        closeTo(theme.spacing.lg, 0.01),
      );

      final divider = tester.widget<Divider>(find.byType(Divider));
      expect(divider.height, touch ? 1 : 24);
      expect(divider.thickness, 1);
      expect(divider.color, theme.line);
    });
  }
}
