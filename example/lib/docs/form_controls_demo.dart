import 'package:material_ui/material_ui.dart';
import 'package:yumeiro/yumeiro.dart';

// #region form-controls
Widget formControlsDemo(
  BuildContext context, {
  Widget Function(String, Widget)? decorate,
}) => _FormControlsDemo(decorate: decorate);

String _text(BuildContext context, {required String en, required String zh}) =>
    Localizations.localeOf(context).languageCode == 'zh' ? zh : en;

String _optionLabel(BuildContext context, String letter) =>
    _text(context, en: 'Option $letter', zh: '选项 $letter');

enum _OptionSource { a, b }

enum _Choice { a, b, c }

class _FormControlsDemo extends StatefulWidget {
  const _FormControlsDemo({this.decorate});

  final Widget Function(String, Widget)? decorate;

  @override
  State<_FormControlsDemo> createState() => _FormControlsDemoState();
}

class _FormControlsDemoState extends State<_FormControlsDemo> {
  static const _remoteOptions = {
    _OptionSource.a: {101: 'A', 102: 'B'},
    _OptionSource.b: {201: 'C', 202: 'D'},
  };

  final _form = GlobalKey<FormState>();
  final _rangeField = GlobalKey<FormFieldState<DateTimeRange<DateTime>>>();
  final _firstDate = DateTime(2026, 1, 1);
  final _lastDate = DateTime(2027, 12, 31);
  final _simulatedFailures = <_OptionSource>{};

  _OptionSource _source = _OptionSource.a;
  bool _showDateFields = false;
  _Choice _choice = _Choice.a;
  Set<String> _selectedOptions = const {};
  Set<String> _selectedListOptions = const {};
  String? _searchedOption;
  int? _remoteOptionId;
  bool _switchValue = false;
  DateTime? _date;
  TimeOfDay? _time;
  DateTimeRange<DateTime>? _dateRange;
  bool _saved = false;

  Future<List<YumeiroSelectionOption<int>>> _searchOptions(
    _OptionSource source,
    String input,
    String labelPrefix,
  ) async {
    final query = input.trim().toLowerCase();
    final shouldSimulateFailure = query == 'retry' || query == '重试';
    final failThisRequest =
        shouldSimulateFailure && _simulatedFailures.add(source);
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (failThisRequest) throw StateError('Simulated request failure');
    return [
      for (final entry in _remoteOptions[source]!.entries)
        if (shouldSimulateFailure ||
            '$labelPrefix ${entry.value}'.toLowerCase().contains(query))
          YumeiroSelectionOption(
            value: entry.key,
            label: '$labelPrefix ${entry.value}',
          ),
    ];
  }

  void _submit() {
    final state = _form.currentState!;
    final invalid = state.validateGranularly();
    if (invalid.isNotEmpty) {
      setState(() {
        _saved = false;
        if (invalid.contains(_rangeField.currentState)) _showDateFields = true;
      });
      return;
    }
    state.save();
    setState(() => _saved = true);
  }

  void _reset() {
    _form.currentState!.reset();
    setState(() {
      _source = _OptionSource.a;
      _showDateFields = false;
      _saved = false;
      _simulatedFailures.clear();
    });
  }

  String _savedSummary(BuildContext context) {
    final format = MaterialLocalizations.of(context);
    String labels(Set<String> choices) => choices
        .map((letter) => _optionLabel(context, letter))
        .join(_text(context, en: ', ', zh: '、'));
    final date = _date;
    final time = _time;
    final range = _dateRange!;
    final remoteOptionId = _remoteOptionId;
    final searchedOption = _searchedOption;
    final parts = [
      _text(context, en: 'Saved', zh: '已保存'),
      _optionLabel(context, _choice.name.toUpperCase()),
      labels(_selectedOptions),
      '${format.formatCompactDate(range.start)} – '
          '${format.formatCompactDate(range.end)}',
      if (remoteOptionId != null)
        _text(
          context,
          en: 'Field B ID $remoteOptionId',
          zh: '字段 B ID $remoteOptionId',
        ),
      if (_switchValue)
        _text(context, en: 'Field F on', zh: '字段 F 已开启')
      else
        _text(context, en: 'Field F off', zh: '字段 F 已关闭'),
      if (date != null) format.formatCompactDate(date),
      if (time != null) time.format(context),
      if (_selectedListOptions.isNotEmpty)
        '${_text(context, en: 'Field G', zh: '字段 G')} '
            '${labels(_selectedListOptions)}',
      if (searchedOption != null)
        '${_text(context, en: 'Field H', zh: '字段 H')} '
            '${_optionLabel(context, searchedOption)}',
    ];
    return parts.join(' · ');
  }

