import 'package:material_ui/material_ui.dart';
import 'package:yumeiro/yumeiro.dart';

// #region color-picker
Widget colorPickerDemo(BuildContext context) {
  const inheritedColor = Color(0xFF087E8B);
  Color? override;
  return StatefulBuilder(
    builder: (context, setState) {
      final color = override ?? inheritedColor;
      final argb = color.toARGB32().toRadixString(16).padLeft(8, '0');
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          YumeiroColorPickerButton(
            value: override,
            defaultColor: inheritedColor,
            defaultLabel: '继承颜色',
            tooltip: '编辑标签颜色',
            presets: const [
              YumeiroColorPickerPreset(label: '湖蓝', color: Color(0xFF2874A6)),
              YumeiroColorPickerPreset(label: '夕照', color: Color(0xFFB85742)),
            ],
            onChanged: (value) => setState(() => override = value),
          ),
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          Text(override == null ? '继承 · #$argb' : '自定义 · #$argb'),
        ],
      );
    },
  );
}
// #endregion color-picker

// #region rows
Widget rowsDemo(BuildContext context) {
  var favorite = false;
  var quality = '自动';
  return StatefulBuilder(
    builder: (context, setState) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        YumeiroListTile(
          title: const Text('晨雾信号'),
          subtitle: Text(favorite ? '已收藏' : '点击收藏此条目'),
          selected: favorite,
          showChevron: false,
          onTap: () => setState(() => favorite = !favorite),
        ),
        const YumeiroListTile(
          title: Text('未下载的片段'),
          subtitle: Text('此条目暂不可用'),
          enabled: false,
        ),
        const SizedBox(height: 16),
        YumeiroSettingsSection(
          title: '播放设置',
          children: [
            YumeiroSettingRow(
              title: '默认画质',
              subtitle: '当前使用 $quality',
              editor: YumeiroSegmentedControl<String>(
                options: const [
                  YumeiroSegmentOption(value: '自动', label: '自动'),
                  YumeiroSegmentOption(value: '高清', label: '高清'),
                ],
                value: quality,
                onChanged: (value) => setState(() => quality = value),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
// #endregion rows

// #region toolbars
Widget toolbarsDemo(BuildContext context) {
  const titles = ['蓝色邮局', '午后列车', '蓝色港口'];
  final selected = <String>{};
  var query = '';
  var globalQuery = '';
  var reverse = false;
  return StatefulBuilder(
    builder: (context, setState) {
      final results = (reverse ? titles.reversed : titles)
          .where((title) => title.contains(query.trim()))
          .toList();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          YumeiroSearchToolbar(
            query: query,
            placeholder: '搜索任务名称',
            onQueryChanged: (value) => setState(() => query = value),
            onSort: () => setState(() => reverse = !reverse),
          ),
          const SizedBox(height: 8),
          YumeiroSelectionToolbar(
            selectedCount: selected.length,
            onClose: selected.isEmpty ? null : () => setState(selected.clear),
            onSelectAll: results.isEmpty
                ? null
                : () => setState(() => selected.addAll(results)),
          ),
          for (final title in results)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: YumeiroSelectionRow(
                card: true,
                title: Text(title),
                selected: selected.contains(title),
                onChanged: (checked) => setState(() {
                  if (checked) {
                    selected.add(title);
                  } else {
                    selected.remove(title);
                  }
                }),
              ),
            ),
          if (results.isEmpty) const Center(child: Text('没有匹配的任务')),
          const SizedBox(height: 12),
          YumeiroSearchHost(
            child: YumeiroSearchScope(
              query: globalQuery,
              placeholder: '全局搜索内容',
              onSubmitted: (value) => setState(() => globalQuery = value),
              child: Row(
                children: [
                  const YumeiroSearchButton(),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      globalQuery.isEmpty ? '全局搜索' : '全局搜索 · $globalQuery',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    },
  );
}
// #endregion toolbars
