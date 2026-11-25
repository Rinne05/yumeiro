import 'package:material_ui/material_ui.dart';
import 'package:yumeiro/yumeiro.dart';

import 'docs/controls_demos.dart';
import 'docs/data_table_pagination_demo.dart';
import 'docs/demos.dart';
import 'docs/display_demos.dart';
import 'docs/form_controls_demo.dart';
import 'docs/layout_demos.dart';
import 'docs/overlays_demos.dart';
import 'docs/page_layout_demo.dart';
import 'docs/preview_viewport.dart';
import 'docs/theme_preview_demo.dart';

void main() {
  runApp(YumeiroDocsPreviewApp(uri: Uri.base));
}

const _demos = <String, (String, WidgetBuilder)>{
  'buttons': ('按钮', buttonsDemo),
  'inputs': ('文本输入', inputsDemo),
  'selection': ('选择控件', selectionDemo),
  'selection-list': ('内联选择列表', selectionListDemo),
  'form-controls': ('表单控件', formControlsDemo),
  'multi-select': ('多选标签', multiSelectDemo),
  'color-picker': ('颜色选择', colorPickerDemo),
  'sliders': ('数值调节', slidersDemo),
  'display': ('状态与信息', displayDemo),
  'media': ('媒体', mediaDemo),
  'layout': ('页面布局', layoutDemo),
  'rows': ('列表与设置行', rowsDemo),
  'compact-table': ('表格变体与惰性滚动', compactTableDemo),
  'data-table': ('数据表', dataTableDemo),
  'data-table-pagination': ('数据表服务端分页', dataTablePaginationDemo),
  'navigation': ('导航', navigationDemo),
  'toolbars': ('工具栏', toolbarsDemo),
  'overlays': ('浮层', overlaysDemo),
  'menus': ('上下文菜单', menusDemo),
  'sheets': ('选择与筛选', sheetsDemo),
  'toasts': ('通知', toastsDemo),
  'materials': ('材质', materialsDemo),
  'theme-preview': ('主题预览', themePreviewDemo),
};

class YumeiroDocsPreviewApp extends StatelessWidget {
  const YumeiroDocsPreviewApp({super.key, required this.uri});

  final Uri uri;

  @override
  Widget build(BuildContext context) {
    final query = uri.queryParameters;
    final isDark = switch (query['theme']) {
      'dark' => true,
      'light' => false,
      _ => MediaQuery.platformBrightnessOf(context) == Brightness.dark,
    };
    final id = query['demo'];
    final demo = _demos[id];
    final title = demo == null ? 'Yumeiro 组件示例' : '${demo.$1} · Yumeiro';
    final locale = Locale(query['locale'] == 'en' ? 'en' : 'zh');
    final familyId = switch (query['preset']) {
      'glass' => 'liquid-glass',
      'pixel' => 'pixel',
      _ => 'classic',
    };
    final family = YumeiroThemeFamilies.builtInValues.firstWhere(
      (family) => family.id == familyId,
    );
    final preset = family.resolve(
      isDark ? YumeiroThemeVariant.dark : YumeiroThemeVariant.light,
    );
    final modality = switch (query['modality']) {
      'pointer' => YumeiroModality.pointer,
      'touch' => YumeiroModality.touch,
      _ => null,
    };
    final overlayHeight = int.tryParse(query['overlayHeight'] ?? '');
    if (demo != null &&
        query['embedded'] == '1' &&
        overlayHeight != null &&
        overlayHeight > 0 &&
        isPreviewEmbedded) {
      return PreviewViewport(
        title: title,
        locale: locale,
        preset: preset,
        modality: modality,
        overlayHeight: overlayHeight,
        buildHome: (key) => _DemoPage(builder: demo.$2, contentKey: key),
      );
    }

    return YumeiroApp(
      title: title,
      locale: locale,
      preset: preset,
      modality: modality,
      home: _DemoPage(
        builder: demo?.$2 ?? (context) => _DemoIndex(unknownId: id),
      ),
    );
  }
}

class _DemoIndex extends StatelessWidget {
  const _DemoIndex({this.unknownId});

  final String? unknownId;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      YumeiroPageHeader(
        title: 'Yumeiro 组件示例',
        subtitle: unknownId == null ? null : '找不到示例「$unknownId」。',
      ),
      const SizedBox(height: 16),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final (title, builder) in _demos.values)
            YumeiroButton(
              label: title,
              variant: YumeiroButtonVariant.secondary,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) =>
                      _DemoPage(builder: builder, showBackButton: true),
                ),
              ),
            ),
        ],
      ),
    ],
  );
}

class _DemoPage extends StatelessWidget {
  const _DemoPage({
    required this.builder,
    this.contentKey,
    this.showBackButton = false,
  });

  final WidgetBuilder builder;
  final Key? contentKey;
  final bool showBackButton;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: YumeiroScrollView(
        child: Padding(
          key: contentKey,
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (showBackButton) ...[
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: YumeiroButton(
                        label: '返回示例目录',
                        variant: YumeiroButtonVariant.ghost,
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Builder(builder: builder),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
