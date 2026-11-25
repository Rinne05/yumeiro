import 'package:material_ui/material_ui.dart';
import 'package:yumeiro/yumeiro.dart';

// #region buttons
Widget buttonsDemo(BuildContext context) => const _ButtonsDemo();

class _ButtonsDemo extends StatefulWidget {
  const _ButtonsDemo();

  @override
  State<_ButtonsDemo> createState() => _ButtonsDemoState();
}

class _ButtonsDemoState extends State<_ButtonsDemo> {
  bool _saved = false;
  bool _favorite = false;
  String _status = '尚未执行操作';

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          YumeiroButton(
            label: _saved ? '已保存' : '保存',
            variant: YumeiroButtonVariant.primary,
            onPressed: () => setState(() {
              _saved = true;
              _status = '已保存';
            }),
          ),
          YumeiroButton(
            label: '重置',
            variant: YumeiroButtonVariant.secondary,
            onPressed: _saved
                ? () => setState(() {
                    _saved = false;
                    _status = '已重置';
                  })
                : null,
          ),
          YumeiroButton(
            label: _favorite ? '已收藏' : '收藏',
            selected: _favorite,
            onPressed: () => setState(() {
              _favorite = !_favorite;
              _status = _favorite ? '已收藏' : '已取消收藏';
            }),
          ),
          YumeiroButton(
            label: '移除',
            variant: YumeiroButtonVariant.danger,
            onPressed: () => setState(() => _status = '触发移除操作'),
          ),
          YumeiroButton(
            label: '跳过',
            variant: YumeiroButtonVariant.ghost,
            onPressed: () => setState(() => _status = '已跳过'),
          ),
          const YumeiroButton(label: '禁用', onPressed: null),
          YumeiroButton(
            variant: YumeiroButtonVariant.ghost,
            icon: YumeiroTheme.of(context).icons.info,
            tooltip: '查看保存状态',
            onPressed: () => showYumeiroToast(context, _saved ? '已保存' : '尚未保存'),
          ),
        ],
      ),
      const SizedBox(height: 12),
      Wrap(
        spacing: 12,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF13394C), Color(0xFF604C89)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: YumeiroButton(
                label: '播放预告',
                icon: Icons.play_arrow_rounded,
                variant: YumeiroButtonVariant.mediaOverlay,
                onPressed: () => setState(() => _status = '已播放预告'),
              ),
            ),
          ),
          Semantics(liveRegion: true, child: Text(_status)),
        ],
      ),
    ],
  );
}
// #endregion buttons

// #region inputs
Widget inputsDemo(BuildContext context) => const _InputsDemo();

enum _InputScene { text, form, tokens }

class _InputsDemo extends StatefulWidget {
  const _InputsDemo();

  @override
  State<_InputsDemo> createState() => _InputsDemoState();
}

class _InputsDemoState extends State<_InputsDemo> {
  final _nickname = TextEditingController();
  final _password = TextEditingController();
  final _query = TextEditingController();
  final _taskForm = GlobalKey<FormState>();
  var _scene = _InputScene.text;
  var _tags = <String>['沿海', '实时'];
  String? _taskName;
  String? _taskStation;
  String? _taskNameError;
  String? _savedTask;

