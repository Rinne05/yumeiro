import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yumeiro/yumeiro.dart';
import 'package:yumeiro_example/src/shell/gallery_shell.dart';
import 'package:yumeiro_example/src/state/gallery_controller.dart';
import 'package:yumeiro_example/src/theme/gallery_registry.dart';
import 'package:yumeiro_example/src/widgets/gallery_widgets.dart';

Future<GalleryController> _mountGallery(
  WidgetTester tester,
  YumeiroModality modality, {
  required int page,
}) async {
  tester.view.physicalSize = modality == YumeiroModality.touch
      ? const Size(390, 844)
      : const Size(1000, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final controller = GalleryController()..setNavIndex(page);
  addTearDown(controller.dispose);
  await tester.pumpWidget(
    ListenableBuilder(
      listenable: controller,
      builder: (context, _) => YumeiroApp(
        registry: controller.registry,
        preset: controller.activePreset,
        locale: controller.locale,
        modality: modality,
        capability: YumeiroMaterialCapability.blurOnly,
        home: GalleryShellPage(
          profile: modality == YumeiroModality.touch
              ? GalleryProfile.mobile
              : GalleryProfile.desktop,
          controller: controller,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return controller;
}

void main() {
  testWidgets('the selected Pixel Dark card uses its surface foreground', (
    tester,
  ) async {
    final controller = await _mountGallery(
      tester,
      YumeiroModality.pointer,
      page: 3,
    );
    controller.setThemeFamily('pixel');
    await tester.pumpAndSettle();
    expect(controller.activePreset.id, YumeiroThemePresets.pixelDark.id);

    final title = find.text('示例卡片');
    await tester.ensureVisible(title);
    await tester.pumpAndSettle();
    final theme = YumeiroTheme.of(tester.element(title));
    Color? foreground(Finder text) => tester
        .widget<RichText>(
          find.descendant(of: text, matching: find.byType(RichText)),
        )
        .text
        .style
        ?.color;
    expect(foreground(find.text('点击切换选中态')), theme.muted);

    await tester.tap(title);
    await tester.pumpAndSettle();
    final selected = theme.visuals.surface(YumeiroSurfaceRole.card, {
      WidgetState.selected,
    });
    expect(foreground(title), selected.foreground);
    expect(foreground(find.text('已选中 · 点击取消')), selected.foreground);
  });

  testWidgets('gallery dropdowns share row geometry and anchor spacing', (
    tester,
  ) async {
    final controller = await _mountGallery(
      tester,
      YumeiroModality.pointer,
      page: 1,
    );
    final comparison = find.byWidgetPredicate(
      (widget) =>
          widget is GalleryCard &&
          widget.example == GalleryExample.singleSelect,
    );
    Finder variant(String api) => find.descendant(
      of: comparison,
      matching: find.byWidgetPredicate(
        (widget) => widget is GalleryComponent && widget.api == api,
      ),
    );
    for (final api in [
      'YumeiroSelect',
      'YumeiroSelect.menu',
      'YumeiroSelect.searchable',
      'YumeiroSelect.searchable(onFreeTextSubmitted: …)',
    ]) {
      final component = variant(api);
      expect(
        find.descendant(of: component, matching: find.text(api)),
        findsOneWidget,
      );
      expect(
        tester.widget<GalleryComponent>(component).child,
        isA<YumeiroSelect<String>>(),
      );
    }

    double anchorGap(Rect trigger, Rect menu) =>
        menu.center.dy > trigger.center.dy
        ? menu.top - trigger.bottom
        : trigger.top - menu.bottom;

    final selectors = find.byWidgetPredicate(
      (widget) => widget is YumeiroSelect,
    );
    final menuSurface = find.byWidgetPredicate(
      (widget) =>
          widget is YumeiroVisualSurface &&
          widget.role == YumeiroSurfaceRole.floating,
    );

    Future<({double height, double inset, double gap})> measureMenu({
      required Finder trigger,
      required String selected,
      required String other,
      bool centered = false,
    }) async {
      await tester.ensureVisible(trigger);
      await tester.pumpAndSettle();
      await tester.tap(trigger);
      await tester.pumpAndSettle();
      final triggerBounds = tester.getRect(trigger);
      final rows = <Rect>[];
      Rect? menu;
      for (final label in [selected, other]) {
        final row = find.ancestor(
          of: find.text(label),
          matching: find.byType(MenuItemButton),
        );
        expect(row, findsOneWidget);
        final bounds = tester.getRect(row);
        rows.add(bounds);
        if (centered) {
          final rowLabel = find.descendant(of: row, matching: find.text(label));
          expect(tester.getCenter(rowLabel).dx, closeTo(bounds.center.dx, .5));
        }
        menu ??= tester.getRect(find.ancestor(of: row, matching: menuSurface));
      }
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(rows.first.height, closeTo(rows.last.height, .5));
      return (
        height: rows.first.height,
        inset: rows.first.left - menu!.left,
        gap: anchorGap(triggerBounds, menu),
      );
    }

    final fixed = await measureMenu(
      trigger: find.descendant(
        of: comparison,
        matching: find.byType(YumeiroSelect<String>),
      ),
      selected: '选项 B',
      other: '选项 A',
    );
    expect(fixed.gap, closeTo(4, .5));
    final toolbar = await measureMenu(
      trigger: find.byKey(const ValueKey('gallery-filter-select')),
      selected: '选项 B',
      other: '选项 D',
      centered: true,
    );
    final searchable = find.descendant(
      of: variant('YumeiroSelect.searchable(onFreeTextSubmitted: …)'),
      matching: selectors,
    );
    await tester.ensureVisible(searchable);
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(of: searchable, matching: find.byType(EditableText)),
    );
    await tester.pumpAndSettle();
    final searchableMenu = find.ancestor(
      of: find.byType(MenuItemButton).first,
      matching: menuSurface,
    );
    expect(
      anchorGap(tester.getRect(searchable), tester.getRect(searchableMenu)),
      closeTo(fixed.gap, .5),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    controller.setNavIndex(GalleryExample.settingSelect.pageIndex);
    await tester.pumpAndSettle();
    final setting = await measureMenu(
      trigger: find.descendant(
        of: find.byKey(const ValueKey('gallery-selection-setting')),
        matching: selectors,
      ),
      selected: '选项 A',
      other: '选项 B',
      centered: true,
    );
    for (final menu in [toolbar, setting]) {
      expect(menu.height, closeTo(fixed.height, .5));
      expect(menu.inset, closeTo(fixed.inset, .5));
      expect(menu.gap, closeTo(fixed.gap, .5));
    }
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('settings rows inset hovered and selected backgrounds', (
    tester,
  ) async {
    final controller = await _mountGallery(
      tester,
      YumeiroModality.pointer,
      page: 3,
    );
    final section = find.byWidgetPredicate(
      (widget) =>
          widget is YumeiroSettingsSection &&
          widget.title == GalleryExample.settingsRows.zh,
    );
    final tile = find.descendant(
      of: section,
      matching: find.byType(YumeiroListTile),
    );
    final selection = find.descendant(
      of: section,
      matching: find.byKey(const ValueKey('gallery-list-selection-row')),
    );
    Finder paintOf(Finder row) => find.descendant(
      of: row,
      matching: find.byType(YumeiroResolvedVisualSurface),
    );
    await tester.ensureVisible(tile);
    await tester.pumpAndSettle();

    final tilePaint = paintOf(tile);
    final resting = tester
        .widget<YumeiroResolvedVisualSurface>(tilePaint)
        .appearance;
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: const Offset(4, 4));
    await mouse.moveTo(tester.getCenter(tile));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<YumeiroResolvedVisualSurface>(tilePaint)
          .appearance
          .background,
      isNot(resting.background),
    );
    expect(controller.layoutSelectionValue, isTrue);

    final tileBounds = tester.getRect(tile);
    final selectedBounds = tester.getRect(selection);
    expect(tester.getRect(tilePaint), tileBounds.deflate(2));
    expect(tester.getRect(paintOf(selection)), selectedBounds.deflate(2));
    final line = YumeiroTheme.of(tester.element(section)).line;
    final divider = find.ancestor(
      of: tile,
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is DecoratedBox &&
            widget.position == DecorationPosition.foreground &&
            widget.decoration ==
                BoxDecoration(
                  border: Border(bottom: BorderSide(color: line)),
                ),
      ),
    );
    final dividerBounds = tester.getRect(divider);
    expect(dividerBounds.bottomLeft, tileBounds.bottomLeft);
    expect(dividerBounds.bottomRight, tileBounds.bottomRight);
    final selectionSample = find.ancestor(
      of: selection,
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is GalleryComponent && widget.api == 'YumeiroSelectionRow',
      ),
    );
    expect(tester.getRect(selectionSample).top, dividerBounds.bottom);
    expect(
      tester.getTopLeft(paintOf(selection)).dy -
          tester.getBottomLeft(tilePaint).dy,
      selectedBounds.top - tileBounds.bottom + 4,
    );

    await mouse.removePointer();
    final press = await tester.startGesture(
      Offset(selectedBounds.left + 1, selectedBounds.center.dy),
    );
    await tester.pumpAndSettle();
    expect(tester.getRect(paintOf(selection)), selectedBounds.deflate(2));
    expect(controller.layoutSelectionValue, isTrue);
    await press.up();
    await tester.pumpAndSettle();
    expect(controller.layoutSelectionValue, isFalse);
    await tester.tapAt(Offset(tileBounds.left + 1, tileBounds.center.dy));
    await tester.pumpAndSettle();
    expect(find.text('已点击列表项'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  for (final modality in YumeiroModality.values) {
    testWidgets('choice controls apply independent selections in $modality', (
      tester,
    ) async {
      final controller = await _mountGallery(tester, modality, page: 1);
      final isTouch = modality == YumeiroModality.touch;

      Finder sample(GalleryExample example) => find.byWidgetPredicate(
        (widget) => widget is GalleryCard && widget.example == example,
      );

      Future<void> tap(Finder finder) async {
        await tester.ensureVisible(finder);
        await tester.pumpAndSettle();
        await tester.tap(finder);
        await tester.pumpAndSettle();
      }

      await tap(
        find.descendant(
          of: sample(GalleryExample.singleSelect),
          matching: find.byType(YumeiroSelect<String>),
        ),
      );
      expect(
        find.byType(YumeiroBottomSheet),
        isTouch ? findsOne : findsNothing,
      );
      await tap(
        find.descendant(
          of: isTouch
              ? find.byType(YumeiroBottomSheet)
              : find.byType(MenuItemButton),
          matching: find.text('选项 A'),
        ),
      );
      expect(controller.selectValue, 'fast');
      expect(controller.multiSelectTags, {'Tag A', 'Tag B'});

      final tagSample = sample(GalleryExample.multiSelect);
      expect(
        find.descendant(of: tagSample, matching: find.text('确认后应用')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: tagSample,
          matching: find.byType(YumeiroSelectionList<String>),
        ),
        findsNothing,
      );
      final selectionSample = sample(GalleryExample.selectionList);
      for (final (api, multiple) in [
        ('YumeiroSelectionList', false),
        ('YumeiroSelectionList(multiple: true)', true),
      ]) {
        final variant = find.descendant(
          of: selectionSample,
          matching: find.byWidgetPredicate(
            (widget) => widget is GalleryComponent && widget.api == api,
          ),
        );
        final list = tester.widget<YumeiroSelectionList<String>>(
          find.descendant(
            of: variant,
            matching: find.byType(YumeiroSelectionList<String>),
          ),
        );
        expect(list.multiple, multiple);
      }

      final picker = find.descendant(
        of: tagSample,
        matching: find.byType(YumeiroMultiSelect<String>),
      );
      Finder pickerOption(String label) => find
          .descendant(
            of: isTouch ? find.byType(YumeiroBottomSheet) : picker,
            matching: find.text(label),
          )
          .hitTestable();
      await tap(picker);
      expect(
        find.byType(YumeiroBottomSheet),
        isTouch ? findsOne : findsNothing,
      );
      await tap(pickerOption('标签 C'));
      expect(controller.multiSelectTags, {'Tag A', 'Tag B'});
      await tap(find.text('确认（3）'));
      expect(controller.multiSelectTags, {'Tag A', 'Tag B', 'Tag C'});

      await tap(picker);
      await tap(pickerOption('标签 D'));
      if (isTouch) {
        await tester.binding.handlePopRoute();
      } else {
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      }
      await tester.pumpAndSettle();
      expect(controller.multiSelectTags, {'Tag A', 'Tag B', 'Tag C'});
      expect(controller.selectedTags, {'Tag A', 'Tag B'});
      expect(controller.selectValue, 'fast');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('layout samples do not change control samples in $modality', (
      tester,
    ) async {
      final controller = await _mountGallery(tester, modality, page: 3);
      final layoutSwitch = find.byType(YumeiroSwitch);
      await tester.ensureVisible(layoutSwitch);
      await tester.pumpAndSettle();
      await tester.tap(layoutSwitch);
      await tester.pumpAndSettle();
      final selectionRow = find.byKey(
        const ValueKey('gallery-list-selection-row'),
      );
      await tester.ensureVisible(selectionRow);
      await tester.pumpAndSettle();
      await tester.tap(selectionRow);
      await tester.pumpAndSettle();
      expect(controller.layoutSwitchValue, isFalse);
      expect(controller.layoutSelectionValue, isFalse);
      expect(controller.switchValue, isTrue);
      expect(controller.checkboxValue, isTrue);

      final sampleCard = find.text('示例卡片');
      await tester.ensureVisible(sampleCard);
      await tester.pumpAndSettle();
      final card = find
          .ancestor(of: sampleCard, matching: find.byType(YumeiroCard))
          .first;
      final cardSize = tester.getSize(card);
      await tester.tap(sampleCard);
      await tester.pumpAndSettle();
      expect(controller.previewCardSelected, isTrue);
      expect(tester.getSize(card), cardSize);
      expect(controller.selectedRows, isEmpty);

      await tester.tap(find.text('交互控件'));
      await tester.pumpAndSettle();
      final controlSwitch = find.byWidgetPredicate(
        (widget) =>
            widget is YumeiroSwitch &&
            widget.onChanged == controller.setSwitchValue,
      );
      final controlCheckbox = find.byWidgetPredicate(
        (widget) =>
            widget is YumeiroCheckbox &&
            widget.onChanged == controller.setCheckboxValue,
      );
      expect(tester.widget<YumeiroSwitch>(controlSwitch).value, isTrue);
      expect(tester.widget<YumeiroCheckbox>(controlCheckbox).value, isTrue);
      await tester.ensureVisible(controlSwitch);
      await tester.pumpAndSettle();
      await tester.tap(controlSwitch);
      await tester.pumpAndSettle();
      await tester.tap(controlSwitch);
      await tester.pumpAndSettle();
      await tester.ensureVisible(controlCheckbox);
      await tester.pumpAndSettle();
      await tester.tap(controlCheckbox);
      await tester.pumpAndSettle();
      await tester.tap(controlCheckbox);
      await tester.pumpAndSettle();
      expect(controller.switchValue, isTrue);
      expect(controller.checkboxValue, isTrue);
      expect(controller.layoutSwitchValue, isFalse);
      expect(controller.layoutSelectionValue, isFalse);

      await tester.tap(find.text('布局导航'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<YumeiroSwitch>(find.byType(YumeiroSwitch)).value,
        isFalse,
      );
      expect(
        tester.widget<YumeiroSelectionRow>(selectionRow).selected,
        isFalse,
      );
      expect(controller.previewCardSelected, isTrue);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets(
      'form validation follows its text without losing focus in $modality',
      (tester) async {
        final controller = await _mountGallery(tester, modality, page: 1);
        final form = find.byWidgetPredicate(
          (widget) =>
              widget is GalleryComponent &&
              widget.api == 'YumeiroTextField.form',
        );
        final field = find.descendant(
          of: form,
          matching: find.byType(TextField),
        );
        final editable = find.descendant(
          of: form,
          matching: find.byType(EditableText),
        );
        await tester.ensureVisible(field);
        await tester.pumpAndSettle();
        await tester.tap(field);
        await tester.pumpAndSettle();
        final editableElement = tester.element(editable);
        final focus = tester.widget<EditableText>(editable).focusNode;
        expect(focus.hasFocus, isTrue);
        expect(find.text('请输入文本'), findsNothing);
        var galleryNotifications = 0;
        controller.addListener(() => galleryNotifications++);

        controller.formFieldController.clear();
        await tester.pumpAndSettle();
        expect(find.text('请输入文本'), findsOneWidget);
        expect(tester.element(editable), same(editableElement));
        expect(focus.hasFocus, isTrue);
        controller.formFieldController.text = '   ';
        await tester.pumpAndSettle();
        expect(find.text('请输入文本'), findsOneWidget);
        controller.formFieldController.text = 'Valid draft';
        await tester.pumpAndSettle();
        expect(find.text('请输入文本'), findsNothing);
        expect(find.text('输入非空文本可通过校验。'), findsOneWidget);
        expect(tester.element(editable), same(editableElement));
        expect(focus.hasFocus, isTrue);

        await tester.enterText(field, '');
        await tester.pumpAndSettle();
        expect(find.text('请输入文本'), findsOneWidget);
        await tester.enterText(field, 'Typed draft');
        await tester.pumpAndSettle();
        expect(find.text('请输入文本'), findsNothing);
        expect(tester.element(editable), same(editableElement));
        expect(focus.hasFocus, isTrue);
        expect(controller.switchValue, isTrue);
        expect(controller.layoutSwitchValue, isTrue);
        expect(galleryNotifications, 0);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
    testWidgets(
      'token input deduplicates visible labels across locales in $modality',
      (tester) async {
        final controller = await _mountGallery(tester, modality, page: 1);
        final tokens = find.byType(YumeiroTokenInput<String>);
        final field = find.descendant(
          of: tokens,
          matching: find.byType(TextField),
        );
        await tester.ensureVisible(field);
        await tester.pumpAndSettle();

        Future<void> submit(String value) async {
          await tester.enterText(field, value);
          await tester.pumpAndSettle();
          await tester.testTextInput.receiveAction(TextInputAction.done);
          await tester.pumpAndSettle();
        }

        await submit('标签 A');
        expect(controller.tokens, ['Tag A', 'Tag B', 'Tag C']);
        expect(
          find.descendant(of: tokens, matching: find.text('标签 A')),
          findsOneWidget,
        );
        await submit('  我的自定义标签  ');
        expect(controller.tokens, ['Tag A', 'Tag B', 'Tag C', '我的自定义标签']);
        expect(
          find.descendant(of: tokens, matching: find.text('我的自定义标签')),
          findsOneWidget,
        );

        controller.setLocale(const Locale('en'));
        await tester.pumpAndSettle();
        await submit('标签 A');
        expect(controller.tokens, ['Tag A', 'Tag B', 'Tag C', '我的自定义标签']);
        expect(
          find.descendant(of: tokens, matching: find.text('Tag A')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: tokens, matching: find.text('我的自定义标签')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
}
