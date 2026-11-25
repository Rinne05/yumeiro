import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yumeiro/yumeiro.dart';
import 'package:yumeiro_example/docs/data_table_pagination_demo.dart';

void main() {
  for (final modality in YumeiroModality.values) {
    testWidgets(
      'page selection remains scoped to its rows in ${modality.name}',
      (tester) async {
        await _open(tester, modality: modality);
        expect(find.text('01 示例 A'), findsOneWidget);
        expect(_pagination(tester).pageCount, 12);
        _expectPaginationCentered(tester, previous: '上一页', next: '下一页');
        expect(_button(tester, '上一页').onPressed, isNull);

        final checkboxes = find.byType(YumeiroCheckbox);
        await tester.tap(checkboxes.at(1));
        await tester.pumpAndSettle();
        expect(find.text('已选择 1 项'), findsOneWidget);

        await _tap(tester, '下一页');
        expect(find.text('正在加载示例'), findsOneWidget);
        expect(find.text('01 示例 A'), findsNothing);
        expect(_button(tester, '上一页').onPressed, isNotNull);
        await tester.pumpAndSettle();
        expect(find.text('05 示例 B2'), findsOneWidget);
        expect(find.textContaining('共 48 项'), findsNothing);
        expect(find.text('其中 1 项不在当前页'), findsOneWidget);

        await tester.tap(checkboxes.first);
        await tester.pumpAndSettle();
        expect(find.text('已选择 4 项'), findsOneWidget);
        expect(tester.widget<YumeiroCheckbox>(checkboxes.at(2)).value, isFalse);
        await tester.tap(checkboxes.first);
        await tester.pumpAndSettle();
        expect(find.text('已选择 1 项'), findsOneWidget);

        await _tap(tester, '上一页');
        await tester.pumpAndSettle();
        expect(tester.widget<YumeiroCheckbox>(checkboxes.at(1)).value, isTrue);
        await _tap(tester, '清空全部选择');
        expect(find.text('已选择 0 项'), findsOneWidget);
        expect(_button(tester, '清空全部选择').onPressed, isNull);
      },
    );
  }

  testWidgets(
    'sorting and filtering take effect before slicing the first page',
    (tester) async {
      await _open(tester, modality: YumeiroModality.touch);
      await _tap(tester, '下一页');
      await tester.pumpAndSettle();
      expect(find.text('05 示例 B2'), findsOneWidget);

      await _tap(tester, '按名称降序');
      await tester.pumpAndSettle();
      expect(find.text('48 示例 48'), findsOneWidget);
      expect(find.text('01 示例 A'), findsNothing);
      await _tap(tester, '下一页');
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '示例 B');
      await tester.pumpAndSettle();
      expect(_pagination(tester).pageCount, 1);
      expect(find.text('10 示例 B3'), findsOneWidget);
      expect(find.text('05 示例 B2'), findsOneWidget);
      expect(find.text('02 示例 B1'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('10 示例 B3')).dy,
        lessThan(tester.getTopLeft(find.text('05 示例 B2')).dy),
      );
      expect(_button(tester, '上一页').onPressed, isNull);
      expect(_button(tester, '下一页').onPressed, isNull);

      await tester.enterText(find.byType(TextField), '不存在');
      await tester.pumpAndSettle();
      expect(find.text('没有匹配的示例'), findsOneWidget);
      expect(find.byType(YumeiroPagination), findsNothing);
    },
  );

  testWidgets('an active request failure can be retried on the same page', (
    tester,
  ) async {
    await _open(tester);
    await _tap(tester, '模拟下次请求失败');
    expect(find.text('取消模拟失败'), findsOneWidget);
    await _tap(tester, '下一页');
    await tester.pumpAndSettle();
    expect(find.text('加载失败'), findsOneWidget);
    expect(_pagination(tester).pageIndex, 1);
    expect(find.text('01 示例 A'), findsNothing);
    await _tap(tester, '重试');
    await tester.pumpAndSettle();
    expect(find.text('05 示例 B2'), findsOneWidget);
    expect(find.text('重试'), findsNothing);

    await _tap(tester, '下一页');
    await tester.pumpAndSettle();
    expect(find.text('12 示例 J'), findsOneWidget);
    expect(_button(tester, '下一页').onPressed, isNotNull);
  });

  testWidgets(
    'numbered navigation can skip directly to the final server page',
    (tester) async {
      await _open(tester);
      await tester.tap(find.widgetWithText(YumeiroButton, '12'));
      await tester.pumpAndSettle();
      expect(find.text('48 示例 48'), findsOneWidget);
      expect(_button(tester, '下一页').onPressed, isNull);
    },
  );

  testWidgets('pagination uses English names and labels at touch width', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      const YumeiroApp(
        modality: YumeiroModality.touch,
        locale: Locale('en'),
        home: Scaffold(body: Builder(builder: dataTablePaginationDemo)),
      ),
    );
    expect(find.text('Loading records'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('01 Example A'), findsOneWidget);
    _expectPaginationCentered(
      tester,
      previous: 'Previous page',
      next: 'Next page',
    );
    expect(find.byTooltip('Previous page'), findsOneWidget);
    expect(find.byTooltip('Next page'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'example b');
    await tester.pumpAndSettle();
    expect(_pagination(tester).pageCount, 1);
    expect(find.text('05 Example B2'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final fail in [false, true]) {
    testWidgets(
      'an older ${fail ? 'failure' : 'success'} cannot replace a new page',
      (tester) async {
        await _open(tester);
        if (fail) await _tap(tester, '模拟下次请求失败');
        await _tap(tester, '下一页');
        await _tap(tester, '上一页');
        await tester.pump(const Duration(milliseconds: 220));
        expect(find.text('01 示例 A'), findsOneWidget);
        await tester.pump(const Duration(milliseconds: 900));
        await tester.pumpAndSettle();
        expect(find.text('01 示例 A'), findsOneWidget);
        expect(find.text('05 示例 B2'), findsNothing);
        expect(find.text('加载失败'), findsNothing);
      },
    );
  }
}

YumeiroPagination _pagination(WidgetTester tester) =>
    tester.widget<YumeiroPagination>(find.byType(YumeiroPagination));

void _expectPaginationCentered(
  WidgetTester tester, {
  required String previous,
  required String next,
}) {
  final previousCenter = tester.getCenter(_buttonFinder(previous));
  final nextCenter = tester.getCenter(_buttonFinder(next));
  final table = find.byWidgetPredicate((widget) => widget is YumeiroDataTable);
  expect(
    (previousCenter.dx + nextCenter.dx) / 2,
    closeTo(tester.getCenter(table).dx, 0.01),
  );
}

Future<void> _open(
  WidgetTester tester, {
  YumeiroModality modality = YumeiroModality.pointer,
}) async {
  await tester.pumpWidget(
    YumeiroApp(
      modality: modality,
      locale: const Locale('zh'),
      home: const Scaffold(body: Builder(builder: dataTablePaginationDemo)),
    ),
  );
  expect(find.text('正在加载示例'), findsOneWidget);
  await tester.pumpAndSettle();
}

Finder _buttonFinder(String label) => find.byWidgetPredicate(
  (widget) =>
      widget is YumeiroButton &&
      (widget.label == label || widget.tooltip == label),
);

YumeiroButton _button(WidgetTester tester, String label) =>
    tester.widget<YumeiroButton>(_buttonFinder(label));

Future<void> _tap(WidgetTester tester, String label) async {
  await tester.tap(_buttonFinder(label));
  await tester.pump();
}
