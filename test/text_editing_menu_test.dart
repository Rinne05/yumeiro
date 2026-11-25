import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yumeiro/yumeiro.dart';
import 'package:yumeiro/src/components/overlays/picker_overlay.dart';

void main() {
  testWidgets('the in-app editing menu uses theme visuals and copies text', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String;
        }
        return null;
      },
    );
    addTearDown(() {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      );
    });
    final controller = TextEditingController(text: 'Example A');
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      YumeiroApp(
        home: Scaffold(
          body: Center(child: YumeiroTextField(controller: controller)),
        ),
      ),
    );
    final editable = find.byType(EditableText);
    await tester.showKeyboard(editable);
    controller.selection = const TextSelection(baseOffset: 0, extentOffset: 7);
    await tester.pump();
    final state = tester.state<EditableTextState>(editable);
    expect(state.copyEnabled, isTrue);
    expect(state.showToolbar(), isTrue);
    await tester.pumpAndSettle();

    final menu = find.byType(PickerFloatingSurface);
    expect(menu, findsOneWidget);
    final messages = MaterialLocalizations.of(tester.element(editable));
    final copy = find.descendant(
      of: menu,
      matching: find.text(messages.copyButtonLabel),
    );
    expect(
      copy,
      findsOneWidget,
      reason: tester
          .widgetList<Text>(
            find.descendant(of: menu, matching: find.byType(Text)),
          )
          .map((text) => text.data)
          .join(', '),
    );
    await tester.tap(copy);
    await tester.pumpAndSettle();
    expect(copied, 'Example');
  });
}
