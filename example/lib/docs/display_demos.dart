import 'package:material_ui/material_ui.dart';
import 'package:yumeiro/yumeiro.dart';

// #region display
Widget displayDemo(BuildContext context) => const _DisplayDemo();

enum _DisplayScene { summary, loading, empty, error }

class _DisplayDemo extends StatefulWidget {
  const _DisplayDemo();

  @override
  State<_DisplayDemo> createState() => _DisplayDemoState();
}

class _DisplayDemoState extends State<_DisplayDemo> {
  var _scene = _DisplayScene.summary;
  var _showFilter = true;
  var _selected = false;

  void _show(_DisplayScene next) => setState(() => _scene = next);

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      YumeiroSegmentedControl<_DisplayScene>(
        options: const [
          YumeiroSegmentOption(value: _DisplayScene.summary, label: '标签与指标'),
          YumeiroSegmentOption(value: _DisplayScene.loading, label: '加载'),
          YumeiroSegmentOption(value: _DisplayScene.empty, label: '空内容'),
          YumeiroSegmentOption(value: _DisplayScene.error, label: '错误'),
        ],
        value: _scene,
        onChanged: _show,
      ),
      const SizedBox(height: 12),
      switch (_scene) {
        _DisplayScene.summary => _summary(),
        _DisplayScene.loading => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const YumeiroSpinner(label: '后台同步中'),
            const YumeiroLoadingCard(message: '正在读取收藏。'),
            YumeiroButton(
              label: '完成同步',
              onPressed: () => _show(_DisplayScene.summary),
            ),
          ],
        ),
        _DisplayScene.empty => YumeiroEmptyState(
          compact: true,
          title: '暂无收藏',
          message: '此列表目前没有可展示的条目。',
          action: YumeiroButton(
            label: '重新加载',
            variant: YumeiroButtonVariant.secondary,
            onPressed: () => _show(_DisplayScene.loading),
          ),
        ),
        _DisplayScene.error => YumeiroCallout(
          message: '收藏加载失败，请重试。',
          statusRole: YumeiroStatusRole.danger,
          action: YumeiroButton(
            label: YumeiroLocalizations.of(context).retry,
            onPressed: () => _show(_DisplayScene.loading),
          ),
        ),
      },
    ],
  );

  Widget _summary() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const YumeiroBadge(
            label: '已同步',
            statusRole: YumeiroStatusRole.success,
          ),
          const YumeiroBadge(
            label: '待确认',
            statusRole: YumeiroStatusRole.warning,
          ),
          const YumeiroBadge(
            label: '本地',
            tint: Color(0xFF3066A4),
            emphasized: true,
          ),
          const YumeiroBadge(label: '本周'),
          YumeiroChip(
            label: '共享收藏',
            selected: _selected,
            onTap: () => setState(() => _selected = !_selected),
          ),
          if (_showFilter)
            YumeiroChip(
              label: '仅显示收藏',
              onDeleted: () => setState(() => _showFilter = false),
            )
          else
            YumeiroButton(
              label: '恢复筛选',
              variant: YumeiroButtonVariant.ghost,
              onPressed: () => setState(() => _showFilter = true),
            ),
        ],
      ),
      const SizedBox(height: 12),
      const YumeiroCallout(
        title: '同步完成',
        message: '你的收藏已经更新。',
        statusRole: YumeiroStatusRole.success,
      ),
      const SizedBox(height: 12),
      const Wrap(
        spacing: 16,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          YumeiroStatTile(
            value: '12',
            label: '本周已同步',
            statusRole: YumeiroStatusRole.success,
          ),
          SizedBox(
            width: 150,
            child: YumeiroFieldLayout.readOnly(
              label: '同步记录 ID',
              value: 'sync-042',
              bottomSpacing: 0,
            ),
          ),
        ],
      ),
    ],
  );
}
// #endregion display

// #region media
Widget mediaDemo(BuildContext context) => const _MediaDemo();

enum _MediaScene { posters, images }

class _MediaDemo extends StatefulWidget {
  const _MediaDemo();

  @override
  State<_MediaDemo> createState() => _MediaDemoState();
}