  @override
  void dispose() {
    _nickname.dispose();
    _password.dispose();
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      YumeiroSegmentedControl<_InputScene>(
        value: _scene,
        options: const [
          YumeiroSegmentOption(value: _InputScene.text, label: '文本与密码'),
          YumeiroSegmentOption(value: _InputScene.form, label: '表单与搜索'),
          YumeiroSegmentOption(value: _InputScene.tokens, label: '标签'),
        ],
        onChanged: (value) => setState(() => _scene = value),
      ),
      const SizedBox(height: 16),
      if (_scene == _InputScene.text) _buildTextFields(),
      Visibility(
        key: const ValueKey('task-form-scene'),
        visible: _scene == _InputScene.form,
        maintainState: true,
        child: _buildFormAndSearch(),
      ),
      if (_scene == _InputScene.tokens)
        YumeiroTokenInput<String>(
          title: '台站标签',
          subtitle: '输入标签后按回车或点击添加',
          placeholder: '添加标签',
          values: _tags,
          onChanged: (values) => setState(() => _tags = values),
        ),
    ],
  );

  Widget _buildTextFields() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      YumeiroTextField(
        controller: _nickname,
        hintText: '输入昵称',
        semanticLabel: '昵称',
        clearable: true,
      ),
      const SizedBox(height: 12),
      YumeiroTextField(
        controller: _password,
        hintText: '输入示例密码',
        semanticLabel: '示例密码',
        obscureToggle: true,
      ),
      const SizedBox(height: 12),
      ValueListenableBuilder<TextEditingValue>(
        valueListenable: _nickname,
        builder: (context, value, child) =>
            Text(value.text.isEmpty ? '尚未输入昵称' : '当前昵称 · ${value.text}'),
      ),
    ],
  );

  Widget _buildFormAndSearch() {
    const stations = ['海岸台', '山地台', '森林台'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Form(
          key: _taskForm,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              YumeiroTextField.form(
                label: '任务名称',
                required: true,
                helperText: '输入「例行巡检」可模拟服务端返回重名错误。',
                hintText: '输入任务名称',
                clearable: true,
                maxLength: 40,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                forceErrorText: _taskNameError,
                validator: (value) =>
                    (value ?? '').trim().isEmpty ? '请输入任务名称' : null,
                onChanged: (_) {
                  if (_taskNameError != null) {
                    setState(() => _taskNameError = null);
                  }
                },
                onSaved: (value) => _taskName = value?.trim(),
              ),
              YumeiroSelect.form<String>(
                label: '执行台站',
                searchable: true,
                required: true,
                helperText: '从登记名单中搜索负责这项任务的台站。',
                options: [
                  for (final station in stations)
                    YumeiroSelectionOption(value: station, label: station),
                ],
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (value) => value == null ? '请选择执行台站' : null,
                onSaved: (value) => _taskStation = value,
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  YumeiroButton(
                    label: '保存任务',
                    variant: YumeiroButtonVariant.primary,
                    onPressed: _saveTask,
                  ),
                  YumeiroButton(
                    label: '重置表单',
                    variant: YumeiroButtonVariant.secondary,
                    onPressed: _resetTask,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Semantics(liveRegion: true, child: Text(_savedTask ?? '尚未保存任务')),
            ],
          ),
        ),
        const SizedBox(height: 16),
        YumeiroTextField.search(controller: _query, hintText: '搜索已登记台站'),
        const SizedBox(height: 8),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: _query,
          builder: (context, value, child) {
            final matches = stations.where(
              (station) => station.contains(value.text.trim()),
            );
            return Text(
              matches.isEmpty ? '没有匹配台站' : '结果 · ${matches.join('、')}',
            );
          },
        ),
      ],
    );
  }

  void _saveTask() {
    final form = _taskForm.currentState!;
    if (!form.validate()) return;
    form.save();

    setState(() {
      if (_taskName == '例行巡检') {
        _taskNameError = '已有同名任务，请换一个名称';
        _savedTask = null;
      } else {
        _savedTask = '已保存 · $_taskName（$_taskStation）';
      }
    });
  }

  void _resetTask() {
    _taskForm.currentState!.reset();
    setState(() {
      _taskNameError = null;
      _savedTask = null;
    });
  }
}
// #endregion inputs

// #region selection
Widget selectionDemo(BuildContext context) => const _SelectionDemo();

enum _SelectionScene { menus, toggles, hierarchy }

class _SelectionDemo extends StatefulWidget {
  const _SelectionDemo();

  @override
  State<_SelectionDemo> createState() => _SelectionDemoState();
}

