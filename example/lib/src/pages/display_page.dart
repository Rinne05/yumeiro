import 'dart:async';

import 'package:flutter/foundation.dart' show SynchronousFuture;
import 'package:material_ui/material_ui.dart';
import 'package:yumeiro/yumeiro.dart';

import '../state/gallery_controller.dart';
import '../theme/gallery_registry.dart';
import '../widgets/gallery_widgets.dart';

/// Displays standalone component samples and image compositions.
class DisplayPage extends StatelessWidget {
  const DisplayPage({super.key, required this.controller});

  final GalleryController controller;

  @override
  Widget build(BuildContext context) {
    final spacing = YumeiroTheme.of(context).spacing;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: spacing.xl,
      children: [
        GallerySection(
          title: gText(context, en: 'Badges and readouts', zh: '徽章与信息'),
          children: [_badges(context), _metrics(context), _callouts(context)],
        ),
        GallerySection(
          title: gText(context, en: 'Feedback states', zh: '状态反馈'),
          children: [_loading(context), _emptyStates(context)],
        ),
        GallerySection(
          title: gText(context, en: 'Images and grids', zh: '图片与网格'),
          children: [_artwork(context), _posters(context)],
        ),
      ],
    );
  }

  Widget _badges(BuildContext context) {
    final theme = YumeiroTheme.of(context);
    final spacing = theme.spacing;
    return GalleryCard.example(
      example: GalleryExample.badges,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: spacing.lg,
        children: [
          GalleryComponent(
            'YumeiroBadge',
            child: Wrap(
              spacing: spacing.sm,
              runSpacing: spacing.sm,
              children: [
                YumeiroBadge(
                  label: gSample(context, 'Category A'),
                  icon: theme.icons.auto,
                ),
                for (final (label, role) in [
                  ('State A', YumeiroStatusRole.success),
                  ('State B', YumeiroStatusRole.neutral),
                  ('State C', YumeiroStatusRole.accent),
                  ('State D', YumeiroStatusRole.warning),
                  ('State E', YumeiroStatusRole.danger),
                  ('State F', YumeiroStatusRole.info),
                  ('State G', gallerySampleStatusRole),
                ])
                  YumeiroBadge(
                    label: gSample(context, label),
                    statusRole: role,
                  ),
              ],
            ),
          ),
          Wrap(
            spacing: spacing.lg,
            runSpacing: spacing.md,
            children: [
              GalleryComponent(
                'YumeiroBadge(dense: true)',
                child: YumeiroBadge(
                  label: gSample(context, 'Category A'),
                  icon: theme.icons.auto,
                  dense: true,
                ),
              ),
              GalleryComponent(
                'YumeiroBadge(emphasized: true)',
                child: YumeiroBadge(
                  label: gSample(context, 'Category A'),
                  icon: theme.icons.auto,
                  tint: theme.accent,
                  emphasized: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metrics(BuildContext context) {
    final spacing = YumeiroTheme.of(context).spacing;
    return GalleryCard.example(
      example: GalleryExample.metrics,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: spacing.lg,
        children: [
          GalleryComponent(
            'YumeiroStatTile',
            child: Wrap(
              spacing: spacing.md,
              runSpacing: spacing.sm,
              children: [
                for (final (label, value, role) in [
                  ('Metric A', '24', YumeiroStatusRole.neutral),
                  ('Metric B', '16', YumeiroStatusRole.success),
                  ('Metric C', '5', YumeiroStatusRole.accent),
                  ('Metric D', '2', YumeiroStatusRole.warning),
                  ('Metric E', '1', YumeiroStatusRole.danger),
                ])
                  YumeiroStatTile(
                    value: value,
                    label: gSample(context, label),
                    statusRole: role,
                  ),
              ],
            ),
          ),
          Wrap(
            spacing: spacing.lg,
            runSpacing: spacing.md,
            children: [
              GalleryComponent(
                'YumeiroMetricPill',
                child: YumeiroMetricPill(
                  label: gSample(context, 'Metric A'),
                  value: '24',
                ),
              ),
              GalleryComponent(
                'YumeiroMetricPill(items: …)',
                child: YumeiroMetricPill(
                  items: [
                    (label: gSample(context, 'Metric B'), value: '16'),
                    (label: gSample(context, 'Metric C'), value: '5'),
                  ],
                ),
              ),
            ],
          ),
          GalleryComponent(
            'YumeiroFieldLayout.readOnly',
            child: YumeiroFieldLayout.readOnly(
              label: gText(context, en: 'Field A', zh: '字段 A'),
              value: 'example-a',
              bottomSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _callouts(BuildContext context) {
    final spacing = YumeiroTheme.of(context).spacing;
    return GalleryCard.example(
      example: GalleryExample.callouts,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: spacing.lg,
        children: [
          GalleryComponent(
            'YumeiroCallout',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: spacing.sm,
              children: [
                for (final (suffix, role) in [
                  ('A', YumeiroStatusRole.neutral),
                  ('B', YumeiroStatusRole.success),
                  ('C', YumeiroStatusRole.warning),
                  ('D', YumeiroStatusRole.danger),
                ])
                  YumeiroCallout(
                    message: gText(
                      context,
                      en: 'Example message $suffix',
                      zh: '示例消息 $suffix',
                    ),
                    statusRole: role,
                  ),
              ],
            ),
          ),
          GalleryComponent(
            'YumeiroCallout(action: …)',
            child: SizedBox(
              width: double.infinity,
              child: YumeiroCallout(
                message: gText(context, en: 'Example message E', zh: '示例消息 E'),
                statusRole: YumeiroStatusRole.info,
                action: YumeiroButton(
                  label: gText(context, en: 'Show example', zh: '查看示例'),
                  onPressed: () => showYumeiroToast(
                    context,
                    gText(context, en: 'Example E', zh: '示例 E'),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _loading(BuildContext context) {
    final spacing = YumeiroTheme.of(context).spacing;
    final loading = gText(context, en: 'Loading…', zh: '加载中…');
    return GalleryCard.example(
      example: GalleryExample.loading,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: spacing.lg,
        children: [
          Wrap(
            spacing: spacing.lg,
            runSpacing: spacing.md,
            children: [
              const GalleryComponent('YumeiroSpinner', child: YumeiroSpinner()),
              GalleryComponent(
                'YumeiroSpinner(label: …)',
                child: YumeiroSpinner(label: loading),
              ),
            ],
          ),
          const GalleryComponent(
            'YumeiroProgress',
            child: YumeiroProgress(value: .65),
          ),
          const GalleryComponent(
            'YumeiroProgress(value: null)',
            child: YumeiroProgress(value: null),
          ),
          GalleryComponent(
            'YumeiroLoadingCard',
            child: YumeiroLoadingCard(message: loading),
          ),
        ],
      ),
    );
  }

  Widget _emptyStates(BuildContext context) {
    final spacing = YumeiroTheme.of(context).spacing;
    void retry() => showYumeiroToast(
      context,
      gText(context, en: 'Refresh requested.', zh: '已请求刷新。'),
      statusRole: YumeiroStatusRole.info,
    );
    final refresh = YumeiroButton(
      label: gText(context, en: 'Refresh', zh: '刷新'),
      variant: YumeiroButtonVariant.secondary,
      onPressed: retry,
    );
    final empty = gText(context, en: 'No results.', zh: '暂无结果。');
    final failed = gText(context, en: 'Could not load.', zh: '加载失败。');
    return GalleryCard.example(
      example: GalleryExample.emptyStates,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: spacing.lg,
        children: [
          GalleryComponent(
            'YumeiroEmptyState',
            child: SizedBox(
              width: double.infinity,
              child: YumeiroCard.panel(
                role: YumeiroSurfaceRole.inset,
                child: YumeiroEmptyState(message: empty, action: refresh),
              ),
            ),
          ),
          GalleryComponent(
            'YumeiroEmptyState(compact: true)',
            child: YumeiroEmptyState(
              compact: true,
              message: empty,
              action: refresh,
            ),
          ),
          GalleryComponent(
            'YumeiroErrorState',
            child: YumeiroCard.panel(
              role: YumeiroSurfaceRole.inset,
              child: YumeiroErrorState(message: failed, onRetry: retry),
            ),
          ),
        ],
      ),
    );
  }

  Widget _artwork(BuildContext context) {
    final spacing = YumeiroTheme.of(context).spacing;
    final media = GalleryController.mediaItems.take(2);
    return GalleryCard.example(
      example: GalleryExample.artwork,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: spacing.lg,
        children: [
          const _ArtworkComparison(),
          GalleryComponent(
            'YumeiroListTile.media',
            child: Column(
              spacing: spacing.xs,
              children: [
                for (final item in media)
                  YumeiroListTile.media(
                    title: gSample(context, item.title),
                    meta: gSample(context, item.meta),
                    image: identical(item, GalleryController.mediaItems.first)
                        ? _sampleCover
                        : null,
                    icon: item.icon,
                    onTap: () =>
                        showYumeiroToast(context, gSample(context, item.title)),
                  ),
              ],
            ),
          ),
          GalleryComponent(
            'YumeiroStarRating',
            child: Wrap(
              spacing: spacing.sm,
              runSpacing: spacing.sm,
              children: [
                for (final item in media) YumeiroStarRating(value: item.rating),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showPlayExample(BuildContext context) => showYumeiroToast(
    context,
    gText(context, en: 'Play button example triggered.', zh: '已点击播放示例按钮。'),
  );

  Widget _posters(BuildContext context) {
    final theme = YumeiroTheme.of(context);
    const media = GalleryController.mediaItems;
    return GalleryCard.example(
      example: GalleryExample.posters,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: theme.spacing.lg,
        children: [
          Wrap(
            spacing: theme.spacing.lg,
            runSpacing: theme.spacing.md,
            children: [
              GalleryComponent(
                'YumeiroBadge.overlay',
                child: SizedBox(
                  width: 72,
                  height: 86,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      YumeiroArtworkImage.thumbnail(image: _sampleCover),
                      const PositionedDirectional(
                        top: 5,
                        start: 5,
                        child: YumeiroBadge.overlay(label: 'A'),
                      ),
                    ],
                  ),
                ),
              ),
              GalleryComponent(
                'YumeiroMediaPlayButton',
                child: YumeiroMediaPlayButton(
                  onPressed: () => _showPlayExample(context),
                ),
              ),
              GalleryComponent(
                'YumeiroMediaPlayButton(active: false)',
                child: YumeiroMediaPlayButton(
                  active: false,
                  onPressed: () => _showPlayExample(context),
                ),
              ),
            ],
          ),
          GalleryComponent(
            'YumeiroMediaCard',
            child: SizedBox(
              width: 136,
              child: _posterCard(context, media.first, image: _sampleCover),
            ),
          ),
          GalleryComponent(
            'YumeiroPosterGrid(shrinkWrap: true)',
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: YumeiroPosterGrid(
                key: const ValueKey('display-poster-grid'),
                minimumTileWidth: 120,
                maximumColumns: 2,
                footerExtent: 96,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 2,
                itemBuilder: (context, index) => _posterCard(
                  context,
                  media[index],
                  image: index == 0 ? _sampleCover : null,
                ),
              ),
            ),
          ),
          GalleryComponent(
            'YumeiroPosterGrid(shrinkWrap: false)',
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: SizedBox(
                height: 380,
                width: double.infinity,
                child: PrimaryScrollController.none(
                  child: YumeiroPosterGrid(
                    minimumTileWidth: 120,
                    maximumColumns: 2,
                    footerExtent: 96,
                    itemCount: media.length,
                    itemBuilder: (context, index) => _posterCard(
                      context,
                      media[index],
                      image: index == 0 ? _sampleCover : null,
                    ),
                  ),
                ),
              ),
            ),
          ),
          GalleryComponent(
            'YumeiroPosterGrid.sliver',
            child: SizedBox(
              height: 420,
              child: CustomScrollView(
                key: const ValueKey('display-poster-viewport'),
                primary: false,
                slivers: [
                  YumeiroPosterGrid.sliver(
                    footerExtent: 96,
                    itemCount: media.length,
                    itemBuilder: (context, index) =>
                        _posterCard(context, media[index]),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _posterCard(
    BuildContext context,
    GalleryMediaItem item, {
    ImageProvider<Object>? image,
  }) => YumeiroMediaCard(
    title: gSample(context, item.title),
    supportingLines: [gSample(context, item.meta)],
    image: image,
    rating: item.rating,
    progress: item.progress,
    icon: item.icon,
    topLeft: YumeiroBadge.overlay(label: item.badge),
    overlayActions: [
      Center(
        child: YumeiroMediaPlayButton(
          onPressed: () => _showPlayExample(context),
        ),
      ),
    ],
    onTap: () => showYumeiroToast(
      context,
      gSample(context, item.title),
      statusRole: YumeiroStatusRole.info,
    ),
  );
}

enum _CoverState { ready, loading, failed }

class _ArtworkComparison extends StatefulWidget {
  const _ArtworkComparison();

  @override
  State<_ArtworkComparison> createState() => _ArtworkComparisonState();
}

class _ArtworkComparisonState extends State<_ArtworkComparison> {
  var _state = _CoverState.ready;

  @override
  Widget build(BuildContext context) {
    final theme = YumeiroTheme.of(context);
    final media = GalleryController.mediaItems.first;
    final unavailable = gText(context, en: 'Image unavailable', zh: '图片暂不可用');
    final loading = gText(context, en: 'Loading image', zh: '正在加载图片');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: theme.spacing.md,
      children: [
        GalleryComponent(
          'YumeiroSegmentedControl',
          child: YumeiroSegmentedControl<_CoverState>(
            options: [
              YumeiroSegmentOption(
                value: _CoverState.ready,
                label: gText(context, en: 'Ready', zh: '已加载'),
              ),
              YumeiroSegmentOption(
                value: _CoverState.loading,
                label: gText(context, en: 'Loading', zh: '加载中'),
              ),
              YumeiroSegmentOption(
                value: _CoverState.failed,
                label: gText(context, en: 'Failed', zh: '加载失败'),
              ),
            ],
            value: _state,
            onChanged: (state) => setState(() => _state = state),
          ),
        ),
        Wrap(
          spacing: theme.spacing.md,
          runSpacing: theme.spacing.md,
          children: [
            GalleryComponent(
              'YumeiroArtworkImage',
              child: SizedBox(
                width: 92,
                height: 138,
                child: YumeiroArtworkImage(
                  key: const ValueKey('display-cover'),
                  image: switch (_state) {
                    _CoverState.ready => _sampleCover,
                    _CoverState.loading => const _CoverPreviewImage(
                      fails: false,
                    ),
                    _CoverState.failed => const _CoverPreviewImage(fails: true),
                  },
                  borderRadius: BorderRadius.circular(theme.radii.md),
                  loading: _placeholder(loading),
                  fallback: _placeholder(unavailable),
                  semanticLabel: gText(
                    context,
                    en: 'Example image A',
                    zh: '示例图片 A',
                  ),
                ),
              ),
            ),
            GalleryComponent(
              'YumeiroArtworkImage.thumbnail',
              child: YumeiroArtworkImage.thumbnail(
                key: const ValueKey('display-thumbnail'),
                image: _sampleCover,
                icon: media.icon,
              ),
            ),
            GalleryComponent(
              'YumeiroAvatar',
              child: Wrap(
                spacing: theme.spacing.sm,
                children: [
                  YumeiroAvatar(image: _sampleCover),
                  YumeiroAvatar(
                    fallback: GalleryPosterArt(
                      startColor: media.startColor,
                      endColor: media.endColor,
                      icon: theme.icons.person,
                      iconSize: 20,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _placeholder(String text) => Center(
    child: Padding(
      padding: const EdgeInsets.all(8),
      child: Text(text, textAlign: TextAlign.center),
    ),
  );
}

// The synthetic 2:3 PNG also used in the media documentation demo.
final _sampleCover = MemoryImage(
  Uri.parse(
    'data:image/png;base64,'
    'iVBORw0KGgoAAAANSUhEUgAAAB4AAAAtCAMAAACOACuTAAAAFVBMVEURIz4mUHten6nR7s8k'
    'aHAVOVB1s6aXqkPWAAAAeElEQVR42u3OQQ6AIAxE0UFa739kQ5HogC0mJsaFf1V8hQj83SqX'
    'QnQXcu48USe2Mzyt/h2e/PmME+vA+0I7jEzNeAl7hSViKTGohYa2IGTGwpGOLKKnEOHI2vFa'
    'MrHJPh4TgqvEehW8Z+uE4Gq7rW7wnq0TNOwZb1DHDG3LliB5AAAAAElFTkSuQmCC',
  ).data!.contentAsBytes(),
);

/// Simulates a pending load or a failed image request.
class _CoverPreviewImage extends ImageProvider<_CoverPreviewImage> {
  const _CoverPreviewImage({required this.fails});

  final bool fails;

  @override
  Future<_CoverPreviewImage> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(
    _CoverPreviewImage key,
    ImageDecoderCallback decode,
  ) => OneFrameImageStreamCompleter(
    fails
        ? Future<ImageInfo>.error(StateError('Sample cover unavailable'))
        : Completer<ImageInfo>().future,
  );
}
