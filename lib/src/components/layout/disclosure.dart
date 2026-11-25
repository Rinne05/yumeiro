import 'package:material_ui/material_ui.dart';

import '../../foundation/modality.dart';
import '../../primitives/visual_surface.dart';
import '../../theme/theme.dart';
import '../../theme/visual_role.dart';

/// A controlled section with one header that expands or collapses its content.
///
/// Keep independent controls in [child] so the header has one activation
/// target. With [maintainState], form fields in a collapsed section remain
/// registered with their enclosing [Form]. The host can expand the section
/// when it wants to show a validation error.
///
/// Collapsed content is removed from focus traversal and accessibility. If
/// focus was in the body, collapsing returns it to the enabled header.
class YumeiroDisclosure extends StatefulWidget {
  const YumeiroDisclosure({
    super.key,
    required this.title,
    required this.child,
    required this.expanded,
    required this.onChanged,
    this.subtitle,
    this.leading,
    this.maintainState = true,
    this.focusNode,
  });

  final Widget title;
  final Widget child;
  final Widget? subtitle;
  final Widget? leading;

  /// Whether the body is visible. The host owns this state.
  final bool expanded;

  /// Requests the opposite of [expanded]. Null disables the header.
  final ValueChanged<bool>? onChanged;

  /// Keeps the body mounted while collapsed. Use false to dispose its state.
  final bool maintainState;

  /// Optional caller-owned focus node for the header.
  final FocusNode? focusNode;

  @override
  State<YumeiroDisclosure> createState() => _YumeiroDisclosureState();
}

class _YumeiroDisclosureState extends State<YumeiroDisclosure> {
  final _ownedHeaderFocus = FocusNode(debugLabel: 'Disclosure header');
  final _bodyFocus = FocusNode(debugLabel: 'Disclosure body');

  FocusNode get _headerFocus => widget.focusNode ?? _ownedHeaderFocus;

  @override
  void didUpdateWidget(covariant YumeiroDisclosure oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.expanded &&
        !widget.expanded &&
        _bodyFocus.hasFocus &&
        widget.onChanged != null) {
      if (oldWidget.onChanged != null) {
        _headerFocus.requestFocus();
      } else {
        // The header's focus widget only re-enables when this rebuild finishes.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !widget.expanded && widget.onChanged != null) {
            _headerFocus.requestFocus();
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _ownedHeaderFocus.dispose();
    _bodyFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = YumeiroTheme.of(context);
    final metrics = YumeiroModalityScope.metricsOf(context);
    final onChanged = widget.onChanged;
    final toggle = onChanged == null ? null : () => onChanged(!widget.expanded);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          container: true,
          button: true,
          enabled: toggle != null,
          expanded: widget.expanded,
          onExpand: widget.expanded ? null : toggle,
          onCollapse: widget.expanded ? toggle : null,
          child: YumeiroInteractiveVisualSurface(
            role: YumeiroItemRole.standard,
            onTap: toggle,
            focusNode: _headerFocus,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: metrics.minTargetSize),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: metrics.horizontalPadding,
                  vertical: theme.spacing.sm,
                ),
                child: Row(
                  spacing: theme.spacing.sm,
                  children: [
                    ?widget.leading,
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DefaultTextStyle.merge(
                            style: theme.typography.title,
                            child: widget.title,
                          ),
                          if (widget.subtitle case final subtitle?) ...[
                            SizedBox(height: theme.spacing.xs),
                            DefaultTextStyle.merge(
                              style: theme.typography.supporting.copyWith(
                                color: theme.muted,
                              ),
                              child: subtitle,
                            ),
                          ],
                        ],
                      ),
                    ),
                    ExcludeSemantics(
                      child: Icon(
                        widget.expanded
                            ? theme.icons.chevronUp
                            : theme.icons.chevronDown,
                        size: metrics.isTouch
                            ? theme.iconSizes.md
                            : theme.iconSizes.sm,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Visibility(
          visible: widget.expanded,
          maintainState: widget.maintainState,
          child: Focus(
            focusNode: _bodyFocus,
            canRequestFocus: false,
            skipTraversal: true,
            includeSemantics: false,
            child: widget.child,
          ),
        ),
      ],
    );
  }
}