class _SelectionDemoState extends State<_SelectionDemo> {
  var _scene = _SelectionScene.menus;
  var _format = '自动';
  var _filter = '全部';
  String? _station;
  var _stationStatus = '尚未选择台站';
  bool? _sync;
  var _remember = true;
  var _defaultQuality = false;
  var _view = '列表';
  var _profile = '均衡';
  String? _location;
  var _sort = '名称排序';

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      YumeiroSegmentedControl<_SelectionScene>(
        value: _scene,
        options: const [
          YumeiroSegmentOption(value: _SelectionScene.menus, label: '下拉'),
          YumeiroSegmentOption(value: _SelectionScene.toggles, label: '开关与分段'),
          YumeiroSegmentOption(
            value: _SelectionScene.hierarchy,
            label: '级联与设置',
          ),
        ],
        onChanged: (value) => setState(() => _scene = value),
      ),
      const SizedBox(height: 16),
      switch (_scene) {
        _SelectionScene.menus => _buildMenus(context),
        _SelectionScene.toggles => _buildToggles(),
        _SelectionScene.hierarchy => _buildHierarchy(),
      },
    ],
  );

  Widget _buildMenus(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          YumeiroSelect<String>(
            title: '选择画质',
            options: const [
              YumeiroSelectionOption(value: '自动', label: '自动'),
              YumeiroSelectionOption(value: '高清', label: '高清'),
              YumeiroSelectionOption(value: '超清', label: '超清', enabled: false),
            ],
            value: _format,
            onChanged: (value) => setState(() => _format = value),
          ),
          YumeiroSelect<String>.menu(
            value: _filter,
            width: 148,
            icon: YumeiroTheme.of(context).icons.filter,
            displayText: '筛选 · $_filter',
            selected: _filter != '全部',
            options: const [
              YumeiroSelectionOption(value: '全部', label: '全部'),
              YumeiroSelectionOption(value: '在线', label: '在线'),
              YumeiroSelectionOption(value: '离线', label: '离线', enabled: false),
            ],
            onChanged: (value) => setState(() => _filter = value),
          ),
        ],
      ),
      const SizedBox(height: 12),
      YumeiroSelect<String>.searchable(
        value: _station,
        placeholder: '搜索台站或输入自定义名称',
        expand: true,
        options: const [
          YumeiroSelectionOption(value: '海岸台', label: '海岸台', subtitle: '沿海'),
          YumeiroSelectionOption(value: '山地台', label: '山地台', subtitle: '山区'),
          YumeiroSelectionOption(value: '临时台', label: '临时台', enabled: false),
        ],
        onChanged: (value) => setState(() {
          _station = value;
          _stationStatus = value == null ? '已清空台站' : '从列表选择 · $value';
        }),
        onFreeTextSubmitted: (value) => setState(() {
          _station = value;
          _stationStatus = '输入自定义台站 · $value';
        }),
      ),
      const SizedBox(height: 8),
      Text(_stationStatus),
    ],
  );

  Widget _buildToggles() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      YumeiroSettingRow(
        title: '记住本次选择',
        trailing: YumeiroSwitch(
          semanticLabel: '记住本次选择',
          value: _remember,
          onChanged: (value) => setState(() => _remember = value),
        ),
      ),
      const SizedBox(height: 8),
      YumeiroCheckbox(
        label: switch (_sync) {
          null => '同步台站 · 部分选中',
          true => '同步台站 · 已选中',
          false => '同步台站 · 未选中',
        },
        value: _sync,
        tristate: true,
        onChanged: (value) => setState(() => _sync = value),
      ),
      const SizedBox(height: 8),
      YumeiroSelectionRow(
        card: true,
        title: const Text('设为默认画质'),
        subtitle: const Text('点击整行切换'),
        selected: _defaultQuality,
        onChanged: (value) => setState(() => _defaultQuality = value),
      ),
      const SizedBox(height: 16),
      YumeiroSegmentedControl<String>(
        value: _view,
        options: const [
          YumeiroSegmentOption(value: '列表', label: '列表'),
          YumeiroSegmentOption(value: '网格', label: '网格'),
          YumeiroSegmentOption(value: '时间线', label: '时间线', enabled: false),
        ],
        onChanged: (value) => setState(() => _view = value),
      ),
      const SizedBox(height: 12),
      YumeiroSegmentedControl.vertical<String>(
        value: _profile,
        options: const [
          YumeiroSegmentOption(value: '均衡', label: '均衡', subtitle: '自动安排后台同步'),
          YumeiroSegmentOption(value: '省电', label: '省电', subtitle: '仅在应用打开时同步'),
        ],
        onChanged: (value) => setState(() => _profile = value),
      ),
    ],
  );

  Widget _buildHierarchy() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      YumeiroCascadingSelect<String>(
        title: '选择存放位置',
        value: _location,
        width: 184,
        options: const [
          YumeiroCascadingOption.branch(
            id: 'local',
            label: '本机',
            children: [
              YumeiroCascadingOption(
                id: 'downloads',
                label: '下载目录',
                value: 'local/downloads',
              ),
              YumeiroCascadingOption(
                id: 'archive',
                label: '归档目录',
                value: 'local/archive',
              ),
            ],
          ),
          YumeiroCascadingOption.branch(
            id: 'network',
            label: '共享存储',
            children: [
              YumeiroCascadingOption(
                id: 'team',
                label: '团队目录',
                value: 'network/team',
              ),
            ],
          ),
        ],
        onChanged: (value) => setState(() => _location = value),
      ),
      if (_location != null) ...[
        const SizedBox(height: 8),
        Text('保存的位置 ID · $_location'),
      ],
      const SizedBox(height: 12),
      YumeiroSettingRow.select<String>(
        title: '目录排序',
        subtitle: '指针模式用下拉框，触控模式用选择面板。',
        value: _sort,
        options: const [
          YumeiroSelectionOption(value: '名称排序', label: '名称排序'),
          YumeiroSelectionOption(value: '最近修改', label: '最近修改'),
        ],
        onChanged: (value) {
          if (value != null) setState(() => _sort = value);
        },
      ),
    ],
  );
}
// #endregion selection

