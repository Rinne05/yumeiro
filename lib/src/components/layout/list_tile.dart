import 'package:material_ui/material_ui.dart';

import '../../foundation/modality.dart';
import '../../foundation/typography.dart';
import '../../primitives/visual_surface.dart';
import '../../theme/theme.dart';
import '../../theme/visual_role.dart';
import '../display/media_images.dart';
import 'row_visuals.dart';

typedef _MediaTileContent = ({
  String title,
  String meta,
  ImageProvider<Object>? image,
  IconData? icon,
});

/// Content-first information and action row styled with [YumeiroItemRole].
class YumeiroListTile extends StatelessWidget {
  const YumeiroListTile({
    super.key,
    this.leading,
    required Widget this._title,
    this._subtitle,
    this.trailing,
    this.onTap,
    this.showChevron = true,
    this.tapIcon,
    this.selected,
    this.enabled = true,
    this.dense = false,
    this.padding,
    this.role = YumeiroItemRole.standard,
  }) : _media = null;

  /// Compact media result or history row, with a fixed thumbnail and metadata.
  const YumeiroListTile.media({
    super.key,
    required String title,
    required String meta,
    ImageProvider<Object>? image,
    IconData? icon,
    this.trailing,
    this.onTap,
  }) : _media = (title: title, meta: meta, image: image, icon: icon),
       _title = null,
       _subtitle = null,
       leading = null,
       showChevron = false,
       tapIcon = null,
       selected = null,
       enabled = true,
       dense = false,
       padding = const EdgeInsets.all(10),
       role = YumeiroItemRole.standard;

  final Widget? leading;
  Widget get title => _title ?? Text(_media!.title);
  Widget? get subtitle => _media == null ? _subtitle : Text(_media.meta);
  final Widget? trailing;
  final VoidCallback? onTap;
  final Widget? _title;
  final Widget? _subtitle;
  final _MediaTileContent? _media;

  /// Navigation chevron by default; menu and selection rows set this to false.
  final bool showChevron;

  /// Optional custom indicator replacing the default chevron when interactive.
  final IconData? tapIcon;

  /// Null for ordinary information/actions; false/true for selectable rows.
  final bool? selected;
  final bool enabled;
  final bool dense;
  final EdgeInsetsGeometry? padding;
  final YumeiroItemRole role;

  @override
  Widget build(BuildContext context) {
    final theme = YumeiroTheme.of(context);
    final metrics = YumeiroModalityScope.metricsOf(context);
    final media = _media;
    final mediaLines = metrics.isTouch ? 2 : 1;
    final standardRow =
        media == null && selected == null && role == YumeiroItemRole.standard;
    final heading = media == null
        ? RowHeading(
            title: _title!,
            subtitle: _subtitle,
            leading: standardRow ? leading : null,
            enabled: !standardRow || enabled,
            selected: selected,
            dense: dense,
          )
        : Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              YumeiroTextStyle(
                style: theme.typography.title,
                child: Text(
                  media.title,
                  maxLines: mediaLines,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                media.meta,
                maxLines: mediaLines,
                overflow: TextOverflow.ellipsis,
                style: theme.typography.supporting.copyWith(color: theme.muted),
              ),
            ],
          );
    final leadingContent = media == null
        ? (standardRow ? null : leading)
        : YumeiroArtworkImage.thumbnail(image: media.image, icon: media.icon);
    final row = Row(
      children: [
        if (leadingContent != null) ...[
          leadingContent,
          SizedBox(width: media == null ? theme.spacing.md : 12),
        ],
        Expanded(child: heading),
        if (trailing != null) ...[
          SizedBox(width: media == null ? theme.spacing.sm : 12),
          trailing!,
        ],
        if (onTap != null && enabled && (tapIcon != null || showChevron)) ...[
          SizedBox(width: theme.spacing.sm),
          rowNavigationIcon(
            context,
            icon: tapIcon,
            color: selected == true ? null : theme.muted,
          ),
        ],
      ],
    );

    final effectivePadding =
        padding ??
        (standardRow && !dense
            ? rowContentPadding(context)
            : EdgeInsets.all(dense ? theme.spacing.sm : theme.spacing.md));
    final content = media != null
        ? row
        : Padding(
            padding: effectivePadding,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: metrics.isTouch
                    ? metrics.minTargetSize
                    : dense
                    ? metrics.denseControlHeight
                    : metrics.minTargetSize,
              ),
              child: row,
            ),
          );
    final surfacePadding = media == null ? null : effectivePadding;
    final visualInsets = rowVisualInsets(context);
    final surface = onTap == null
        ? media != null || selected == true || !enabled
              ? YumeiroVisualSurface(
                  role: role,
                  states: {
                    if (selected == true) WidgetState.selected,
                    if (!enabled) WidgetState.disabled,
                  },
                  padding: surfacePadding,
                  visualInsets: visualInsets,
                  child: content,
                )
              : metrics.isTouch
              ? content
              : YumeiroVisualSurface(
                  role: YumeiroSurfaceRole.panel,
                  child: content,
                )
        : YumeiroInteractiveVisualSurface(
            role: role,
            selected: selected == true,
            onTap: enabled ? onTap : null,
            padding: surfacePadding,
            visualInsets: visualInsets,
            child: content,
          );

    return media != null
        ? surface
        : Semantics(selected: selected, enabled: enabled, child: surface);
  }
}
