import 'package:material_ui/material_ui.dart';
import 'package:yumeiro/yumeiro.dart';

import '../../docs/form_controls_demo.dart';
import '../state/gallery_controller.dart';
import '../widgets/gallery_widgets.dart';

/// Interactive samples grouped by control type.
class ControlsPage extends StatefulWidget {
  const ControlsPage({super.key, required this.controller});

  final GalleryController controller;

  @override
  State<ControlsPage> createState() => _ControlsPageState();
}

class _ControlsPageState extends State<ControlsPage> {
  static const _letters = ['A', 'B', 'C'];

  String? _remoteValue;
  String? _fixedSearchValue;
  double _steppedValue = .5;
  late final _calendarToday = DateUtils.dateOnly(DateTime.now());
  late DateTime? _date = _calendarToday;
  TimeOfDay? _time = const TimeOfDay(hour: 14, minute: 30);
  late DateTimeRange<DateTime>? _dateRange = DateTimeRange(
    start: DateTime(_calendarToday.year, _calendarToday.month + 1, 0),
    end: DateTime(_calendarToday.year, _calendarToday.month + 1, 3),
  );

  GalleryController get controller => widget.controller;

  @override
  Widget build(BuildContext context) {
    final theme = YumeiroTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: theme.spacing.xl,
      children: [
        GallerySection(
          title: gText(context, en: 'Actions & Text Input', zh: '操作与输入'),
          children: [
            _buildButtons(context),
            _buildBooleanControls(context),
            _buildTextFields(context),
          ],
        ),
        GallerySection(
          title: gText(context, en: 'Selection Controls', zh: '选择控件'),
          children: [
            _buildSegments(context),
            _buildSingleSelect(context),
            _buildSelectionList(context),
            _buildRemoteSelect(context),
            _buildCascadingSelect(context),
          ],
        ),
        GallerySection(
          title: gText(context, en: 'Labels', zh: '标签'),
          children: [
            _buildTokenInput(context),
            _buildMultiSelect(context),
            _buildChips(context),
          ],
        ),
        GallerySection(
          title: gText(context, en: 'Values, colors and time', zh: '数值、颜色与时间'),
          children: [
            _buildNumbers(context),
            _buildColorPicker(context),
            _buildDateTimePickers(context),
          ],
        ),
        GallerySection(
          title: gText(context, en: 'Forms', zh: '表单'),
          children: [
            _buildInputActionGroup(context),
            GalleryCard.example(
              key: const ValueKey('sample-form-controls'),
              example: GalleryExample.formControls,
              child: formControlsDemo(
                context,
                decorate: GalleryComponent.sample,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _option(BuildContext context, String suffix) =>
      gText(context, en: 'Option $suffix', zh: '选项 $suffix');

  List<YumeiroSelectionOption<String>> _options(BuildContext context) => [
    for (final letter in _letters)
      YumeiroSelectionOption(value: letter, label: _option(context, letter)),
  ];

  Widget _buildButtons(BuildContext context) {
    final theme = YumeiroTheme.of(context);
    void showExample() => showYumeiroToast(
      context,
      gText(context, en: 'Button pressed', zh: '已点击按钮'),
    );
    return GalleryCard.example(
      example: GalleryExample.buttons,
      child: Column(
        spacing: theme.spacing.md,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: theme.spacing.lg,
            runSpacing: theme.spacing.md,
            children: [
              GalleryComponent(
                'YumeiroButton',
                child: Wrap(
                  spacing: theme.spacing.sm,
                  runSpacing: theme.spacing.sm,
                  children: [
                    YumeiroButton(
                      label: gText(context, en: 'Default button', zh: '默认按钮'),
                      onPressed: showExample,
                    ),
                    YumeiroButton(
                      label: gText(context, en: 'Disabled', zh: '禁用'),
                      onPressed: null,
                    ),
                  ],
                ),
              ),
              for (final (variant, en, zh, icon) in [
                (
                  YumeiroButtonVariant.primary,
                  'Primary',
                  '主要',
                  theme.icons.auto,
                ),
                (
                  YumeiroButtonVariant.secondary,
                  'Secondary',
                  '次要',
                  Icons.tune_rounded,
                ),
                (YumeiroButtonVariant.ghost, 'Ghost', '幽灵', null),
                (
                  YumeiroButtonVariant.danger,
                  'Danger',
                  '危险',
                  theme.icons.delete,
                ),
                (YumeiroButtonVariant.mediaOverlay, 'Overlay', '浮层', null),
              ])
                GalleryComponent(
                  'YumeiroButton(variant: ${variant.name})',
                  child: YumeiroButton(
                    label: gText(context, en: en, zh: zh),
                    icon: icon,
                    variant: variant,
                    onPressed: showExample,
                  ),
                ),
              GalleryComponent(
                'YumeiroButton(dense: true)',
                child: YumeiroButton(
                  label: gText(context, en: 'Dense', zh: '紧凑'),
                  dense: true,
                  onPressed: showExample,
                ),
              ),
              GalleryComponent(
                'YumeiroButton(label: null)',
                child: Wrap(
                  spacing: theme.spacing.sm,
                  children: [
                    YumeiroButton(
                      variant: YumeiroButtonVariant.ghost,
                      icon: theme.icons.refresh,
                      tooltip: gText(context, en: 'Example A', zh: '示例 A'),
                      onPressed: showExample,
                    ),
                    YumeiroButton(
                      variant: YumeiroButtonVariant.ghost,
                      icon: theme.icons.starFilled,
                      selected: true,
                      badge: true,
                      tooltip: gText(context, en: 'Selected icon', zh: '选中图标'),
                      onPressed: showExample,
                    ),
                  ],
                ),
              ),
            ],
          ),
          GalleryComponent(
            'YumeiroSearchButton',
            child: Wrap(
              spacing: theme.spacing.sm,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const YumeiroSearchButton(),
                if (controller.searchScopeQuery.isNotEmpty)
                  Text(controller.searchScopeQuery),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBooleanControls(BuildContext context) {
    final theme = YumeiroTheme.of(context);
    return GalleryCard.example(
      example: GalleryExample.booleanControls,
      child: Column(
        spacing: theme.spacing.md,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GalleryComponent(
            'YumeiroSwitch',
            child: Wrap(
              spacing: theme.spacing.lg,
              runSpacing: theme.spacing.md,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    YumeiroSwitch(
                      value: controller.switchValue,
                      onChanged: controller.setSwitchValue,
                    ),
                    SizedBox(width: theme.spacing.sm),
                    Text(_option(context, 'A')),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const YumeiroSwitch(value: true, onChanged: null),
                    SizedBox(width: theme.spacing.sm),
                    Text(
                      gText(context, en: 'Disabled', zh: '禁用'),
                      style: theme.typography.body.copyWith(
                        color: theme.subtle,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          GalleryComponent(
            'YumeiroCheckbox',
            child: Wrap(
              spacing: theme.spacing.lg,
              runSpacing: theme.spacing.md,
              children: [
                YumeiroCheckbox(
                  value: controller.checkboxValue,
                  label: _option(context, 'A'),
                  onChanged: controller.setCheckboxValue,
                ),
                YumeiroCheckbox(
                  value: true,
                  enabled: false,
                  label: gText(context, en: 'Disabled', zh: '禁用'),
                  onChanged: (_) {},
                ),
              ],
            ),
          ),
          GalleryComponent(
            'YumeiroCheckbox(tristate: true)',
            child: YumeiroCheckbox(
              value: controller.tristateValue,
              tristate: true,
              label: gText(context, en: 'Tristate', zh: '三态复选'),
              onChanged: controller.setTristateValue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextFields(BuildContext context) {
    final theme = YumeiroTheme.of(context);
    return GalleryCard.example(
      example: GalleryExample.textFields,
      child: Column(
        spacing: theme.spacing.md,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GalleryComponent(
            'YumeiroTextField',
            child: YumeiroTextField(
              controller: controller.textController,
              hintText: gText(context, en: 'Enter text', zh: '输入文本'),
              clearable: true,
              prefixIcon: theme.icons.edit,
            ),
          ),
          GalleryComponent(
            'YumeiroTextField.search',
            child: YumeiroTextField.search(
              controller: controller.searchController,
              hintText: gText(context, en: 'Search', zh: '搜索'),
            ),
          ),
          _comparison(context, minWidth: 230, [
            GalleryComponent(
              'YumeiroTextField(maxLines: 4)',
              child: _labeledText(
                gText(
                  context,
                  en: 'Multiline · 80 characters',
                  zh: '多行 · 限 80 字',
                ),
                YumeiroTextField(
                  key: const ValueKey('gallery-text-multiline'),
                  hintText: gText(
                    context,
                    en: 'Enter multiple lines',
                    zh: '输入多行文本',
                  ),
                  minLines: 2,
                  maxLines: 4,
                  maxLength: 80,
                ),
              ),
            ),
            GalleryComponent(
              'YumeiroTextField(obscureToggle: true)',
              child: _labeledText(
                gText(context, en: 'Hidden text', zh: '隐藏文本'),
                YumeiroTextField(
                  key: const ValueKey('gallery-text-obscure'),
                  initialValue: 'sample-a',
                  hintText: gText(context, en: 'Enter text', zh: '输入文本'),
                  obscureToggle: true,
                ),
              ),
            ),
          ]),
          GalleryComponent(
            'YumeiroFieldLayout',
            child: _comparison(context, minWidth: 180, [
              _labeledText(
                gText(context, en: 'Disabled', zh: '禁用'),
                const YumeiroTextField(
                  key: ValueKey('gallery-text-disabled'),
                  initialValue: 'A123',
                  enabled: false,
                ),
              ),
              _labeledText(
                gText(context, en: 'Read only', zh: '只读'),
                const YumeiroTextField(
                  key: ValueKey('gallery-text-readonly'),
                  initialValue: 'B123',
                  readOnly: true,
                ),
              ),
            ]),
          ),
          GalleryComponent(
            'YumeiroTextField.form',
            child: Form(
              child: YumeiroTextField.form(
                controller: controller.formFieldController,
                label: gText(context, en: 'Field A', zh: '字段 A'),
                required: true,
                helperText: gText(
                  context,
                  en: 'Enter text to pass validation.',
                  zh: '输入非空文本可通过校验。',
                ),
                autovalidateMode: AutovalidateMode.always,
                validator: (value) => (value ?? '').trim().isEmpty
                    ? gText(context, en: 'Enter text', zh: '请输入文本')
                    : null,
                clearable: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _labeledText(String label, Widget child) =>
      YumeiroFieldLayout(label: label, bottomSpacing: 0, child: child);

  Widget _buildTokenInput(BuildContext context) {
    return GalleryCard.example(
      example: GalleryExample.tokenInput,
      child: GalleryComponent(
        'YumeiroTokenInput',
        child: YumeiroTokenInput<String>(
          title: gText(context, en: 'Example A', zh: '示例 A'),
          subtitle: gText(
            context,
            en: 'Press + or Enter to add a label.',
            zh: '输入后点 + 或按回车添加。',
          ),
          placeholder: gText(context, en: 'Add a label', zh: '添加标签'),
          values: controller.tokens,
          labelBuilder: (value) => gSample(context, value),
          parseInput: (raw) {
            final value = raw.trim();
            // Built-in labels have the same value in both locales.
            return [
              value.startsWith('标签 ')
                  ? value.replaceFirst('标签 ', 'Tag ')
                  : value,
            ];
          },
          onChanged: controller.setTokens,
        ),
      ),
    );
  }

  Widget _buildChips(BuildContext context) {
    final theme = YumeiroTheme.of(context);
    final spacing = theme.spacing;
    return GalleryCard.example(
      example: GalleryExample.chips,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: spacing.md,
        children: [
          Wrap(
            spacing: spacing.lg,
            runSpacing: spacing.md,
            children: [
              GalleryComponent(
                'YumeiroChip',
                child: YumeiroChip(label: gSample(context, 'Tag A')),
              ),
              GalleryComponent(
                'YumeiroChip(onTap: …)',
                child: YumeiroChip(
                  label: gSample(context, 'Tag B'),
                  onTap: () => showYumeiroToast(
                    context,
                    gText(context, en: 'Tag pressed', zh: '已点击标签'),
                  ),
                ),
              ),
              GalleryComponent(
                'YumeiroChip(selected: …)',
                child: YumeiroChip(
                  key: const ValueKey('display-fixed-chip'),
                  label: gSample(context, 'Tag C'),
                  icon: theme.icons.auto,
                  selected: controller.displayChipSelected,
                  onTap: () => controller.setDisplayChipSelected(
                    !controller.displayChipSelected,
                  ),
                ),
              ),
              GalleryComponent(
                'YumeiroChip(dense: true)',
                child: YumeiroChip(
                  key: const ValueKey('display-fixed-dense-chip'),
                  label: gSample(context, 'Tag D'),
                  dense: true,
                  selected: controller.displayDenseChipSelected,
                  onTap: () => controller.setDisplayDenseChipSelected(
                    !controller.displayDenseChipSelected,
                  ),
                ),
              ),
            ],
          ),
          GalleryComponent(
            'YumeiroChip(onDeleted: …)',
            child: Wrap(
              spacing: spacing.sm,
              runSpacing: spacing.sm,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (final tag in controller.removableTags)
                  YumeiroChip(
                    key: ValueKey('display-removable-$tag'),
                    label: gSample(context, tag),
                    selected: controller.selectedTags.contains(tag),
                    onTap: () => controller.toggleTag(tag),
                    onDeleted: () => controller.removeTag(tag),
                  ),
                if (controller.removableTags.isEmpty)
                  Text(
                    gText(context, en: 'No tags remaining.', zh: '暂无标签。'),
                    style: theme.typography.supporting,
                  ),
                YumeiroButton(
                  label: gText(
                    context,
                    en: 'Reset Removable Tags',
                    zh: '重置可移除标签',
                  ),
                  icon: theme.icons.refresh,
                  variant: YumeiroButtonVariant.ghost,
                  dense: true,
                  onPressed: controller.resetRemovableTags,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumbers(BuildContext context) {
    final theme = YumeiroTheme.of(context);
    return GalleryCard.example(
      example: GalleryExample.numbers,
      child: Column(
        spacing: theme.spacing.md,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GalleryComponent(
            'YumeiroSlider',
            child: YumeiroSlider(
              value: controller.sliderValue,
              valueLabel: '${(controller.sliderValue * 100).round()}%',
              onChanged: controller.setSliderValue,
            ),
          ),
          GalleryComponent(
            'YumeiroSlider(divisions: 4)',
            child: YumeiroSlider(
              value: _steppedValue,
              divisions: 4,
              valueLabel: '${(_steppedValue * 100).round()}%',
              onChanged: (value) => setState(() => _steppedValue = value),
            ),
          ),
          GalleryComponent(
            'YumeiroRangeSlider',
            child: YumeiroRangeSlider(
              values: controller.rangeSliderValues,
              divisions: 20,
              labels: RangeLabels(
                '${(controller.rangeSliderValues.start * 100).round()}%',
                '${(controller.rangeSliderValues.end * 100).round()}%',
              ),
              onChanged: controller.setRangeSliderValues,
            ),
          ),
          GalleryComponent(
            'YumeiroSliderInput',
            child: YumeiroSliderInput(
              title: gText(context, en: 'Example A', zh: '示例 A'),
              value: controller.sliderInputValue,
              defaultValue: 48,
              min: 0,
              max: 100,
              divisions: 100,
              onChanged: controller.setSliderInputValue,
              onReset: () => controller.setSliderInputValue(48),
            ),
          ),
          GalleryComponent(
            'YumeiroRatingEditor',
            child: YumeiroSettingRow(
              title: gText(context, en: 'Example A', zh: '示例 A'),
              subtitle: controller.rating == null
                  ? gText(context, en: 'Unrated', zh: '未评分')
                  : '${controller.rating!.toStringAsFixed(1)} / 5.0',
              trailing: YumeiroRatingEditor(
                value: controller.rating,
                onChanged: controller.setRating,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _comparison(
    BuildContext context,
    List<Widget> samples, {
    required double minWidth,
  }) {
    final gap = YumeiroTheme.of(context).spacing.md;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final gaps = (samples.length - 1) * gap;
        final sampleWidth = width >= samples.length * minWidth + gaps
            ? (width - gaps) / samples.length
            : width;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final sample in samples)
              SizedBox(width: sampleWidth, child: sample),
          ],
        );
      },
    );
  }

  Widget _buildSegments(BuildContext context) {
    const views = [
      (value: 'balanced', letter: 'A', icon: Icons.circle_outlined),
      (value: 'vivid', letter: 'B', icon: Icons.square_outlined),
      (value: 'timeline', letter: 'C', icon: Icons.change_history_rounded),
    ];

    return GalleryCard.example(
      example: GalleryExample.segments,
      child: _comparison(context, minWidth: 260, [
        GalleryComponent(
          'YumeiroSegmentedControl',
          child: YumeiroSegmentedControl<int>(
            value: controller.segmentValue,
            options: [
              for (final (index, option) in views.indexed)
                YumeiroSegmentOption(
                  value: index,
                  icon: option.icon,
                  label: _option(context, option.letter),
                ),
            ],
            onChanged: controller.setSegmentValue,
          ),
        ),
        GalleryComponent(
          'YumeiroSegmentedControl.vertical',
          child: YumeiroSegmentedControl.vertical<String>(
            value: controller.verticalSegmentValue,
            options: [
              for (final option in views)
                YumeiroSegmentOption(
                  value: option.value,
                  icon: option.icon,
                  label: _option(context, option.letter),
                  subtitle: gText(
                    context,
                    en: 'Details ${option.letter}',
                    zh: '说明 ${option.letter}',
                  ),
                ),
            ],
            onChanged: controller.setVerticalSegmentValue,
          ),
        ),
      ]),
    );
  }

  Widget _buildSingleSelect(BuildContext context) {
    final theme = YumeiroTheme.of(context);
    final searchOptions = [
      for (final letter in const ['A', 'B', 'C', 'D', 'E', 'F'])
        YumeiroSelectionOption(
          value: letter.toLowerCase(),
          label: _option(context, letter),
        ),
    ];
    return GalleryCard.example(
      example: GalleryExample.singleSelect,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: theme.spacing.md,
        children: [
          _comparison(context, minWidth: 190, [
            GalleryComponent(
              'YumeiroSelect',
              child: YumeiroSelect<String>(
                title: gText(context, en: 'Choose an option', zh: '选择选项'),
                value: controller.selectValue,
                options: [
                  YumeiroSelectionOption(
                    value: 'fast',
                    label: _option(context, 'A'),
                  ),
                  YumeiroSelectionOption(
                    value: 'balanced',
                    label: _option(context, 'B'),
                  ),
                  YumeiroSelectionOption(
                    value: 'precise',
                    label: _option(context, 'C'),
                  ),
                ],
                onChanged: controller.setSelectValue,
              ),
            ),
            GalleryComponent(
              'YumeiroSelect.menu',
              child: YumeiroSelect<String>.menu(
                key: const ValueKey('gallery-filter-select'),
                value: controller.dropdownValue,
                icon: theme.icons.filter,
                selected: controller.dropdownValue != 'all',
                options: [
                  YumeiroSelectionOption(
                    value: 'all',
                    label: _option(context, 'A'),
                  ),
                  YumeiroSelectionOption(
                    value: 'optical',
                    label: _option(context, 'B'),
                  ),
                  YumeiroSelectionOption(
                    value: 'blur',
                    label: _option(context, 'C'),
                  ),
                  YumeiroSelectionOption(
                    value: 'surface',
                    label: _option(context, 'D'),
                  ),
                ],
                onChanged: controller.setDropdownValue,
              ),
            ),
          ]),
          _comparison(context, minWidth: 220, [
            GalleryComponent(
              'YumeiroSelect.searchable(onFreeTextSubmitted: …)',
              child: YumeiroSelect<String>.searchable(
                value: controller.searchableValue,
                placeholder: gText(
                  context,
                  en: 'Search or enter text',
                  zh: '搜索或输入文本',
                ),
                expand: true,
                options: searchOptions,
                onChanged: controller.setSearchableValue,
                onFreeTextSubmitted: controller.setSearchableValue,
              ),
            ),
            GalleryComponent(
              'YumeiroSelect.searchable',
              child: YumeiroSelect<String>.searchable(
                value: _fixedSearchValue,
                placeholder: gText(context, en: 'Search options', zh: '搜索选项'),
                expand: true,
                options: searchOptions,
                onChanged: (value) => setState(() => _fixedSearchValue = value),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildMultiSelect(BuildContext context) => GalleryCard.example(
    example: GalleryExample.multiSelect,
    child: GalleryComponent(
      'YumeiroMultiSelect',
      child: multiSelectSample(
        context,
        tags: controller.multiSelectTags,
        onTagsChanged: controller.setMultiSelectTags,
      ),
    ),
  );

  Widget _buildRemoteSelect(BuildContext context) {
    final options = _options(context);
    return GalleryCard.example(
      example: GalleryExample.remoteSelect,
      child: GalleryComponent(
        'YumeiroAsyncSelect',
        child: YumeiroAsyncSelect<String>(
          key: const ValueKey('gallery-remote-select'),
          value: options
              .where((option) => option.value == _remoteValue)
              .firstOrNull,
          placeholder: gText(context, en: 'Search options', zh: '搜索选项'),
          loadOptions: (input) async {
            await Future<void>.delayed(const Duration(milliseconds: 350));
            final query = input.trim().toLowerCase();
            return options
                .where((option) => option.label.toLowerCase().contains(query))
                .toList();
          },
          onChanged: (option) => setState(() => _remoteValue = option?.value),
          clearable: true,
        ),
      ),
    );
  }

  Widget _buildSelectionList(BuildContext context) => GalleryCard.example(
    example: GalleryExample.selectionList,
    child: selectionListDemo(context, decorate: GalleryComponent.sample),
  );

  Widget _buildCascadingSelect(BuildContext context) => GalleryCard.example(
    example: GalleryExample.cascadingSelect,
    child: GalleryComponent(
      'YumeiroCascadingSelect',
      child: YumeiroCascadingSelect<String>(
        title: gText(context, en: 'Choose an option', zh: '选择选项'),
        value: controller.cascadeValue,
        options: [
          YumeiroCascadingOption.branch(
            id: 'render',
            label: gText(context, en: 'Group A', zh: '分组 A'),
            children: [
              YumeiroCascadingOption(
                id: 'optical',
                label: _option(context, 'A1'),
                value: 'render/optical',
              ),
              YumeiroCascadingOption(
                id: 'blur',
                label: _option(context, 'A2'),
                value: 'render/blur',
              ),
            ],
          ),
          YumeiroCascadingOption.branch(
            id: 'theme',
            label: gText(context, en: 'Group B', zh: '分组 B'),
            children: [
              YumeiroCascadingOption(
                id: 'tokens',
                label: _option(context, 'B1'),
                value: 'theme/tokens',
              ),
              YumeiroCascadingOption(
                id: 'radii',
                label: _option(context, 'B2'),
                value: 'theme/radii',
              ),
            ],
          ),
        ],
        onChanged: controller.setCascadeValue,
      ),
    ),
  );

  Widget _buildDateTimePickers(BuildContext context) {
    final year = _calendarToday.year;
    final firstDate = DateTime(year - 1);
    final lastDate = DateTime(year + 1, 12, 31);
    return GalleryCard.example(
      example: GalleryExample.dateTimePickers,
      child: _comparison(context, minWidth: 180, [
        GalleryComponent(
          'YumeiroDatePicker',
          child: YumeiroDatePicker(
            key: const ValueKey('gallery-date-picker'),
            firstDate: firstDate,
            lastDate: lastDate,
            currentDate: _calendarToday,
            value: _date,
            onChanged: (value) => setState(() => _date = value),
            clearable: true,
          ),
        ),
        GalleryComponent(
          'YumeiroTimePicker',
          child: YumeiroTimePicker(
            key: const ValueKey('gallery-time-picker'),
            value: _time,
            onChanged: (value) => setState(() => _time = value),
            clearable: true,
          ),
        ),
        GalleryComponent(
          'YumeiroDateRangePicker',
          child: YumeiroDateRangePicker(
            key: const ValueKey('gallery-date-range-picker'),
            firstDate: firstDate,
            lastDate: lastDate,
            currentDate: _calendarToday,
            value: _dateRange,
            onChanged: (value) => setState(() => _dateRange = value),
            clearable: true,
          ),
        ),
      ]),
    );
  }

  Widget _buildInputActionGroup(BuildContext context) => GalleryCard.example(
    example: GalleryExample.inputActionGroup,
    child: GalleryComponent(
      'YumeiroInputActionGroup',
      child: YumeiroInputActionGroup(
        key: const ValueKey('gallery-input-action-group'),
        inputWidth: 180,
        inputs: [
          YumeiroTextField(
            hintText: gText(context, en: 'Field A', zh: '字段 A'),
          ),
          YumeiroTextField(
            hintText: gText(context, en: 'Field B', zh: '字段 B'),
          ),
        ],
        action: YumeiroButton(
          label: gText(context, en: 'Show message', zh: '显示提示'),
          variant: YumeiroButtonVariant.primary,
          onPressed: () => showYumeiroToast(
            context,
            gText(context, en: 'Sample action triggered.', zh: '已触发示例操作。'),
          ),
        ),
      ),
    ),
  );

  Widget _buildColorPicker(BuildContext context) {
    final theme = YumeiroTheme.of(context);
    return GalleryCard.example(
      example: GalleryExample.colorPicker,
      child: GalleryComponent(
        'YumeiroColorPickerButton',
        child: YumeiroSettingRow(
          title: gText(context, en: 'Example A', zh: '示例 A'),
          subtitle: gText(
            context,
            en: 'Choose a swatch, enter HEX, or restore the default.',
            zh: '可选预设、输入十六进制颜色或恢复默认值。',
          ),
          trailing: YumeiroColorPickerButton(
            value: controller.pickedColor,
            defaultColor: theme.accent,
            presets: [
              YumeiroColorPickerPreset(
                label: _option(context, 'A'),
                color: const Color(0xFF19857B),
              ),
              YumeiroColorPickerPreset(
                label: _option(context, 'B'),
                color: const Color(0xFF6366F1),
              ),
              YumeiroColorPickerPreset(
                label: _option(context, 'C'),
                color: const Color(0xFFF43F5E),
              ),
            ],
            onChanged: controller.setPickedColor,
          ),
        ),
      ),
    );
  }
}
