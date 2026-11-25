import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yumeiro/yumeiro.dart';

void main() {
  testWidgets('rating display and editor round to the same half star', (
    tester,
  ) async {
    await tester.pumpWidget(
      YumeiroApp(
        home: Scaffold(
          body: Column(
            children: [
              const YumeiroStarRating(value: 3.26),
              YumeiroRatingEditor(value: 3.26, onChanged: (_) {}),
            ],
          ),
        ),
      ),
    );

    final display = find.byType(YumeiroStarRating);
    final editor = find.byType(YumeiroRatingEditor);
    final icons = YumeiroTheme.of(tester.element(display)).icons;
    for (final rating in [display, editor]) {
      expect(
        find.descendant(of: rating, matching: find.byIcon(icons.starFilled)),
        findsNWidgets(3),
      );
      expect(
        find.descendant(of: rating, matching: find.byIcon(icons.starHalf)),
        findsOneWidget,
      );
    }
    expect(tester.widget<Slider>(find.byType(Slider)).value, 3.5);
  });
}