// #region sliders
Widget slidersDemo(BuildContext context) => const _SlidersDemo();

class _SlidersDemo extends StatefulWidget {
  const _SlidersDemo();

  @override
  State<_SlidersDemo> createState() => _SlidersDemoState();
}

class _SlidersDemoState extends State<_SlidersDemo> {
  var _volume = 40.0;
  var _speed = 1.0;
  var _episodeRange = const RangeValues(3, 8);
  double? _rating = 3.5;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('音量'),
      YumeiroSlider(
        min: 0,
        max: 100,
        divisions: 20,
        value: _volume,
        valueLabel: '${_volume.round()}%',
        onChanged: (value) => setState(() => _volume = value),
      ),
      const SizedBox(height: 12),
      Text(
        '集数范围 · ${_episodeRange.start.round()}–${_episodeRange.end.round()}',
      ),
      YumeiroRangeSlider(
        values: _episodeRange,
        min: 1,
        max: 12,
        divisions: 11,
        labels: RangeLabels(
          '${_episodeRange.start.round()}',
          '${_episodeRange.end.round()}',
        ),
        semanticFormatterCallback: (value) => '第 ${value.round()} 集',
        onChanged: (values) => setState(() => _episodeRange = values),
      ),
      const SizedBox(height: 12),
      YumeiroSliderInput(
        title: '播放速度',
        value: _speed,
        min: .5,
        max: 2,
        divisions: 6,
        decimalPlaces: 2,
        defaultValue: 1,
        suffixText: '×',
        onChanged: (value) => setState(() => _speed = value),
      ),
      const SizedBox(height: 16),
      Text(_rating == null ? '未评分' : '评分 · ${_rating!.toStringAsFixed(1)} / 5'),
      const SizedBox(height: 4),
      Wrap(
        spacing: 8,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          YumeiroRatingEditor(
            value: _rating,
            semanticLabel: '台站评分',
            onChanged: (value) => setState(() => _rating = value),
          ),
          YumeiroButton(
            label: '清除评分',
            variant: YumeiroButtonVariant.ghost,
            onPressed: _rating == null
                ? null
                : () => setState(() => _rating = null),
          ),
        ],
      ),
    ],
  );
}
// #endregion sliders

