import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yumeiro/yumeiro.dart';

void main() {
  for (final modality in YumeiroModality.values) {
    testWidgets(
      'pagination uses standard button sizing and theme fonts in ${modality.name}',
      (tester) async {
        await tester.pumpWidget(
          _host(
            const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                YumeiroButton(
                  icon: Icons.chevron_left,
                  tooltip: 'Standard back button',
                  variant: YumeiroButtonVariant.ghost,
                  onPressed: _doNothing,
                ),
                YumeiroPagination(
                  pageIndex: 4,
                  pageCount: 24,
                  variant: YumeiroPaginationVariant.numbered,
                  onChanged: _ignorePage,
                ),
                YumeiroPagination(
                  pageIndex: 4,
                  pageCount: 24,
                  variant: YumeiroPaginationVariant.compact,
                  onChanged: _ignorePage,
                ),
              ],
            ),
            modality: modality,
          ),
        );
        final previous = find.byTooltip('Previous page');
        expect(previous, findsNWidgets(2));
        final context = tester.element(previous.first);
        final metrics = YumeiroModalityScope.metricsOf(context);
        final standard = find.byTooltip('Standard back button');
        final target = tester.getSize(standard);
        final iconSize = tester.getSize(
          find.descendant(of: standard, matching: find.byType(Icon)),
        );
        for (var i = 0; i < 2; i++) {
          final arrow = previous.at(i);
          expect(tester.getSize(arrow), target);
          expect(
            tester.getSize(
              find.descendant(of: arrow, matching: find.byType(Icon)),
            ),
            iconSize,
          );
          if (metrics.isTouch) {
            final surface = tester.widget<YumeiroResolvedVisualSurface>(
              find.descendant(
                of: arrow,
                matching: find.byWidgetPredicate(
                  (widget) =>
                      widget is YumeiroResolvedVisualSurface &&
                      widget.visualInsets != null,
                ),
              ),
            );
            expect(
              target.height - surface.visualInsets!.vertical,
              metrics.controlHeight,
            );
          }
        }
        final page = find.ancestor(
          of: find.text('5'),
          matching: find.byType(YumeiroButton),
        );
        expect(tester.getSize(page), target);
        expect(
          tester.widget<YumeiroButton>(page).variant,
          YumeiroButtonVariant.primary,
        );
        final jump = find.byTooltip('Go to page');
        expect(tester.getSize(jump).height, target.height);
        expect(
          _button(tester, find.text('5 / 24')).variant,
          YumeiroButtonVariant.secondary,
        );
        final themeLabel = YumeiroTheme.of(context).typography.control();
        for (final label in ['5', '5 / 24']) {
          final text = tester.widget<Text>(find.text(label));
          expect(text.style!.fontFamily, themeLabel.fontFamily);
          expect(text.style!.fontFamilyFallback, themeLabel.fontFamilyFallback);
          expect(
            text.style!.fontFeatures,
            contains(const FontFeature.tabularFigures()),
          );
        }
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

  testWidgets('automatic layout stays stable across page windows', (
    tester,
  ) async {
    final state = ValueNotifier((index: 0, width: 700.0));
    addTearDown(state.dispose);
    await tester.pumpWidget(
      _host(
        ValueListenableBuilder(
          valueListenable: state,
          builder: (context, value, child) => SizedBox(
            width: value.width,
            child: YumeiroPagination(
              pageIndex: value.index,
              pageCount: 24,
              onChanged: _ignorePage,
            ),
          ),
        ),
      ),
    );
    final width =
        tester.getTopRight(find.byTooltip('Next page')).dx -
        tester.getTopLeft(find.byTooltip('Previous page')).dx;

    state.value = (index: 4, width: width - 1);
    await tester.pumpAndSettle();
    expect(find.text('5 / 24'), findsOneWidget);

    state.value = (index: 0, width: width - 1);
    await tester.pumpAndSettle();
    expect(find.text('1 / 24'), findsOneWidget);
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

  testWidgets(
    'compact pagination uses a passive readout when jump is unavailable',
    (tester) async {
      for (final count in [1, 3]) {
        await tester.pumpWidget(
          _host(
            YumeiroPagination(
              pageIndex: 0,
              pageCount: count,
              variant: YumeiroPaginationVariant.compact,
              onChanged: count == 1 ? _ignorePage : null,
            ),
          ),
        );
        expect(find.byTooltip('Go to page'), findsNothing);
        expect(find.bySemanticsLabel('Page 1 of $count'), findsOneWidget);
        expect(
          find.ancestor(
            of: find.text('1 / $count'),
            matching: find.byWidgetPredicate(
              (widget) =>
                  widget is YumeiroVisualSurface &&
                  widget.role == YumeiroSurfaceRole.readout,
            ),
          ),
          findsOneWidget,
        );
      }
    },
  );
}

void _ignorePage(int _) {}

void _doNothing() {}

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