  Widget _fieldGroup(List<Widget> fields) => LayoutBuilder(
    builder: (context, constraints) {
      final horizontal =
          constraints.hasBoundedWidth &&
          constraints.maxWidth >= 250 * fields.length;
      return Flex(
        direction: horizontal ? Axis.horizontal : Axis.vertical,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: !horizontal && constraints.hasBoundedWidth
            ? CrossAxisAlignment.stretch
            : CrossAxisAlignment.start,
        spacing: 12,
        children: [
          for (final field in fields)
            Flexible(
              flex: horizontal ? 1 : 0,
              fit: FlexFit.tight,
              child: field,
            ),
        ],
      );
    },
  );

  @override
  Widget build(BuildContext context) {
    final source = _source;
    final theme = YumeiroTheme.of(context);
    final decorate = widget.decorate ?? (_, child) => child;
    final examplePrefix = _text(context, en: 'Example', zh: '示例');
    return Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          Semantics(
            header: true,
            child: Text(
              _text(context, en: 'Selection fields', zh: '选择字段'),
              style: theme.typography.title,
            ),
          ),
          _fieldGroup([
            decorate(
              'YumeiroSelect.form',
              YumeiroSelect.form<_OptionSource>(
                label: _text(context, en: 'Field A', zh: '字段 A'),
                options: [
                  for (final option in _OptionSource.values)
                    YumeiroSelectionOption(
                      value: option,
                      label: _optionLabel(context, option.name.toUpperCase()),
                    ),
                ],
                initialValue: _OptionSource.a,
                onChanged: (value) {
                  if (value != null) setState(() => _source = value);
                },
              ),
            ),
            decorate(
              'YumeiroAsyncSelect.form',
              YumeiroAsyncSelect.form<int>(
                label: _text(context, en: 'Field B', zh: '字段 B'),
                helperText: _text(
                  context,
                  en: 'Enter “retry” to simulate one request failure.',
                  zh: '输入「重试」模拟一次请求失败。',
                ),
                placeholder: _text(context, en: 'Search options', zh: '搜索选项'),
                clearable: true,
                sourceKey: source,
                loadOptions: (query) =>
                    _searchOptions(source, query, examplePrefix),
                loadErrorText: _text(
                  context,
                  en: 'Could not load options.',
                  zh: '未能加载选项。',
                ),
                onSaved: (option) => _remoteOptionId = option?.value,
              ),
            ),
            decorate(
              'YumeiroMultiSelect.form',
              YumeiroMultiSelect.form<String>(
                label: _text(context, en: 'Field C', zh: '字段 C'),
                placeholder: _text(context, en: 'Choose options', zh: '选择选项'),
                required: true,
                options: [
                  for (final letter in const ['A', 'B', 'C'])
                    YumeiroSelectionOption(
                      value: letter,
                      label: _optionLabel(context, letter),
                    ),
                ],
                searchable: true,
                clearable: true,
                validator: (values) => values == null || values.isEmpty
                    ? _text(
                        context,
                        en: 'Choose at least one option',
                        zh: '请至少选择一项',
                      )
                    : null,
                onSaved: (values) => _selectedOptions = values ?? const {},
              ),
            ),
          ]),
          _fieldGroup([
            decorate(
              'YumeiroSelectionList.form',
              YumeiroSelectionList.form<_Choice>(
                label: _text(context, en: 'Field D', zh: '字段 D'),
                options: [
                  for (final option in _Choice.values)
                    YumeiroSelectionOption(
                      value: option,
                      label: _optionLabel(context, option.name.toUpperCase()),
                      enabled: option != _Choice.c,
                    ),
                ],
                initialValue: _Choice.a,
                onSaved: (value) => _choice = value ?? _Choice.a,
              ),
            ),
            decorate(
              'YumeiroSelectionList.multiForm',
              YumeiroSelectionList.multiForm<String>(
                label: _text(context, en: 'Field G', zh: '字段 G'),
                options: [
                  for (final letter in const ['A', 'B', 'C'])
                    YumeiroSelectionOption(
                      value: letter,
                      label: _optionLabel(context, letter),
                    ),
                ],
                onSaved: (values) => _selectedListOptions = values ?? const {},
              ),
            ),
            decorate(
              'YumeiroSelect.form(searchable: true)',
              YumeiroSelect.form<String>(
                key: const ValueKey('gallery-form-searchable-select'),
                label: _text(context, en: 'Field H', zh: '字段 H'),
                placeholder: _text(context, en: 'Filter options', zh: '筛选选项'),
                options: [
                  for (var index = 1; index <= 12; index++)
                    YumeiroSelectionOption(
                      value: 'H$index',
                      label: _optionLabel(context, 'H$index'),
                    ),
                ],
                searchable: true,
                onSaved: (value) => _searchedOption = value,
              ),
            ),
          ]),
          decorate(
            'YumeiroDisclosure',
            YumeiroDisclosure(
              title: Text(_text(context, en: 'Date and time', zh: '日期与时间')),
              expanded: _showDateFields,
              onChanged: (expanded) =>
                  setState(() => _showDateFields = expanded),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 12,
                  children: [
                    decorate(
                      'YumeiroDateRangePicker.form',
                      YumeiroDateRangePicker.form(
                        key: _rangeField,
                        label: _text(context, en: 'Date range', zh: '日期范围'),
                        required: true,
                        firstDate: _firstDate,
                        lastDate: _lastDate,
                        clearable: true,
                        validator: (value) => value == null
                            ? _text(
                                context,
                                en: 'Choose a date range',
                                zh: '请选择日期范围',
                              )
                            : null,
                        onSaved: (value) => _dateRange = value,
                      ),
                    ),
                    _fieldGroup([
                      decorate(
                        'YumeiroDatePicker.form',
                        YumeiroDatePicker.form(
                          label: _text(context, en: 'Date', zh: '日期'),
                          firstDate: _firstDate,
                          lastDate: _lastDate,
                          clearable: true,
                          onSaved: (value) => _date = value,
                        ),
                      ),
                      decorate(
                        'YumeiroTimePicker.form',
                        YumeiroTimePicker.form(
                          label: _text(context, en: 'Time', zh: '时间'),
                          clearable: true,
                          onSaved: (value) => _time = value,
                        ),
                      ),
                    ]),
                  ],
                ),
              ),
            ),
          ),
          _fieldGroup([
            decorate(
              'YumeiroCheckbox.form',
              YumeiroCheckbox.form(
                label: _text(context, en: 'Field E', zh: '字段 E'),
                required: true,
                validator: (checked) => checked == true
                    ? null
                    : _text(context, en: 'Check this box', zh: '请勾选此项'),
              ),
            ),
            decorate(
              'YumeiroSwitch.form',
              YumeiroSwitch.form(
                label: _text(context, en: 'Field F', zh: '字段 F'),
                onSaved: (value) => _switchValue = value ?? false,
              ),
            ),
          ]),
          Wrap(
            spacing: theme.spacing.md,
            runSpacing: theme.spacing.sm,
            children: [
              decorate(
                'YumeiroButton',
                YumeiroButton(
                  label: _text(context, en: 'Save', zh: '保存'),
                  onPressed: _submit,
                ),
              ),
              decorate(
                'YumeiroButton(variant: secondary)',
                YumeiroButton(
                  label: _text(context, en: 'Reset', zh: '重置'),
                  variant: YumeiroButtonVariant.secondary,
                  onPressed: _reset,
                ),
              ),
            ],
          ),
          if (_saved)
            Semantics(liveRegion: true, child: Text(_savedSummary(context))),
        ],
      ),
    );
  }
}
// #endregion form-controls

