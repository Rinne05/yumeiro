import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yumeiro/yumeiro.dart';

class _RowModel {
  const _RowModel(this.id, this.name);
  final String id;
  final String name;
}

void main() {
  group('Migrated display, layout, and navigation', () {
    testWidgets(
      'display widgets render status badges, removable chips, media cards, and rows',
      (tester) async {
        var chipSelected = false;
        var chipDeleted = false;
        var mediaTapped = false;
        var playTapped = false;

        await tester.pumpWidget(
          YumeiroApp(
            home: Scaffold(
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: StatefulBuilder(
                  builder: (context, setState) => Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const YumeiroSectionHeader(
                        title: 'Status and media',
                        eyebrow: 'Section Eyebrow',
                      ),
                      const Wrap(
                        spacing: 8,
                        children: [
                          YumeiroBadge(
                            label: 'Online',
                            tint: Color(0xFF10B981),
                            emphasized: true,
                          ),
                          YumeiroBadge(maxLines: null, label: 'v1.0'),
                          YumeiroBadge.overlay(label: 'HD'),
                          YumeiroMetricPill(label: 'Latency', value: '4ms'),
                          YumeiroAvatar(radius: 16),
                        ],
                      ),
                      const SizedBox(height: 8),
                      YumeiroChip(
                        label: 'Tag Chip',
                        selected: chipSelected,
                        onTap: () =>
                            setState(() => chipSelected = !chipSelected),
                        onDeleted: () => setState(() => chipDeleted = true),
                      ),
                      const YumeiroFieldLayout.readOnly(
                        label: 'Token Path',
                        value: 'YumeiroTheme.of(context)',
                      ),
                      const YumeiroProgress(value: 0.7),
                      const YumeiroStarRating(value: 3.5),
                      YumeiroListTile.media(
                        title: 'Result Entry',
                        meta: 'Subtitle meta',
                        trailing: YumeiroMediaPlayButton(
                          onPressed: () => setState(() => playTapped = true),
                        ),
                        onTap: () {},
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: SizedBox(
                          width: 180,
                          child: YumeiroMediaCard(
                            title: 'Poster Card',
                            supportingLines: const ['Details'],
                            progress: 0.5,
                            rating: 4.5,
                            topLeft: const YumeiroBadge.overlay(label: 'NEW'),
                            onTap: () => setState(() => mediaTapped = true),
                          ),
                        ),
                      ),
                      YumeiroPosterGrid(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: 2,
                        itemBuilder: (context, i) => YumeiroMediaCard(
                          title: 'Grid #$i',
                          supportingLines: ['Meta $i'],
                        ),
                      ),
                      YumeiroErrorState(message: 'Load failed', onRetry: () {}),
                      YumeiroActionRow(
                        leading: const Text('Leading'),
                        actions: [YumeiroButton(label: 'Go', onPressed: () {})],
                      ),
                      const YumeiroDivider(height: 24, touchHeight: 1),
                      const YumeiroSettingRow(
                        title: 'Setting Tile',
                        subtitle: 'Subtitle',
                      ),
                      const YumeiroListTile(
                        dense: true,
                        title: Text('Compact List Tile'),
                        subtitle: Text('Dense subtitle'),
                      ),
                      if (chipDeleted) const Text('Chip Deleted'),
                      if (mediaTapped) const Text('Media Tapped'),
                      if (playTapped) const Text('Play Tapped'),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );

        expect(find.text('SECTION EYEBROW'), findsOneWidget);

        await tester.tap(find.text('Tag Chip'));
        await tester.pumpAndSettle();
        expect(chipSelected, isTrue);

        await tester.tap(find.byTooltip('Remove Tag Chip'));
        await tester.pumpAndSettle();
        expect(chipDeleted, isTrue);

        await tester.ensureVisible(find.byType(YumeiroMediaPlayButton));
        await tester.tap(find.byType(YumeiroMediaPlayButton));
        await tester.pumpAndSettle();
        expect(playTapped, isTrue);

        await tester.ensureVisible(find.text('Poster Card'));
        await tester.tap(find.text('Poster Card'));
        await tester.pumpAndSettle();
        expect(mediaTapped, isTrue);
      },
    );

    testWidgets(
      'YumeiroDataTable adapts between pointer table and touch compact rows',
      (tester) async {
        const items = [_RowModel('1', 'Alpha'), _RowModel('2', 'Beta')];
        var selected = <Key>{};

        await tester.pumpWidget(
          YumeiroApp(
            modality: YumeiroModality.pointer,
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) => YumeiroDataTable<_RowModel>(
                  items: items,
                  selection: YumeiroTableSelection(
                    mode: YumeiroTableSelectionMode.multiple,
                    selectedKeys: selected,
                    onChanged: (next) => setState(() => selected = next),
                  ),
                  columns: [
                    YumeiroTableColumn(
                      title: 'ID',
                      cellBuilder: (_, item, _) => Text(item.id),
                    ),
                    YumeiroTableColumn(
                      title: 'Name',
                      cellBuilder: (_, item, _) => Text(item.name),
                    ),
                  ],
                  compactRowBuilder: (_, item, _) =>
                      Text('Compact ${item.name}'),
                ),
              ),
            ),
          ),
        );

        expect(find.text('Alpha'), findsOneWidget);
        expect(find.text('Compact Alpha'), findsNothing);

        // Select All checkbox in pointer table
        await tester.tap(find.byType(YumeiroCheckbox).first);
        await tester.pumpAndSettle();
        expect(selected.length, 2);

        // Switch to touch modality -> uses compactRowBuilder
        await tester.pumpWidget(
          YumeiroApp(
            modality: YumeiroModality.touch,
            home: Scaffold(
              body: YumeiroDataTable<_RowModel>(
                items: items,
                selection: YumeiroTableSelection(
                  mode: YumeiroTableSelectionMode.multiple,
                  selectedKeys: selected,
                  onChanged: (_) {},
                ),
                columns: [
                  YumeiroTableColumn(
                    title: 'Name',
                    cellBuilder: (_, item, _) => Text(item.name),
                  ),
                ],
                compactRowBuilder: (_, item, _) => Text('Compact ${item.name}'),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Compact Alpha'), findsOneWidget);
        expect(find.text('Compact Beta'), findsOneWidget);
      },
    );

    testWidgets(
      'paged top navigation keeps tabs, pages, and persistent controls in sync',
      (tester) async {
        var tab = 'first';
        var filterCount = 0;
        await tester.pumpWidget(
          YumeiroApp(
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) => YumeiroTopNavigation.paged(
                  value: tab,
                  destinations: const [
                    YumeiroTopNavigationDestination(
                      value: 'first',
                      label: 'First Tab',
                    ),
                    YumeiroTopNavigationDestination(
                      value: 'second',
                      label: 'Second Tab',
                    ),
                  ],
                  onChanged: (next) => setState(() => tab = next),
                  itemBuilder: (_, value) => Center(child: Text('Page:$value')),
                  between: YumeiroButton(
                    label: 'Filter $filterCount',
                    onPressed: () => setState(() => filterCount++),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(find.text('Page:first'), findsOneWidget);
        await tester.tap(find.text('Filter 0'));
        await tester.pumpAndSettle();
        final toolbar = tester.getRect(find.byType(YumeiroButton));
        expect(toolbar.bottom, tester.getTopLeft(find.byType(PageView)).dy);
        final indicator = find.descendant(
          of: find.byType(YumeiroTopNavigation<String>),
          matching: find.byType(AnimatedPositioned),
        );
        final initialLeft = tester.widget<AnimatedPositioned>(indicator).left!;
        final pager = tester
            .widget<PageView>(find.byType(PageView))
            .controller!;
        pager.jumpTo(pager.position.viewportDimension / 4);
        await tester.pump();
        expect(tab, 'first');
        expect(
          tester.widget<AnimatedPositioned>(indicator).left,
          greaterThan(initialLeft),
        );

        await tester.tap(find.text('Second Tab'));
        await tester.pumpAndSettle();
        expect(tab, 'second');
        expect(find.text('Page:second'), findsOneWidget);
        expect(find.text('Filter 1'), findsOneWidget);
        expect(tester.getRect(find.byType(YumeiroButton)), toolbar);

        await tester.drag(find.byType(PageView), const Offset(600, 0));
        await tester.pumpAndSettle();
        expect(tab, 'first');
        expect(find.text('Page:first'), findsOneWidget);
        expect(find.text('Filter 1'), findsOneWidget);
      },
    );

    testWidgets('pager remount takes its controlled value from the host', (
      tester,
    ) async {
      final storage = PageStorageBucket();
      var selected = 0;
      var showPager = true;
      var taps = 0;
      late StateSetter update;
      await tester.pumpWidget(
        YumeiroApp(
          home: Scaffold(
            body: PageStorage(
              bucket: storage,
              child: StatefulBuilder(
                builder: (context, setState) {
                  update = setState;
                  if (!showPager) return const SizedBox.shrink();
                  return YumeiroNavigationPager<int>(
                    key: const PageStorageKey('controlled pager'),
                    value: selected,
                    values: const [0, 1],
                    onChanged: (value) => setState(() => selected = value),
                    itemBuilder: (context, value) => Center(
                      child: YumeiroButton(
                        label: 'Page $value',
                        onPressed: () => taps++,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );
      await tester.drag(find.byType(PageView), const Offset(-650, 0));
      await tester.pumpAndSettle();
      expect(selected, 1);

      update(() => showPager = false);
      await tester.pumpAndSettle();
      update(() {
        selected = 0;
        showPager = true;
      });
      await tester.pumpAndSettle();

      await tester.tap(find.text('Page 0'));
      expect(taps, 1);
    });

    testWidgets('pager can retry a page change the host declined', (
      tester,
    ) async {
      final requests = <int>[];
      var selected = 0;
      var accept = false;
      var pressed = 0;
      await tester.pumpWidget(
        YumeiroApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => YumeiroTopNavigation.paged(
                value: selected,
                destinations: const [
                  YumeiroTopNavigationDestination(value: 0, label: 'First'),
                  YumeiroTopNavigationDestination(value: 1, label: 'Second'),
                ],
                onChanged: (value) {
                  requests.add(value);
                  if (accept) setState(() => selected = value);
                },
                itemBuilder: (context, value) => Center(
                  child: YumeiroButton(
                    label: 'Page $value',
                    onPressed: () => pressed++,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      final pager = find.byType(PageView);
      await tester.drag(pager, const Offset(-650, 0));
      await tester.pumpAndSettle();
      expect(requests, [1]);
      await tester.tap(find.text('Page 0'));
      expect(pressed, 1);

      accept = true;
      await tester.tap(find.text('Second'));
      await tester.pumpAndSettle();
      expect(requests, [1, 1]);
      await tester.tap(find.text('Page 1'));
      expect(pressed, 2);
    });

    for (final modality in YumeiroModality.values) {
      testWidgets('search keeps focus as actions come and go in $modality', (
        tester,
      ) async {
        var loaded = false;
        late StateSetter update;
        await tester.pumpWidget(
          YumeiroApp(
            modality: modality,
            locale: const Locale('en'),
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) {
                  update = setState;
                  return YumeiroSearchToolbar(
                    onQueryChanged: (_) {},
                    onFilter: loaded ? () {} : null,
                  );
                },
              ),
            ),
          ),
        );

        final input = find.byType(EditableText);
        await tester.enterText(input, 'draft');
        await tester.pumpAndSettle();
        final initial = tester.widget<EditableText>(input);
        expect(initial.focusNode.hasFocus, isTrue);

        for (final show in [true, false]) {
          update(() => loaded = show);
          await tester.pumpAndSettle();
          final active = tester.widget<EditableText>(input);
          expect(active.focusNode, same(initial.focusNode));
          expect(active.focusNode.hasFocus, isTrue);
          expect(active.controller.text, 'draft');
          expect(
            find.byTooltip('Filter'),
            show ? findsOneWidget : findsNothing,
          );
        }
      });
    }

    testWidgets(
      'search toolbar accepts a controller as its only query source',
      (tester) async {
        final controller = TextEditingController(text: 'initial search');
        final focus = FocusNode();
        addTearDown(controller.dispose);
        addTearDown(focus.dispose);
        var changed = '';
        var submitted = '';
        await tester.pumpWidget(
          YumeiroApp(
            home: Scaffold(
              body: YumeiroSearchToolbar(
                controller: controller,
                focusNode: focus,
                onQueryChanged: (value) => changed = value,
                onSubmitted: (value) => submitted = value,
              ),
            ),
          ),
        );
        expect(find.text('initial search'), findsOneWidget);
        controller.text = 'external search';
        await tester.pump();
        expect(find.text('external search'), findsOneWidget);
        await tester.enterText(find.byType(TextField), 'edited search');
        expect(controller.text, 'edited search');
        expect(changed, 'edited search');
        expect(focus.hasFocus, isTrue);
        expect(
          tester.widget<TextField>(find.byType(TextField)).textInputAction,
          TextInputAction.search,
        );
        await tester.testTextInput.receiveAction(TextInputAction.search);
        expect(submitted, 'edited search');
      },
    );

    testWidgets(
      'narrow touch toolbar keeps search editable when all actions are present',
      (tester) async {
        tester.view.physicalSize = const Size(288, 720);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final controller = TextEditingController();
        final focus = FocusNode();
        addTearDown(controller.dispose);
        addTearDown(focus.dispose);
        var filtersOpened = 0;

        await tester.pumpWidget(
          YumeiroApp(
            modality: YumeiroModality.touch,
            locale: const Locale('en'),
            home: Scaffold(
              body: YumeiroSearchToolbar(
                controller: controller,
                focusNode: focus,
                onQueryChanged: (_) {},
                onFilter: () => filtersOpened++,
                onSort: () {},
                onMore: () {},
              ),
            ),
          ),
        );

        final input = find.byType(EditableText);
        final filter = find.byTooltip('Filter');
        await tester.enterText(input, 'Example');
        await tester.pumpAndSettle();
        expect(tester.getSize(input).width, greaterThan(100));
        expect(
          tester.getTopLeft(filter).dy,
          greaterThan(tester.getBottomLeft(input).dy),
        );

        tester.view.physicalSize = const Size(600, 720);
        await tester.pumpAndSettle();
        expect(
          tester.getCenter(filter).dy,
          closeTo(tester.getCenter(input).dy, 1),
        );
        expect(controller.text, 'Example');
        expect(focus.hasFocus, isTrue);
        await tester.tap(filter);
        expect(filtersOpened, 1);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'YumeiroSearchToolbar, YumeiroSelectionToolbar, and Scaffolds render',
      (tester) async {
        var query = '';
        var selectAllTapped = false;
        var saved = false;

        await tester.pumpWidget(
          YumeiroApp(
            home: YumeiroPageScaffold.detail(
              title: 'Detail View',
              body: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  YumeiroSearchToolbar(
                    query: query,
                    onQueryChanged: (v) => query = v,
                    onFilter: () {},
                    filterCount: 2,
                    onSort: () {},
                    onMore: () {},
                  ),
                  const SizedBox(height: 12),
                  YumeiroSelectionToolbar(
                    selectedCount: 3,
                    onClose: () {},
                    onSelectAll: () => selectAllTapped = true,
                    actions: [YumeiroButton(label: 'Batch', onPressed: () {})],
                  ),
                  SizedBox(
                    height: 280,
                    child: YumeiroEditor(
                      title: 'Edit Item',
                      actions: [
                        YumeiroButton(
                          label: 'Save',
                          onPressed: () => saved = true,
                        ),
                      ],
                      child: const Text('Form Body'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        await tester.enterText(find.byType(TextField), 'search term');
        expect(query, 'search term');

        await tester.tap(find.text('Select All'));
        expect(selectAllTapped, isTrue);

        await tester.tap(find.text('Save'));
        expect(saved, isTrue);
      },
    );
  });
}
