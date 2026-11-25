import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yumeiro/yumeiro.dart';

void main() {
  for (final modality in YumeiroModality.values) {
    testWidgets(
      'pagination matches standard button sizing in ${modality.name}',
      (tester) async {
        await tester.pumpWidget(
          _host(
            Builder(
              builder: (context) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  YumeiroButton(
                    icon: YumeiroTheme.iconsOf(context).chevronLeft,
                    tooltip: 'Standard back button',
                    variant: YumeiroButtonVariant.ghost,
                    onPressed: () {},
                  ),
                  const YumeiroPagination(
                    pageIndex: 4,
                    pageCount: 24,
                    variant: YumeiroPaginationVariant.numbered,
                    onChanged: _ignorePage,
                  ),
                  const YumeiroPagination(
                    pageIndex: 4,
                    pageCount: 24,
                    variant: YumeiroPaginationVariant.compact,
                    onChanged: _ignorePage,
                  ),
                ],
              ),
            ),
            modality: modality,
          ),
        );
        final standard = find.byTooltip('Standard back button');
        final standardSize = tester.getSize(standard);
        final standardIcon = tester.getSize(
          find.descendant(of: standard, matching: find.byType(Icon)),
        );
        final previous = find.byTooltip('Previous page');
        expect(previous, findsNWidgets(2));
        for (var i = 0; i < 2; i++) {
          expect(tester.getSize(previous.at(i)), standardSize);
          expect(
            tester.getSize(
              find.descendant(of: previous.at(i), matching: find.byType(Icon)),
            ),
            standardIcon,
          );
        }
        final page = find.ancestor(
          of: find.text('5'),
          matching: find.byType(YumeiroButton),
        );
        expect(tester.getSize(page), standardSize);
        expect(
          tester.getSize(find.byTooltip('Go to page')).height,
          standardSize.height,
        );
      },
    );
  }

  testWidgets(
    'numbered pages preserve endpoints and request zero-based indices',
    (tester) async {
      final requested = <int>[];

      Future<void> show(int index) => tester.pumpWidget(
        _host(
          YumeiroPagination(
            pageIndex: index,
            pageCount: 24,
            variant: YumeiroPaginationVariant.numbered,
            onChanged: requested.add,
          ),
        ),
      );

      await show(4);
      await tester.pumpAndSettle();
      expect(_numberedLabels(tester), ['1', '4', '5', '6', '24']);
      final pagination = tester.element(find.byType(YumeiroPagination));
      expect(
        find.byIcon(YumeiroTheme.iconsOf(pagination).more),
        findsNWidgets(2),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel(RegExp(r'^Page 5$'))),
        isSemantics(isButton: true, isSelected: true),
      );

      await tester.tap(find.text('5'));
      expect(requested, isEmpty);
      await tester.tap(find.text('24'));
      expect(requested, [23]);
      expect(_button(tester, find.text('5')).selected, isTrue);

      await show(23);
      await tester.pumpAndSettle();
      expect(_numberedLabels(tester), ['1', '20', '21', '22', '23', '24']);
      expect(_button(tester, find.byTooltip('Next page')).onPressed, isNull);
      await tester.tap(find.byTooltip('Previous page'));
      expect(requested, [23, 22]);

      await show(0);
      await tester.pumpAndSettle();
      expect(_numberedLabels(tester), ['1', '2', '3', '4', '5', '24']);
      expect(
        _button(tester, find.byTooltip('Previous page')).onPressed,
        isNull,
      );
      await tester.tap(find.byTooltip('Next page'));
      expect(requested, [23, 22, 1]);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('automatic layout follows the local width in touch mode', (
    tester,
  ) async {
    final width = ValueNotifier(620.0);
    addTearDown(width.dispose);
    final requested = <int>[];
    await tester.pumpWidget(
      _host(
        ValueListenableBuilder(
          valueListenable: width,
          builder: (_, value, _) => SizedBox(
            width: value,
            child: YumeiroPagination(
              pageIndex: 4,
              pageCount: 24,
              onChanged: requested.add,
            ),
          ),
        ),
        modality: YumeiroModality.touch,
      ),
    );
    expect(_numberedLabels(tester), ['1', '4', '5', '6', '24']);
    expect(find.text('5 / 24'), findsNothing);

    width.value = 260;
    await tester.pumpAndSettle();
    expect(_numberedLabels(tester), isEmpty);
    expect(find.text('5 / 24'), findsOneWidget);
    final previous = find.byTooltip('Previous page');
    final next = find.byTooltip('Next page');
    expect(tester.getCenter(previous).dy, tester.getCenter(next).dy);
    expect(tester.getSize(previous).height, greaterThanOrEqualTo(44));
    await tester.tap(next);
    expect(requested, [5]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('compact jump validates input and keeps cancellation inert', (
    tester,
  ) async {
    final requested = <int>[];
    await tester.pumpWidget(
      _host(
        YumeiroPagination(
          pageIndex: 4,
          pageCount: 24,
          variant: YumeiroPaginationVariant.compact,
          onChanged: requested.add,
        ),
      ),
    );
    expect(find.bySemanticsLabel(RegExp(r'^Page 5 of 24$')), findsOneWidget);
    final current = find.text('5 / 24');
    await tester.tap(current);
    await tester.pumpAndSettle();
    expect(find.text('Go to page'), findsOneWidget);
    expect(find.byType(YumeiroDialog), findsOneWidget);

    await tester.enterText(find.byType(EditableText), '25');
    await tester.tap(find.widgetWithText(YumeiroButton, 'Confirm'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a page from 1 to 24.'), findsOneWidget);
    expect(requested, isEmpty);

    await tester.enterText(find.byType(EditableText), '17');
    await tester.tap(find.widgetWithText(YumeiroButton, 'Confirm'));
    await tester.pumpAndSettle();
    expect(find.byType(EditableText), findsNothing);
    expect(requested, [16]);

    await tester.tap(current);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(YumeiroButton, 'Cancel'));
    await tester.pumpAndSettle();
    expect(find.byType(EditableText), findsNothing);
    expect(requested, [16]);
  });

  for (final modality in YumeiroModality.values) {
    testWidgets('jump uses the current page count in ${modality.name}', (
      tester,
    ) async {
      final count = ValueNotifier(24);
      addTearDown(count.dispose);
      final requested = <int>[];
      await tester.pumpWidget(
        _host(
          ValueListenableBuilder(
            valueListenable: count,
            builder: (context, pageCount, child) => YumeiroPagination(
              pageIndex: 4,
              pageCount: pageCount,
              variant: YumeiroPaginationVariant.compact,
              onChanged: requested.add,
            ),
          ),
          modality: modality,
        ),
      );
      await tester.tap(find.text('5 / 24'));
      await tester.pumpAndSettle();
      final field = find.byType(EditableText);
      final confirm = find.widgetWithText(YumeiroButton, 'Confirm');
      await tester.enterText(field, '17');

      count.value = 12;
      await tester.pumpAndSettle();
      await tester.tap(confirm);
      await tester.pumpAndSettle();
      expect(requested, isEmpty);
      expect(find.text('Enter a page from 1 to 12.'), findsOneWidget);
      expect(tester.widget<EditableText>(field).controller.text, '17');

      count.value = 0;
      await tester.pumpAndSettle();
      await tester.tap(confirm);
      await tester.pumpAndSettle();
      expect(find.text('No matching items'), findsOneWidget);

      count.value = 26;
      await tester.pumpAndSettle();
      await tester.tap(confirm);
      await tester.pumpAndSettle();
      expect(requested, [16]);
      expect(field, findsNothing);
    });
  }

  testWidgets('touch jump stays above the keyboard and accepts Go', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final requested = <int>[];
    await tester.pumpWidget(
      _host(
        YumeiroPagination(
          pageIndex: 4,
          pageCount: 24,
          variant: YumeiroPaginationVariant.compact,
          onChanged: requested.add,
        ),
        modality: YumeiroModality.touch,
      ),
    );
    final current = find.text('5 / 24');
    await tester.tap(current);
    await tester.pumpAndSettle();

    final sheet = find.byType(YumeiroBottomSheet);
    final surface = find.descendant(
      of: sheet,
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is YumeiroVisualSurface &&
            widget.role == YumeiroSurfaceRole.modal,
      ),
    );
    expect(tester.getRect(surface).bottom, 700);
    tester.view.viewInsets = const FakeViewPadding(bottom: 330);
    await tester.pumpAndSettle();
    expect(tester.getRect(surface).bottom, 370);

    await tester.enterText(find.byType(EditableText), '25');
    await tester.testTextInput.receiveAction(TextInputAction.go);
    await tester.pumpAndSettle();
    expect(find.text('Enter a page from 1 to 24.'), findsOneWidget);
    expect(requested, isEmpty);

    await tester.enterText(find.byType(EditableText), '17');
    await tester.testTextInput.receiveAction(TextInputAction.go);
    await tester.pumpAndSettle();
    expect(sheet, findsNothing);
    expect(requested, [16]);

    tester.view.resetViewInsets();
    await tester.pumpAndSettle();
    await tester.tap(current);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(YumeiroButton, 'Cancel'));
    await tester.pumpAndSettle();
    expect(sheet, findsNothing);
    expect(requested, [16]);
  });

  testWidgets('arrow labels localize and follow direction and keyboard order', (
    tester,
  ) async {
    final requested = <int>[];
    await tester.pumpWidget(
      _host(
        Directionality(
          textDirection: TextDirection.rtl,
          child: YumeiroPagination(
            pageIndex: 1,
            pageCount: 3,
            onChanged: requested.add,
          ),
        ),
        locale: const Locale('zh'),
      ),
    );
    await tester.pumpAndSettle();
    final previous = find.byTooltip('上一页');
    final next = find.byTooltip('下一页');
    final icons = YumeiroTheme.iconsOf(tester.element(previous));
    expect(_button(tester, previous).icon, icons.chevronRight);
    expect(_button(tester, next).icon, icons.chevronLeft);
    expect(
      tester.getCenter(previous).dx,
      greaterThan(tester.getCenter(next).dx),
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(requested, [0]);
  });

  testWidgets(
    'empty, single-page and read-only states respect navigation limits',
    (tester) async {
      await tester.pumpWidget(
        _host(YumeiroPagination(pageIndex: 0, pageCount: 0, onChanged: (_) {})),
      );
      expect(find.byType(YumeiroButton), findsNothing);

      await tester.pumpWidget(
        _host(YumeiroPagination(pageIndex: 0, pageCount: 1, onChanged: (_) {})),
      );
      expect(_numberedLabels(tester), ['1']);
      expect(
        _button(tester, find.byTooltip('Previous page')).onPressed,
        isNull,
      );
      expect(_button(tester, find.byTooltip('Next page')).onPressed, isNull);

      await tester.pumpWidget(
        _host(
          const YumeiroPagination(pageIndex: 1, pageCount: 3, onChanged: null),
        ),
      );
      expect(_numberedLabels(tester), ['1', '2', '3']);
      expect(
        tester.widgetList<YumeiroButton>(find.byType(YumeiroButton)),
        everyElement(
          predicate<YumeiroButton>((button) => button.onPressed == null),
        ),
      );
    },
  );
}

void _ignorePage(int _) {}

Widget _host(
  Widget child, {
  Locale locale = const Locale('en'),
  YumeiroModality modality = YumeiroModality.pointer,
}) => YumeiroApp(
  locale: locale,
  modality: modality,
  home: Scaffold(body: Center(child: child)),
);

List<String> _numberedLabels(WidgetTester tester) => tester
    .widgetList<Text>(
      find.descendant(
        of: find.byType(YumeiroPagination),
        matching: find.byType(Text),
      ),
    )
    .map((label) => label.data)
    .whereType<String>()
    .where((label) => int.tryParse(label) != null)
    .toList();

YumeiroButton _button(WidgetTester tester, Finder content) => tester.widget(
  find.ancestor(of: content, matching: find.byType(YumeiroButton)),
);
