import 'package:flutter_test/flutter_test.dart';
import 'package:yumeiro/yumeiro.dart';
import 'package:yumeiro_example/main_docs.dart';

void main() {
  for (final (preset, appearance, id) in [
    ('classic', 'light', YumeiroThemePresetIds.classicLight),
    ('glass', 'dark', YumeiroThemePresetIds.liquidGlassDark),
    ('pixel', 'light', YumeiroThemePresetIds.pixelLight),
    ('unknown', 'dark', YumeiroThemePresetIds.classicDark),
  ]) {
    testWidgets('preview link selects $id and opens the sample dialog', (
      tester,
    ) async {
      await tester.pumpWidget(
        YumeiroDocsPreviewApp(
          uri: Uri.parse(
            'https://example.invalid/preview/index.html?demo=theme-preview'
            '&modality=pointer&preset=$preset&theme=$appearance',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.widget<YumeiroApp>(find.byType(YumeiroApp)).preset!.id, id);
      expect(find.widgetWithText(YumeiroFieldLayout, '任务名称'), findsOneWidget);
      await tester.tap(find.widgetWithText(YumeiroButton, '查看详情'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(YumeiroDialog, '发布资料'), findsOneWidget);
    });
  }
}
