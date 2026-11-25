import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:yumeiro/yumeiro.dart';

import '../../docs/overlays_demos.dart';
import '../state/gallery_controller.dart';
import '../theme/gallery_registry.dart';
import '../widgets/gallery_widgets.dart';
import '../widgets/selection_sheets_sample.dart';

/// Page 5: Interactive showcase for all Yumeiro dialogs, editors, sheets,
/// context menus, toasts, pointer tooltips, and touch detail push routes.
class OverlaysPage extends StatelessWidget {
  const OverlaysPage({
    super.key,
    required this.controller,
    required this.profile,
  });

  final GalleryController controller;
  final GalleryProfile profile;

  static const _cascadeOptions = {
    'render/optical': 'A',
    'render/blur': 'B',
    'theme/tokens': 'C',
    'theme/radii': 'D',
  };

  @override
  Widget build(BuildContext context) {
    final theme = YumeiroTheme.of(context);
    final isTouch = profile == GalleryProfile.mobile;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GalleryComponent(
          'YumeiroCallout',
          child: YumeiroCallout(
            title: gText(context, en: 'Latest action', zh: '最近操作'),
            message: controller.lastOverlayEvent.isEmpty
                ? gText(context, en: 'No action yet.', zh: '暂无操作。')
                : gText(
                    context,
                    en: controller.lastOverlayEvent,
                    zh: controller.lastOverlayEventZh,
                  ),
            statusRole: YumeiroStatusRole.info,
          ),
        ),
        SizedBox(height: theme.spacing.md),
        GalleryComponent(
          'YumeiroFieldLayout.readOnly',
          child: YumeiroFieldLayout.readOnly(
            label: gText(context, en: 'Field A', zh: '字段 A'),
            value: controller.overlaySamplePresent
                ? gSample(context, controller.overlaySampleName)
                : gText(context, en: 'No sample item', zh: '暂无示例项目'),
            bottomSpacing: 0,
          ),
        ),
        if (!controller.overlaySamplePresent) ...[
          SizedBox(height: theme.spacing.md),
          YumeiroCallout(
            message: gText(
              context,
              en: 'The sample item was removed. Reset it to continue editing or using its actions.',
              zh: '示例项目已移除，重置后可继续编辑和操作。',
            ),
            statusRole: YumeiroStatusRole.info,
            action: YumeiroButton(
              label: gText(context, en: 'Reset Sample Item', zh: '重置示例项目'),
              icon: theme.icons.refresh,
              onPressed: _resetSample,
            ),
          ),
        ],
        SizedBox(height: theme.spacing.xl),
        GallerySection(
          title: gText(context, en: 'Dialogs & Routes', zh: '对话框与路由'),
          children: [
            _dialogs(context),
            _filter(context),
            if (isTouch) ...[
              _bottomSheet(context),
              const SelectionSheetsSample(),
              GalleryCard.example(
                example: GalleryExample.detailRoute,
                description: gText(
                  context,
                  en: 'Open a detail page with its own back button and themed background.',
                  zh: '打开带返回按钮和主题背景的详情页。',
                ),
                child: GalleryComponent(
                  'YumeiroPageScaffold.detail',
                  child: YumeiroButton(
                    label: gText(
                      context,
                      en: 'Push Detail Route',
                      zh: '推入详情二级页',
                    ),
                    icon: theme.icons.chevronRight,
                    variant: YumeiroButtonVariant.primary,
                    onPressed: () => _pushMobileDetailRoute(context),
                  ),
                ),
              ),
            ],
          ],
        ),
        SizedBox(height: theme.spacing.xl),
        GallerySection(
          title: gText(context, en: 'Menus & Feedback', zh: '菜单与反馈'),
          children: [
            _menus(context, isTouch: isTouch),
            _toasts(context),
            _tooltip(context, isTouch: isTouch),
          ],
        ),
      ],
    );
  }

  Widget _dialogs(BuildContext context) {
    final theme = YumeiroTheme.of(context);
    return GalleryCard.example(
      example: GalleryExample.dialogs,
      child: Wrap(
        spacing: theme.spacing.sm,
        runSpacing: theme.spacing.sm,
        children: [
          GalleryComponent(
            'YumeiroDialog.show',
            child: YumeiroButton(
              label: gText(context, en: 'Open Dialog', zh: '打开基础弹窗'),
              icon: theme.icons.auto,
              variant: YumeiroButtonVariant.secondary,
              onPressed: () => _openStandardDialog(context),
            ),
          ),
          GalleryComponent(
            'YumeiroDialog.confirm',
            child: YumeiroButton(
              label: gText(context, en: 'Confirm Action', zh: '确认示例操作'),
              variant: YumeiroButtonVariant.secondary,
              onPressed: () => _openActionConfirmation(context),
            ),
          ),
          GalleryComponent(
            'YumeiroDialog.confirm(destructive: true)',
            child: YumeiroButton(
              label: gText(context, en: 'Confirm Dialog', zh: '打开确认弹窗'),
              icon: theme.icons.warning,
              variant: YumeiroButtonVariant.secondary,
              onPressed: controller.overlaySamplePresent
                  ? () => _openConfirmDialog(context)
                  : null,
            ),
          ),
          GalleryComponent(
            'YumeiroEditor.show',
            child: YumeiroButton(
              label: gText(context, en: 'Open Adaptive Editor', zh: '打开自适应编辑器'),
              icon: theme.icons.edit,
              variant: YumeiroButtonVariant.primary,
              onPressed: controller.overlaySamplePresent
                  ? () => _openAdaptiveEditor(context)
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomSheet(BuildContext context) => GalleryCard.example(
    example: GalleryExample.bottomSheet,
    child: GalleryComponent(
      'YumeiroBottomSheet.show',
      child: YumeiroButton(
        label: gText(context, en: 'Open Bottom Sheet', zh: '打开底部面板'),
        variant: YumeiroButtonVariant.secondary,
        onPressed: () => _openBottomSheet(context),
      ),
    ),
  );

  Widget _menus(BuildContext context, {required bool isTouch}) {
    final theme = YumeiroTheme.of(context);
    return GalleryCard.example(
      example: GalleryExample.menus,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: theme.spacing.md,
        children: [
          GalleryComponent(
            'YumeiroContextMenuRegion',
            child: YumeiroContextMenuRegion(
              focusable: true,
              menuBuilder: (menuContext, _) => _menuItems(menuContext),
              child: YumeiroCard.panel(
                role: YumeiroSurfaceRole.inset,
                child: Row(
                  spacing: theme.spacing.md,
                  children: [
                    Icon(theme.icons.more, color: theme.accentSoft),
                    Expanded(
                      child: Text(
                        isTouch
                            ? gText(
                                context,
                                en: 'Long-press to open the contextual actions.',
                                zh: '长按此区域打开上下文动作菜单。',
                              )
                            : gText(
                                context,
                                en: 'Right-click this area or focus it and press Shift+F10.',
                                zh: '右键点击此区域，或聚焦后按 Shift+F10。',
                              ),
                        style: theme.typography.supporting.copyWith(
                          color: theme.muted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          GalleryComponent(
            'YumeiroActionMenu.show',
            child: Builder(
              builder: (buttonContext) => YumeiroButton(
                label: gText(buttonContext, en: 'More Actions', zh: '更多操作'),
                variant: YumeiroButtonVariant.secondary,
                onPressed: () => YumeiroActionMenu.show(
                  context: buttonContext,
                  items: _menuItems(buttonContext),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filter(BuildContext context) {
    final theme = YumeiroTheme.of(context);
    final categories = controller.activeCategories
        .map((category) => gSample(context, category))
        .join(', ');
    final categoryLabel = categories.isEmpty ? '—' : categories;
    final option = _cascadeOptionLabel(context, controller.overlayCascadeValue);
    return GalleryCard.example(
      example: GalleryExample.compoundFilter,
      description: gText(
        context,
        en: 'Reset changes the draft. Apply saves it to the current sample.',
        zh: '重置修改草稿，应用后才更新当前筛选。',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: theme.spacing.sm,
        children: [
          GalleryComponent(
            'YumeiroFilter.show',
            child: YumeiroButton(
              label: gText(context, en: 'Open Filters', zh: '打开组合筛选'),
              variant: YumeiroButtonVariant.primary,
              onPressed: () => _openFilters(context),
            ),
          ),
          Text(
            gText(
              context,
              en: 'Applied: $categoryLabel · $option',
              zh: '已应用：$categoryLabel · $option',
            ),
            style: theme.typography.supporting,
          ),
        ],
      ),
    );
  }

  String _cascadeOptionLabel(BuildContext context, String value) {
    final option = _cascadeOptions[value];
    return option == null ? '—' : gSample(context, 'Option $option');
  }

  Widget _toasts(BuildContext context) {
    final theme = YumeiroTheme.of(context);
    return GalleryCard.example(
      example: GalleryExample.toasts,
      description: gText(
        context,
        en: 'Tap a timed notification to copy its message.',
        zh: '点击限时通知可复制内容。',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: theme.spacing.md,
        children: [
          GalleryComponent(
            'YumeiroToast',
            child: YumeiroToast(
              message: gText(context, en: 'Example message A', zh: '通知 A'),
              statusRole: YumeiroStatusRole.info,
            ),
          ),
          GalleryComponent(
            'showYumeiroToast',
            child: Wrap(
              spacing: theme.spacing.sm,
              runSpacing: theme.spacing.sm,
              children: [
                YumeiroButton(
                  label: gText(context, en: 'Trigger Toast', zh: '触发 Toast 通知'),
                  icon: theme.icons.info,
                  variant: YumeiroButtonVariant.primary,
                  onPressed: () => showYumeiroToast(
                    context,
                    gText(
                      context,
                      en: 'This is a notification example.',
                      zh: '这是一条通知示例。',
                    ),
                    title: gText(
                      context,
                      en: 'Example notification',
                      zh: '示例通知',
                    ),
                  ),
                ),
                for (final (en, zh, example, role) in const [
                  ('Info Toast', '信息提示', 'A', YumeiroStatusRole.info),
                  ('Success Toast', '成功提示', 'B', YumeiroStatusRole.success),
                  ('Warning Toast', '警告提示', 'C', YumeiroStatusRole.warning),
                  ('Danger Toast', '错误提示', 'D', YumeiroStatusRole.danger),
                ])
                  YumeiroButton(
                    label: gText(context, en: en, zh: zh),
                    variant: role == YumeiroStatusRole.danger
                        ? YumeiroButtonVariant.danger
                        : YumeiroButtonVariant.secondary,
                    onPressed: () => showYumeiroToast(
                      context,
                      gSample(context, 'Example $example'),
                      statusRole: role,
                    ),
                  ),
                YumeiroButton(
                  label: gText(context, en: 'Long Toast', zh: '长文本提示'),
                  variant: YumeiroButtonVariant.secondary,
                  onPressed: () => showYumeiroToast(
                    context,
                    gText(
                      context,
                      en: 'This is a longer example message. It wraps across multiple lines and can be copied by selecting the notification.',
                      zh: '这是一段用于展示换行的较长示例文本。通知会按可用宽度排版，也可以点击通知复制完整内容。',
                    ),
                    title: gText(
                      context,
                      en: 'Long message example',
                      zh: '长文本示例',
                    ),
                  ),
                ),
              ],
            ),
          ),
          const GalleryComponent(
            'YumeiroToastController.show(duration: Duration.zero)',
            child: PersistentToastDemo(),
          ),
        ],
      ),
    );
  }

  Widget _tooltip(BuildContext context, {required bool isTouch}) =>
      GalleryCard.example(
        example: GalleryExample.tooltip,
        description: isTouch
            ? null
            : gText(
                context,
                en: 'Tab focus also opens the tooltip.',
                zh: '按 Tab 聚焦按钮也能查看提示。',
              ),
        child: Wrap(
          spacing: YumeiroTheme.of(context).spacing.md,
          runSpacing: YumeiroTheme.of(context).spacing.md,
          children: [
            GalleryComponent(
              'YumeiroTooltip',
              child: YumeiroTooltip(
                message: gText(
                  context,
                  en: 'This is a tooltip example.',
                  zh: '这是一条悬浮提示示例。',
                ),
                showOnFocus: !isTouch,
                child: YumeiroButton(
                  label: isTouch
                      ? gText(context, en: 'Hold for Tooltip', zh: '长按查看提示')
                      : gText(context, en: 'Hover for Tooltip', zh: '悬停查看提示'),
                  variant: YumeiroButtonVariant.secondary,
                  onPressed: () {},
                ),
              ),
            ),
            if (isTouch)
              GalleryComponent(
                'YumeiroTooltip(triggerMode: tap)',
                child: YumeiroTooltip(
                  triggerMode: TooltipTriggerMode.tap,
                  message: gText(
                    context,
                    en: 'Example B tooltip.',
                    zh: '这是示例 B 的提示。',
                  ),
                  child: YumeiroCard.panel(
                    child: Text(
                      gText(context, en: 'Tap for Tooltip', zh: '点击查看提示'),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );

  void _resetSample() {
    controller.resetOverlaySample();
    controller.recordOverlayEvent(en: 'Sample content reset.', zh: '已重置示例内容。');
  }

  Future<void> _openStandardDialog(BuildContext context) async {
    await YumeiroDialog.show<void>(
      context: context,
      builder: (dialogContext) => YumeiroDialog(
        title: gText(context, en: 'Sample dialog', zh: '示例对话框'),
        actions: [
          YumeiroButton(
            label: gText(context, en: 'Close', zh: '关闭'),
            variant: YumeiroButtonVariant.primary,
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
        ],
        child: Text(
          gText(
            context,
            en: 'This is the sample dialog content.',
            zh: '这是一段示例对话框内容。',
          ),
        ),
      ),
    );
    if (context.mounted) {
      controller.recordOverlayEvent(en: 'Dialog closed.', zh: '已关闭对话框。');
    }
  }

  Future<void> _openConfirmDialog(BuildContext context) async {
    final confirmed = await YumeiroDialog.confirm(
      context: context,
      title: gText(context, en: 'Remove sample item?', zh: '移除示例项目？'),
      message: gText(
        context,
        en: 'Only the local sample item will be removed. Use Reset to restore it.',
        zh: '仅移除当前示例项目，可通过重置操作恢复。',
      ),
      destructive: true,
    );
    if (!context.mounted) return;
    if (confirmed) controller.deleteOverlaySample();
    controller.recordOverlayEvent(
      en: confirmed ? 'Sample item removed.' : 'Removal cancelled.',
      zh: confirmed ? '已移除示例项目。' : '已取消移除。',
    );
  }

  Future<void> _openActionConfirmation(BuildContext context) async {
    final confirmed = await YumeiroDialog.confirm(
      context: context,
      title: gText(context, en: 'Apply Example A?', zh: '应用示例 A？'),
      message: gText(
        context,
        en: 'Confirm to record the action.',
        zh: '确认后记录这次操作。',
      ),
    );
    if (!context.mounted) return;
    controller.recordOverlayEvent(
      en: confirmed ? 'Sample action applied.' : 'Sample action cancelled.',
      zh: confirmed ? '已应用示例操作。' : '已取消示例操作。',
    );
  }

  Future<void> _openAdaptiveEditor(BuildContext context) async {
    final saved = await YumeiroEditor.show<bool>(
      context: context,
      builder: (_) => _GallerySampleEditor(
        name: controller.overlaySampleName,
        enabled: controller.overlaySampleEnabled,
        onSave: controller.saveOverlaySample,
      ),
    );
    if (!context.mounted) return;
    controller.recordOverlayEvent(
      en: saved == true ? 'Sample content saved.' : 'Editing cancelled.',
      zh: saved == true ? '已保存示例内容。' : '已取消编辑。',
    );
  }

  Future<void> _openBottomSheet(BuildContext context) async {
    await YumeiroBottomSheet.show<void>(
      context: context,
      builder: (sheetContext) => YumeiroBottomSheet(
        title: gText(context, en: 'Sample content', zh: '示例内容'),
        actions: [
          YumeiroButton(
            label: gText(context, en: 'Done', zh: '完成'),
            variant: YumeiroButtonVariant.primary,
            onPressed: () => Navigator.of(sheetContext).pop(),
          ),
        ],
        child: GalleryComponent(
          'YumeiroFieldLayout.readOnly',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              YumeiroFieldLayout.readOnly(
                label: gText(context, en: 'Field A', zh: '字段 A'),
                value: controller.overlaySamplePresent
                    ? gSample(context, controller.overlaySampleName)
                    : gText(context, en: 'No sample item', zh: '暂无示例项目'),
              ),
              YumeiroFieldLayout.readOnly(
                label: gText(context, en: 'Field B', zh: '字段 B'),
                value: controller.overlaySamplePresent
                    ? gSample(context, 'Example B')
                    : '—',
                bottomSpacing: 0,
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<YumeiroMenuEntry> _menuItems(BuildContext context) {
    final theme = YumeiroTheme.of(context);
    final present = controller.overlaySamplePresent;
    return [
      YumeiroMenuHeader(
        title: gText(context, en: 'Option state', zh: '选项状态'),
      ),
      for (final enabled in [true, false])
        YumeiroMenuAction(
          label: enabled
              ? gText(context, en: 'Enable sample option', zh: '启用示例选项')
              : gText(context, en: 'Disable sample option', zh: '关闭示例选项'),
          icon: theme.icons.settings,
          enabled: present,
          selected: present ? controller.overlaySampleEnabled == enabled : null,
          onPressed: () {
            controller.setOverlaySampleEnabled(enabled);
            controller.recordOverlayEvent(
              en: enabled
                  ? 'Sample option enabled.'
                  : 'Sample option disabled.',
              zh: enabled ? '已启用示例选项。' : '已关闭示例选项。',
            );
          },
        ),
      const YumeiroMenuDivider(),
      YumeiroMenuHeader(
        title: gText(context, en: 'Sample text', zh: '文本操作'),
      ),
      YumeiroMenuAction(
        label: gText(context, en: 'Copy sample text', zh: '复制示例文本'),
        icon: theme.icons.copy,
        enabled: present,
        onPressed: () => _copySample(context),
      ),
      const YumeiroMenuDivider(),
      YumeiroMenuAction(
        label: gText(context, en: 'Reset sample content', zh: '重置示例内容'),
        icon: theme.icons.refresh,
        destructive: true,
        onPressed: _resetSample,
      ),
    ];
  }

  Future<void> _copySample(BuildContext context) async {
    if (!controller.overlaySamplePresent) return;
    await Clipboard.setData(
      ClipboardData(text: gSample(context, controller.overlaySampleName)),
    );
    if (!context.mounted) return;
    const en = 'Sample text copied.';
    const zh = '已复制示例文本。';
    controller.recordOverlayEvent(en: en, zh: zh);
    showYumeiroToast(context, gText(context, en: en, zh: zh));
  }

  Future<void> _openFilters(BuildContext context) async {
    final result =
        await YumeiroFilter.show<({Set<String> categories, String cascade})>(
          context: context,
          title: gText(context, en: 'Filter sample content', zh: '筛选示例内容'),
          initialValue: (
            categories: Set<String>.of(controller.activeCategories),
            cascade: controller.overlayCascadeValue,
          ),
          resetValue: (
            categories: const {'Category A'},
            cascade: 'render/optical',
          ),
          builder: (context, draft, onChanged) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GalleryComponent(
                'YumeiroSelectionRow',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final item in const [
                      'Category A',
                      'Category B',
                      'Category C',
                      'Category D',
                    ])
                      YumeiroSelectionRow(
                        title: Text(gSample(context, item)),
                        selected: draft.categories.contains(item),
                        multiple: true,
                        onChanged: (checked) {
                          final next = Set<String>.of(draft.categories);
                          if (checked) {
                            next.add(item);
                          } else {
                            next.remove(item);
                          }
                          onChanged((categories: next, cascade: draft.cascade));
                        },
                      ),
                  ],
                ),
              ),
              const YumeiroDivider(height: 24, touchHeight: 1),
              GalleryComponent(
                'YumeiroCascadingSelection',
                child: YumeiroCascadingSelection<String>(
                  value: draft.cascade,
                  options: [
                    for (final (id, group) in const [
                      ('render', 'A'),
                      ('theme', 'B'),
                    ])
                      YumeiroCascadingOption.branch(
                        id: id,
                        label: gSample(context, 'Group $group'),
                        children: [
                          for (final entry in _cascadeOptions.entries)
                            if (entry.key.startsWith('$id/'))
                              YumeiroCascadingOption(
                                id: entry.key,
                                label: gSample(
                                  context,
                                  'Option ${entry.value}',
                                ),
                                value: entry.key,
                              ),
                        ],
                      ),
                  ],
                  onChanged: (nextCascade) => onChanged((
                    categories: draft.categories,
                    cascade: nextCascade,
                  )),
                ),
              ),
            ],
          ),
        );
    if (!context.mounted) return;
    if (result != null) {
      controller.setActiveCategories(result.categories);
      controller.setOverlayCascadeValue(result.cascade);
      final option = _cascadeOptions[result.cascade];
      controller.recordOverlayEvent(
        en: 'Selected ${result.categories.length} categories and option $option.',
        zh: '已选择 ${result.categories.length} 个分类和选项 $option。',
      );
    }
  }

  void _pushMobileDetailRoute(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        pageBuilder: (routeContext, _, _) => YumeiroVisualSurface(
          role: YumeiroSurfaceRole.canvas,
          child: YumeiroPageScaffold.detail(
            title: gText(routeContext, en: 'Detail Push Route', zh: '二级详情路由页'),
            onBack: () => Navigator.of(routeContext).pop(),
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GalleryComponent(
                  'YumeiroCallout',
                  child: YumeiroCallout(
                    title: gSample(routeContext, 'Example A'),
                    message: gText(
                      routeContext,
                      en: 'Example description',
                      zh: '示例说明',
                    ),
                    statusRole: YumeiroStatusRole.success,
                  ),
                ),
                const SizedBox(height: 16),
                GalleryComponent(
                  'YumeiroFieldLayout.readOnly',
                  child: YumeiroFieldLayout.readOnly(
                    label: gText(routeContext, en: 'Field A', zh: '字段 A'),
                    value: gSample(routeContext, 'Example B'),
                  ),
                ),
              ],
            ),
          ),
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            YumeiroPageTransition(
              animation: animation,
              secondaryAnimation: secondaryAnimation,
              child: child,
            ),
      ),
    );
  }
}

/// Owns its local draft until Save; cancelling leaves all gallery state intact.
class _GallerySampleEditor extends StatefulWidget {
  const _GallerySampleEditor({
    required this.name,
    required this.enabled,
    required this.onSave,
  });
  final String name;
  final bool enabled;
  final void Function(String name, bool enabled) onSave;

  @override
  State<_GallerySampleEditor> createState() => _GallerySampleEditorState();
}

class _GallerySampleEditorState extends State<_GallerySampleEditor> {
  late final _name = TextEditingController(text: widget.name);
  late bool _enabled = widget.enabled;
  var _saving = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<bool> _confirmDiscard() async {
    if (_name.text == widget.name && _enabled == widget.enabled) return true;

    return YumeiroDialog.confirm(
      context: context,
      title: gText(context, en: 'Discard unsaved changes?', zh: '丢弃未保存的更改？'),
      cancelLabel: gText(context, en: 'Keep Editing', zh: '继续编辑'),
      confirmLabel: gText(context, en: 'Discard', zh: '丢弃'),
      destructive: true,
    );
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (!mounted) return;

    widget.onSave(_name.text, _enabled);
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) => YumeiroEditor(
    title: gText(context, en: 'Edit sample content', zh: '编辑示例内容'),
    busy: _saving,
    onLeave: _confirmDiscard,
    headerAccessory: _saving
        ? YumeiroSpinner(
            size: 16,
            label: gText(context, en: 'Saving…', zh: '保存中…'),
          )
        : null,
    actions: [
      YumeiroButton(
        label: gText(context, en: 'Cancel', zh: '取消'),
        variant: YumeiroButtonVariant.ghost,
        onPressed: _saving ? null : () => Navigator.of(context).maybePop(),
      ),
      YumeiroButton(
        label: gText(context, en: 'Save', zh: '保存'),
        variant: YumeiroButtonVariant.primary,
        onPressed: _saving ? null : _save,
      ),
    ],
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GalleryComponent(
          'YumeiroTextField',
          child: YumeiroFieldLayout(
            label: gText(context, en: 'Field A', zh: '字段 A'),
            child: YumeiroTextField(controller: _name, enabled: !_saving),
          ),
        ),
        GalleryComponent(
          'YumeiroSwitch',
          child: YumeiroSettingRow(
            title: gSample(context, 'Option A'),
            trailing: YumeiroSwitch(
              value: _enabled,
              onChanged: _saving
                  ? null
                  : (value) => setState(() => _enabled = value),
            ),
          ),
        ),
      ],
    ),
  );
}