// #region multi-select
Widget multiSelectDemo(BuildContext context) {
  var tags = const {'Tag A', 'Tag B'};
  return StatefulBuilder(
    builder: (context, setState) => multiSelectSample(
      context,
      tags: tags,
      onTagsChanged: (next) => setState(() => tags = next),
    ),
  );
}

Widget multiSelectSample(
  BuildContext context, {
  required Set<String> tags,
  required ValueChanged<Set<String>> onTagsChanged,
}) {
  final chinese = Localizations.localeOf(context).languageCode == 'zh';
  return Align(
    alignment: AlignmentDirectional.centerStart,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: YumeiroMultiSelect<String>(
        label: chinese ? '确认后应用' : 'Apply on confirmation',
        title: chinese ? '选择标签' : 'Choose tags',
        options: [
          for (final letter in const ['A', 'B', 'C', 'D'])
            YumeiroSelectionOption(
              value: 'Tag $letter',
              label: chinese ? '标签 $letter' : 'Tag $letter',
            ),
        ],
        value: tags,
        onChanged: onTagsChanged,
      ),
    ),
  );
}
// #endregion multi-select

// #region selection-list
Widget selectionListDemo(
  BuildContext context, {
  Widget Function(String, Widget)? decorate,
}) => _SelectionListDemo(decorate: decorate);

