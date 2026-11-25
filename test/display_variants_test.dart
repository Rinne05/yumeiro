import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yumeiro/yumeiro.dart';

void main() {
  testWidgets('section badge and callout action wrap below readable text', (
    tester,
  ) async {
    const title = 'Theme Style & Appearance';
    const message = 'Could not load records';
    const badge = 'Classic Dark';
    const action = 'Show example details';
    var opened = false;

    Future<void> pumpAt(double width, double scale) => tester.pumpWidget(
      YumeiroApp(
        modality: YumeiroModality.touch,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: Scaffold(
          body: SizedBox(
            width: width,
            child: Column(
              children: [
                const YumeiroSectionHeader(
                  title: title,
                  subtitle: 'Select a style',
                  trailing: YumeiroBadge(label: badge),
                ),
                YumeiroCallout(
                  message: message,
                  action: YumeiroButton(
                    label: action,
                    onPressed: () => opened = true,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final titleText = find.text(title);
    final badgeWidget = find.widgetWithText(YumeiroBadge, badge);
    final messageText = find.text(message);
    final actionButton = find.widgetWithText(YumeiroButton, action);

    await pumpAt(320, 2);
    expect(tester.takeException(), isNull);
    expect(tester.getSize(titleText).width, 320);
    expect(
      tester.getTopLeft(badgeWidget).dy,
      greaterThan(tester.getBottomLeft(find.text('Select a style')).dy),
    );
    expect(
      tester.getTopLeft(actionButton).dy,
      greaterThan(tester.getBottomLeft(messageText).dy),
    );
    expect(tester.getTopRight(actionButton).dx, lessThanOrEqualTo(320));
    await tester.tap(actionButton);
    expect(opened, isTrue);

    await pumpAt(760, 1);
    expect(tester.takeException(), isNull);
    final titleBounds = tester.getRect(titleText);
    final badgeBounds = tester.getRect(badgeWidget);
    expect(badgeBounds.left, greaterThan(titleBounds.right));
    expect(
      badgeBounds.top,
      lessThan(tester.getRect(find.text('Select a style')).bottom),
    );
    final messageBounds = tester.getRect(messageText);
    final actionBounds = tester.getRect(actionButton);
    expect(actionBounds.left, greaterThan(messageBounds.right));
    expect(actionBounds.center.dy, closeTo(messageBounds.center.dy, 1));
  });

  testWidgets('badges resolve tint, status, and muted treatments', (
    tester,
  ) async {
    const tint = Color(0xFF10B981);
    await tester.pumpWidget(
      const YumeiroApp(
        home: Scaffold(
          body: Wrap(
            children: [
              YumeiroBadge(
                label: 'Tinted',
                statusRole: YumeiroStatusRole.danger,
                tint: tint,
                emphasized: true,
              ),
              YumeiroBadge(
                label: 'Ready',
                statusRole: YumeiroStatusRole.success,
                icon: Icons.check,
              ),
              YumeiroBadge(label: 'Muted'),
            ],
          ),
        ),
      ),
    );

    final tintedFinder = find.text('Tinted');
    final theme = YumeiroTheme.of(tester.element(tintedFinder));
    final success = theme.visuals.status(YumeiroStatusRole.success);
    final tinted = tester.widget<Text>(tintedFinder);
    final ready = tester.widget<Text>(find.text('Ready'));
    final muted = tester.widget<Text>(find.text('Muted'));
    expect(tinted.style!.color, theme.visuals.customStatusForeground(tint));
    expect(ready.style!.color, success.foreground);
    expect(
      tester.widget<Icon>(find.byIcon(Icons.check)).color,
      success.foreground,
    );
    expect(muted.style!.color, theme.colors.muted);
    expect(tinted.style!.fontWeight, theme.typography.emphasisWeight);
    expect(muted.style!.fontWeight, theme.typography.bodyWeight);
    YumeiroVisualDelta badgeDelta(String label) => tester
        .widget<YumeiroVisualSurface>(
          find.descendant(
            of: find.widgetWithText(YumeiroBadge, label),
            matching: find.byType(YumeiroVisualSurface),
          ),
        )
        .visualOverride!
        .base;
    expect(
      (badgeDelta('Tinted').fill as YumeiroSolidFill).color,
      theme.visuals.customStatusFill(tint),
    );
    expect(
      (badgeDelta('Ready').fill as YumeiroSolidFill).color,
      success.subtleFill,
    );
    expect(badgeDelta('Muted').fill, isNull);
  });

  testWidgets('selectable chip truncates its label and announces selection', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    var tapped = false;
    const label = 'A selectable chip with a long label';
    await tester.pumpWidget(
      YumeiroApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 120,
              child: YumeiroChip(
                label: label,
                selected: true,
                onTap: () => tapped = true,
              ),
            ),
          ),
        ),
      ),
    );

    final chipLabel = find.text(label);
    final text = tester.widget<Text>(chipLabel);
    expect(text.maxLines, 1);
    expect(text.overflow, TextOverflow.ellipsis);
    final surface = tester.widget<YumeiroInteractiveVisualSurface>(
      find.descendant(
        of: find.byType(YumeiroChip),
        matching: find.byType(YumeiroInteractiveVisualSurface),
      ),
    );
    expect(surface.role, YumeiroControlRole.secondary);
    expect(surface.selected, isTrue);
    expect(tester.getSemantics(chipLabel), isSemantics(isSelected: true));
    semantics.dispose();
    await tester.tap(chipLabel);
    expect(tapped, isTrue);
  });

  testWidgets('selected chip uses its foreground and full height for removal', (
    tester,
  ) async {
    var tapped = false;
    var removed = false;
    await tester.pumpWidget(
      YumeiroApp(
        preset: YumeiroThemePresets.pixelDark,
        modality: YumeiroModality.touch,
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: YumeiroChip(
              label: 'Example',
              selected: true,
              onTap: () => tapped = true,
              onDeleted: () => removed = true,
            ),
          ),
        ),
      ),
    );

    final label = find.text('Example');
    final remove = find.byTooltip('Remove Example');
    final icon = find.descendant(of: remove, matching: find.byType(Icon));
    expect(
      tester.widget<Icon>(icon).color,
      IconTheme.of(tester.element(label)).color,
    );
    final bounds = tester.getRect(remove);
    expect(bounds.height, tester.getSize(find.byType(YumeiroChip)).height);
    await tester.tapAt(Offset(bounds.center.dx, bounds.top + 2));
    expect(removed, isTrue);
    expect(tapped, isFalse);
    await tester.tap(label);
    expect(tapped, isTrue);
  });

  testWidgets('centered error shows its title and retry state', (tester) async {
    const disabledError = ValueKey('disabled-error');
    const enabledError = ValueKey('enabled-error');
    var retried = false;
    await tester.pumpWidget(
      YumeiroApp(
        home: Scaffold(
          body: Column(
            children: [
              YumeiroErrorState(
                key: disabledError,
                message: 'Wait before retrying',
                retryEnabled: false,
                onRetry: () => retried = true,
              ),
              YumeiroErrorState(
                key: enabledError,
                title: 'Could not load records',
                message: 'Try again',
                onRetry: () => retried = true,
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Could not load records'), findsOneWidget);
    final context = tester.element(find.byKey(disabledError));
    final l10n = YumeiroLocalizations.of(context);
    expect(find.text(l10n.errorTitle), findsOneWidget);
    Finder retryButton(Key key) => find.descendant(
      of: find.byKey(key),
      matching: find.widgetWithText(YumeiroButton, l10n.retry),
    );
    final disabled = tester.widget<YumeiroButton>(retryButton(disabledError));
    expect(disabled.icon, YumeiroTheme.of(context).icons.refresh);
    expect(disabled.onPressed, isNull);
    await tester.tap(retryButton(enabledError));
    expect(retried, isTrue);
  });
}