// #region overlays
Widget overlaysDemo(BuildContext context) {
  var name = '晨雾信号';
  var destination = '收件箱';
  var editStatus = '尚未编辑';
  return StatefulBuilder(
    builder: (context, setState) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            YumeiroButton(
              label: '打开确认框',
              onPressed: () async {
                final confirmed = await YumeiroDialog.confirm(
                  context: context,
                  title: '归档这项任务？',
                  message: '已下载的文件会保留。',
                  confirmLabel: '归档',
                );
                if (confirmed && context.mounted) {
                  showYumeiroToast(
                    context,
                    '任务已归档',
                    statusRole: YumeiroStatusRole.success,
                  );
                }
              },
            ),
            YumeiroButton(
              label: '编辑名称',
              variant: YumeiroButtonVariant.secondary,
              onPressed: () async {
                final result = await YumeiroEditor.show<String>(
                  context: context,
                  builder: (context) => _NameEditor(initialName: name),
                );
                if (!context.mounted) return;
                setState(() {
                  if (result != null) name = result;
                  editStatus = result == null ? '已取消编辑' : '已保存名称';
                });
              },
            ),
            YumeiroButton(
              label: '更改位置',
              variant: YumeiroButtonVariant.secondary,
              onPressed: () async {
                final result = await YumeiroDialog.show<String>(
                  context: context,
                  builder: (dialogContext) => YumeiroDialog(
                    title: '移动任务',
                    actions: [
                      YumeiroButton(
                        label: '取消移动',
                        variant: YumeiroButtonVariant.secondary,
                        onPressed: () => Navigator.of(dialogContext).pop(),
                      ),
                      YumeiroButton(
                        label: '移至归档',
                        onPressed: () => Navigator.of(dialogContext).pop('归档'),
                      ),
                    ],
                    child: Text('当前位于「$destination」，请选择新位置。'),
                  ),
                );
                if (context.mounted && result != null) {
                  setState(() => destination = result);
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text('当前名称 · $name'),
        Text('存放位置 · $destination'),
        Text(editStatus),
      ],
    ),
  );
}

class _NameEditor extends StatefulWidget {
  const _NameEditor({required this.initialName});

  final String initialName;

  @override
  State<_NameEditor> createState() => _NameEditorState();
}

class _NameEditorState extends State<_NameEditor> {
  late String _draft = widget.initialName;

  @override
  Widget build(BuildContext context) => YumeiroEditor(
    title: '编辑任务名称',
    actions: [
      YumeiroButton(
        label: '取消编辑',
        variant: YumeiroButtonVariant.secondary,
        onPressed: () => Navigator.of(context).pop(),
      ),
      YumeiroButton(
        label: '保存名称',
        onPressed: _draft.trim().isEmpty
            ? null
            : () => Navigator.of(context).pop(_draft.trim()),
      ),
    ],
    child: YumeiroTextField(
      initialValue: widget.initialName,
      semanticLabel: '任务名称',
      onChanged: (value) => setState(() => _draft = value),
    ),
  );
}
// #endregion overlays

// #region materials
Widget materialsDemo(BuildContext context) {
  final theme = YumeiroTheme.of(context);
  final base = theme.visuals.surface(YumeiroSurfaceRole.panel);
  final dark = Theme.of(context).brightness == Brightness.dark;
  var acrylic = true;

  return StatefulBuilder(
    builder: (context, setState) {
      final material = acrylic
          ? YumeiroMaterials.acrylic(
              blur: 18,
              tint: dark ? const Color(0x990F1834) : const Color(0x99F1F8FF),
            )
          : YumeiroMaterials.brushedMetal(
              color: dark ? const Color(0xFF313B53) : const Color(0xFFD8E2EE),
              texture: .8,
            );

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          YumeiroSegmentedControl<bool>(
            options: const [
              YumeiroSegmentOption(value: true, label: '磨砂亚克力'),
              YumeiroSegmentOption(value: false, label: '拉丝金属'),
            ],
            value: acrylic,
            onChanged: (value) => setState(() => acrylic = value),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(theme.radii.lg),
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF72C8D3),
                    Color(0xFF756BCD),
                    Color(0xFFF19DA2),
                  ],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: YumeiroResolvedVisualSurface(
                  appearance: material.applyTo(base),
                  padding: const EdgeInsets.all(16),
                  child: Text(acrylic ? '半透明表面与背景取样' : '不透明表面与方向纹理'),
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}
// #endregion materials
