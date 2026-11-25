import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yumeiro/yumeiro.dart';
import 'package:yumeiro_example/docs/layout_demos.dart';
import 'package:yumeiro_example/src/widgets/compact_table_demo.dart';
import 'package:yumeiro_example/src/widgets/gallery_widgets.dart';

void main() {
  for (final modality in YumeiroModality.values) {
    testWidgets(
      'short tables use the expected overlay and retain selection in ${modality.name}',
      (tester) async {
        final isTouch = modality == YumeiroModality.touch;
        final size = isTouch ? const Size(390, 844) : const Size(760, 920);
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          YumeiroApp(
            modality: modality,
            locale: const Locale('zh'),
            home: const Scaffold(body: GalleryCompactTableDemo()),
          ),
        );
        await tester.pumpAndSettle();

        Future<void> tap(String label) async {
          final control = find.text(label);
          await tester.ensureVisible(control);
          await tester.tap(control);
          await tester.pumpAndSettle();
        }

        final sheet = find.byType(YumeiroBottomSheet);
        final dialog = find.byType(YumeiroDialog);
        final table = find.byWidgetPredicate(
          (widget) => widget is YumeiroDataTable,
        );

        void expectTableOverlay() {
          expect(sheet, isTouch ? findsOneWidget : findsNothing);
          expect(dialog, isTouch ? findsNothing : findsOneWidget);
          final frame = isTouch ? sheet : dialog;
          expect(find.descendant(of: frame, matching: table), findsOneWidget);
          expect(
            find.text(
              isTouch
                  ? 'YumeiroDataTable(variant: compact, compactRowBuilder: …)'
                  : 'YumeiroDataTable(variant: compact, additionalColumnBands: …)',
            ),
            findsOneWidget,
          );
          if (isTouch) {
            final surface = find.descendant(
              of: sheet,
              matching: find.byWidgetPredicate(
                (widget) =>
                    widget is YumeiroVisualSurface &&
                    widget.role == YumeiroSurfaceRole.modal,
              ),
            );
            final rect = tester.getRect(surface.first);
            expect(rect.left, 0);
            expect(rect.right, size.width);
            expect(rect.bottom, size.height);
            expect(
              find.descendant(of: table, matching: find.byType(YumeiroDataRow)),
              findsNWidgets(4),
            );
            expect(
              find.descendant(
                of: table,
                matching: find.byWidgetPredicate(
                  (widget) =>
                      widget is Scrollable &&
                      axisDirectionToAxis(widget.axisDirection) ==
                          Axis.horizontal,
                ),
              ),
              findsNothing,
            );
          }
        }

        if (isTouch) {
          expect(find.text('上下两排'), findsNothing);
        } else {
          await tap('上下两排');
        }
        await tap('单选表格');
        expectTableOverlay();
        await tap('选项 C');
        await tap('确认选择');
        expect(find.text('已选择 选项 C'), findsOneWidget);

        await tap('单选表格');
        await tap('选项 B');
        await tap('取消');
        await tap('单选表格');
        await tap('确认选择');
        expect(find.text('已选择 选项 C'), findsOneWidget);

        await tap('带操作的表格');
        expectTableOverlay();
        expect(find.byTooltip('查看 说明 A').hitTestable(), findsOneWidget);
        expect(find.byTooltip('复制 说明 A').hitTestable(), findsOneWidget);
        await tap('完成');
        expect(table, findsNothing);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'tables retain selections across display variants in ${modality.name}',
      (tester) async {
        tester.view.physicalSize = modality == YumeiroModality.touch
            ? const Size(390, 844)
            : const Size(760, 920);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          YumeiroApp(
            modality: modality,
            locale: const Locale('zh'),
            home: Scaffold(
              body: Builder(
                builder: (context) => compactTableDemo(
                  context,
                  decorate: GalleryComponent.sample,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        Future<void> tap(String label) async {
          await tester.tap(find.text(label));
          await tester.pumpAndSettle();
        }

        expect(find.text('已选 1 项'), findsOneWidget);
        const stackedCaption =
            'YumeiroDataTable(variant: compact, additionalColumnBands: …)';
        expect(find.text(stackedCaption), findsOneWidget);
        await tap('单排');
        expect(find.text('YumeiroDataTable(variant: compact)'), findsOneWidget);
        expect(find.text(stackedCaption), findsNothing);
        await tap('上下两排');
        expect(find.text(stackedCaption), findsOneWidget);
        await tap('多选');
        await tap('示例 B');
        await tap('示例 C');
        expect(find.text('已选 2 项'), findsOneWidget);

        await tap('查看全部');
        const longCaption =
            'YumeiroDataTable.sliver(variant: compact, additionalColumnBands: …)';
        expect(find.text(longCaption), findsOneWidget);
        expect(find.text(stackedCaption), findsNothing);
        final viewport = find.descendant(
          of: find.byType(CustomScrollView),
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is Scrollable &&
                widget.axisDirection == AxisDirection.down,
          ),
        );
        final farRow = find.text('示例 A · 31');
        expect(farRow, findsNothing);
        await tester.scrollUntilVisible(farRow, 180, scrollable: viewport);
        await tester.pumpAndSettle();
        expect(find.text('示例 A'), findsNothing);
        await tap('示例 A · 31');
        expect(find.text('已选 3 项'), findsOneWidget);
        tester.state<ScrollableState>(viewport).position.jumpTo(0);
        await tester.pumpAndSettle();
        expect(
          tester
              .widgetList<YumeiroCheckbox>(find.byType(YumeiroCheckbox))
              .where((checkbox) => checkbox.value == true),
          hasLength(2),
        );

        await tap('标准');
        const standardLongCaption =
            'YumeiroDataTable.sliver(additionalColumnBands: …)';
        expect(find.text(standardLongCaption), findsOneWidget);
        final header = find.text('名称').hitTestable();
        final headerY = tester.getTopLeft(header).dy;
        await tester.scrollUntilVisible(farRow, 180, scrollable: viewport);
        await tester.pumpAndSettle();
        expect(tester.getTopLeft(header).dy, headerY);
        expect(find.text('已选 3 项'), findsOneWidget);

        await tap('隐藏');
        expect(
          find.text('YumeiroDataTable(additionalColumnBands: …)'),
          findsOneWidget,
        );
        expect(find.text(standardLongCaption), findsNothing);
        expect(find.text(longCaption), findsNothing);
        expect(find.text('其中 1 项已隐藏'), findsOneWidget);
        await tap('确认选择');
        expect(find.text('已确认 3 项'), findsOneWidget);
        await tap('单选');
        expect(find.text('已选 1 项'), findsOneWidget);
        await tap('清空选择');
        expect(find.text('已选 0 项'), findsOneWidget);
        expect(
          tester
              .widget<YumeiroButton>(find.widgetWithText(YumeiroButton, '确认选择'))
              .onPressed,
          isNull,
        );
      },
    );
  }
}