class _SelectionListDemo extends StatefulWidget {
  const _SelectionListDemo({this.decorate});

  final Widget Function(String, Widget)? decorate;

  @override
  State<_SelectionListDemo> createState() => _SelectionListDemoState();
}

class _SelectionListDemoState extends State<_SelectionListDemo> {
  Set<String> _single = const {'A'};
  Set<String> _multiple = const {'A'};
  Set<int> _longList = const {};

  @override
  Widget build(BuildContext context) {
    final chinese = Localizations.localeOf(context).languageCode == 'zh';
    final decorate = widget.decorate ?? (_, child) => child;
    String optionLabel(String value) => chinese ? '选项 $value' : 'Option $value';
    List<YumeiroSelectionOption<String>> options({bool disableC = false}) => [
      for (final letter in const ['A', 'B', 'C'])
        YumeiroSelectionOption(
          value: letter,
          label: optionLabel(letter),
          subtitle: letter == 'B' ? (chinese ? '说明 B' : 'Details B') : null,
          enabled: !disableC || letter != 'C',
        ),
    ];
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: YumeiroTheme.of(context).spacing.md,
          children: [
            decorate(
              'YumeiroSelectionList',
              YumeiroSelectionList<String>(
                label: chinese ? '单选' : 'Single choice',
                options: options(disableC: true),
                values: _single,
                onChanged: (values) => setState(() => _single = values),
                scrollable: false,
              ),
            ),
            decorate(
              'YumeiroSelectionList(multiple: true)',
              YumeiroSelectionList<String>(
                label: chinese ? '多选' : 'Multiple choices',
                options: options(disableC: true),
                values: _multiple,
                onChanged: (values) => setState(() => _multiple = values),
                multiple: true,
                searchable: true,
                clearable: true,
                scrollable: false,
              ),
            ),
            decorate(
              'YumeiroSelectionList(scrollable: true)',
              SizedBox(
                height: 220,
                width: double.infinity,
                child: YumeiroSelectionList<int>(
                  label: chinese ? '长列表（30 项）' : 'Long list (30 options)',
                  options: [
                    for (var index = 1; index <= 30; index++)
                      YumeiroSelectionOption(
                        value: index,
                        label: optionLabel('$index'),
                      ),
                  ],
                  values: _longList,
                  onChanged: (values) => setState(() => _longList = values),
                  scrollable: true,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
// #endregion selection-list
