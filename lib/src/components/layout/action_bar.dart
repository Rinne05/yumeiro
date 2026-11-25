import 'package:material_ui/material_ui.dart';

import '../../primitives/backdrop_group.dart';
import '../../primitives/visual_surface.dart';
import '../../theme/visual_role.dart';

const yumeiroActionBarInset = 16.0;

/// Sticky touch-friendly submit bar where the primary action spans full width
/// and secondary actions arrange cleanly underneath.
class YumeiroActionBar extends StatelessWidget {
  const YumeiroActionBar({
    super.key,
    required this.primaryAction,
    this.secondaryActions = const <Widget>[],
    this.showBackground = true,
  });

  final Widget primaryAction;
  final List<Widget> secondaryActions;

  /// Disable when an enclosing dialog or sheet already owns the panel surface.
  final bool showBackground;

  @override
  Widget build(BuildContext context) {
    final content = YumeiroBackdropGroup(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          primaryAction,
          if (secondaryActions.isNotEmpty) ...[
            const SizedBox(height: 8),
            if (secondaryActions.length <= 2)
              Row(
                children: [
                  for (var i = 0; i < secondaryActions.length; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    Expanded(child: secondaryActions[i]),
                  ],
                ],
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: secondaryActions,
              ),
          ],
        ],
      ),
    );
    return showBackground
        ? YumeiroVisualSurface(
            role: YumeiroSurfaceRole.panel,
            padding: const EdgeInsets.all(yumeiroActionBarInset),
            child: content,
          )
        : Padding(
            padding: const EdgeInsets.all(yumeiroActionBarInset),
            child: content,
          );
  }
}
