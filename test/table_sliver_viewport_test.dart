import 'dart:ui' show SemanticsRole;

import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yumeiro/src/components/layout/table_sliver_viewport.dart';

void main() {
  testWidgets(
    'pinned header and lazily mounted rows share horizontal position',
    (tester) async {
      final verticalController = ScrollController();
      final viewportWidth = ValueNotifier(280.0);
      final builtRows = <int>{};
      addTearDown(verticalController.dispose);
      addTearDown(viewportWidth.dispose);

      Widget content(String label) => Semantics(
        role: SemanticsRole.row,
        container: true,
        child: Semantics(
          role: SemanticsRole.cell,
          container: true,
          child: SizedBox(
            key: ValueKey(label),
            height: 50,
            child: Align(alignment: Alignment.centerLeft, child: Text(label)),
          ),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ValueListenableBuilder(
              valueListenable: viewportWidth,
              builder: (_, width, _) => SizedBox(
                width: width,
                height: 220,
                child: CustomScrollView(
                  controller: verticalController,
                  slivers: [
                    TableSliverViewport(
                      header: content('Header'),
                      pinnedHeader: true,
                      viewportWidth: width,
                      contentWidth: 720,
                      sliverBuilder: (fitRow) => SliverList.builder(
                        addSemanticIndexes: false,
                        itemCount: 200,
                        itemBuilder: (_, index) {
                          builtRows.add(index);
                          return fitRow(content('Row $index'));
                        },
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 220)),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      Offset position(String label) =>
          tester.getTopLeft(find.byKey(ValueKey(label)));

      expect(builtRows, isNot(contains(40)));
      await tester.drag(find.text('Row 0'), const Offset(-190, 0));
      await tester.pumpAndSettle();

      final scrolledHeader = position('Header');
      expect(scrolledHeader.dx, lessThan(-120));
      expect(position('Row 0').dx, scrolledHeader.dx);

      await tester.sendEventToBinding(
        const PointerScrollEvent(
          kind: PointerDeviceKind.mouse,
          position: Offset(200, 25),
          scrollDelta: Offset(100, 0),
        ),
      );
      await tester.pumpAndSettle();
      final wheelOffset = position('Header').dx;
      expect(wheelOffset, lessThan(scrolledHeader.dx));
      expect(position('Row 0').dx, wheelOffset);

      verticalController.jumpTo(2000);
      await tester.pumpAndSettle();

      expect(builtRows, contains(40));
      expect(position('Header'), Offset(wheelOffset, 0));
      expect(position('Row 40').dx, wheelOffset);

      viewportWidth.value = 600;
      await tester.pumpAndSettle();

      expect(position('Header').dx, -120);
      expect(position('Row 40').dx, -120);

      verticalController.jumpTo(verticalController.position.maxScrollExtent);
      await tester.pumpAndSettle();

      expect(find.text('Header').hitTestable(), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