class _MediaDemoState extends State<_MediaDemo> {
  // Small synthetic 2:3 covers embedded as PNGs, independent of host assets.
  static final _items = [
    (
      title: '晨雾信号',
      meta: '短片 · 12 分钟',
      tag: '预告片',
      rating: 4.5,
      image: _cover(
        'iVBORw0KGgoAAAANSUhEUgAAAB4AAAAtCAMAAACOACuTAAAAFVBMVEURIz4mUHten6nR7s8k'
        'aHAVOVB1s6aXqkPWAAAAeElEQVR42u3OQQ6AIAxE0UFa739kQ5HogC0mJsaFf1V8hQj83SqX'
        'QnQXcu48USe2Mzyt/h2e/PmME+vA+0I7jEzNeAl7hSViKTGohYa2IGTGwpGOLKKnEOHI2vFa'
        'MrHJPh4TgqvEehW8Z+uE4Gq7rW7wnq0TNOwZb1DHDG3LliB5AAAAAElFTkSuQmCC',
      ),
    ),
    (
      title: '岛屿来信',
      meta: '访谈 · 18 分钟',
      tag: '访谈',
      rating: 4.0,
      image: _cover(
        'iVBORw0KGgoAAAANSUhEUgAAAB4AAAAtCAMAAACOACuTAAAAFVBMVEU6JEN0O0/Pd1//2JaG'
        'TWxIKUrgm3LQCtbQAAAAeElEQVR42u3OQQ6AIAxE0UFa739kQ5HogC0mJsaFf1V8hQj83SqX'
        'QnQXcu48USe2Mzyt/h2e/PmME+vA+0I7jEzNeAl7hSViKTGohYa2IGTGwpGOLKKnEOHI2vFa'
        'MrHJPh4TgqvEehW8Z+uE4Gq7rW7wnq0TNOwZb1DHDG3LliB5AAAAAElFTkSuQmCC',
      ),
    ),
  ];

  static MemoryImage _cover(String png) => MemoryImage(
    Uri.parse('data:image/png;base64,$png').data!.contentAsBytes(),
  );

  var _scene = _MediaScene.posters;
  var _showImage = true;
  final _progress = <double>[.25, .5];
  int? _active;
  String? _action;

  void _open(int index) =>
      setState(() => _action = '已打开 · ${_items[index].title}');

  void _play(int index) => setState(() {
    _active = index;
    _progress[index] = _progress[index] == 1 ? .25 : _progress[index] + .25;
    _action =
        '播放 · ${_items[index].title} · ${(_progress[index] * 100).round()}%';
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      YumeiroSegmentedControl<_MediaScene>(
        options: const [
          YumeiroSegmentOption(value: _MediaScene.posters, label: '海报网格'),
          YumeiroSegmentOption(value: _MediaScene.images, label: '图片与结果行'),
        ],
        value: _scene,
        onChanged: (next) => setState(() => _scene = next),
      ),
      const SizedBox(height: 12),
      switch (_scene) {
        _MediaScene.posters => _posters(),
        _MediaScene.images => _images(context),
      },
      if (_action case final action?) ...[
        const SizedBox(height: 8),
        Semantics(liveRegion: true, child: Text(action)),
      ],
    ],
  );

  Widget _posters() => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 400),
    child: YumeiroPosterGrid(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      minimumTileWidth: 128,
      maximumColumns: 2,
      maxRows: 1,
      footerExtent: 56,
      itemCount: _items.length,
      itemBuilder: (context, index) {
        final item = _items[index];
        return YumeiroMediaCard(
          title: item.title,
          supportingLines: [item.meta],
          topLeft: YumeiroBadge.overlay(label: item.tag),
          rating: item.rating,
          image: item.image,
          progress: _progress[index],
          overlayActions: [
            Center(
              child: YumeiroMediaPlayButton(
                active: _active == index,
                tooltip: '播放${item.title}',
                onPressed: () => _play(index),
              ),
            ),
          ],
          onTap: () => _open(index),
        );
      },
    ),
  );

  Widget _images(BuildContext context) {
    final item = _items.first;
    final image = _showImage ? item.image : null;
    final theme = YumeiroTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const YumeiroAvatar(
              radius: 24,
              semanticLabel: '工作室头像',
              fallback: ColoredBox(
                color: Color(0xFF6456B3),
                child: Center(
                  child: Text('Y', style: TextStyle(color: Colors.white)),
                ),
              ),
            ),
            SizedBox(
              width: 100,
              height: 64,
              child: YumeiroArtworkImage(
                image: image,
                borderRadius: BorderRadius.circular(theme.radii.md),
                loading: const Center(child: YumeiroSpinner()),
                fallback: Center(
                  child: Text('封面暂缺', style: theme.typography.supporting),
                ),
                semanticLabel: image == null ? '封面暂缺' : '晨雾中的岛屿',
              ),
            ),
            YumeiroButton(
              label: _showImage ? '模拟缺图' : '恢复封面',
              variant: YumeiroButtonVariant.secondary,
              onPressed: () => setState(() => _showImage = !_showImage),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          '浏览历史',
          style: theme.typography.caption.copyWith(
            color: theme.accentSoft,
            fontWeight: theme.typography.headingWeight,
          ),
        ),
        const SizedBox(height: 6),
        YumeiroListTile.media(
          title: item.title,
          meta: item.meta,
          image: image,
          trailing: YumeiroStarRating(value: item.rating),
          onTap: () => _open(0),
        ),
        const SizedBox(height: 8),
        YumeiroProgress(value: _progress.first),
      ],
    );
  }
}
// #endregion media
