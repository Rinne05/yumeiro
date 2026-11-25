import 'package:material_ui/material_ui.dart';
import 'package:yumeiro/yumeiro.dart';

// #region menus
Widget menusDemo(BuildContext context) {
  var pinned = false;
  var status = '尚未操作';
  return StatefulBuilder(
    builder: (context, setState) {
      List<YumeiroMenuEntry> actions() => [
        const YumeiroMenuHeader(title: '下载任务'),
        YumeiroMenuAction(
          label: '打开详情',
          onPressed: () => setState(() => status = '已打开任务详情'),
        ),
        YumeiroMenuAction(
          label: '置顶',
          icon: Icons.push_pin_outlined,
          selected: pinned,
          onPressed: () => setState(() {
            pinned = !pinned;
            status = pinned ? '已置顶' : '已取消置顶';
          }),
        ),
        const YumeiroMenuDivider(),
        const YumeiroMenuAction(label: '重新下载', enabled: false),
      ];

      return YumeiroContextMenuRegion(
        menuBuilder: (context, position) => actions(),
        child: YumeiroCard.panel(
          child: YumeiroActionRow(
            leading: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('晨雾信号'),
                Text(status),
                Text(
                  YumeiroModalityScope.metricsOf(context).isTouch
                      ? '长按以打开菜单'
                      : '右键或按 Shift+F10 打开菜单',
                ),
                const YumeiroTooltip(
                  message: '任务已下载，可离线查看。',
                  child: Text('下载状态 · 已完成'),
                ),
              ],
            ),
            actions: [
              Builder(
                builder: (context) => YumeiroButton(
                  variant: YumeiroButtonVariant.ghost,
                  icon: YumeiroTheme.of(context).icons.more,
                  tooltip: '任务菜单',
                  onPressed: () {
                    final trigger = context.findRenderObject()! as RenderBox;
                    YumeiroActionMenu.show(
                      context: context,
                      globalPosition: trigger.localToGlobal(
                        Offset(0, trigger.size.height),
                      ),
                      items: actions(),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
// #endregion menus

// #region sheets
Widget sheetsDemo(BuildContext context) {
  var category = '全部';
  var tags = <String>{'访谈'};
  const defaultFilter = (completedOnly: false, includeArchived: false);
  var filter = defaultFilter;
  return StatefulBuilder(
    builder: (context, setState) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 12,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            SizedBox(
              width: 190,
              child: YumeiroFieldLayout(
                label: '选择分类',
                child: YumeiroSelect<String>(
                  options: const [
                    YumeiroSelectionOption(value: '全部', label: '全部'),
                    YumeiroSelectionOption(value: '下载', label: '下载'),
                    YumeiroSelectionOption(value: '归档', label: '归档'),
                  ],
                  value: category,
                  onChanged: (value) => setState(() => category = value),
                  title: '任务分类',
                  semanticLabel: '选择分类',
                  expand: true,
                ),
              ),
            ),
            SizedBox(
              width: 190,
              child: YumeiroMultiSelect<String>(
                options: const [
                  YumeiroSelectionOption(value: '访谈', label: '访谈'),
                  YumeiroSelectionOption(value: '短片', label: '短片'),
                  YumeiroSelectionOption(value: '纪实', label: '纪实'),
                ],
                value: tags,
                onChanged: (value) => setState(() => tags = value),
                label: '选择标签',
                title: '任务标签',
                searchable: true,
              ),
            ),
          ],
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            YumeiroButton(
              label: '编辑筛选',
              variant: YumeiroButtonVariant.secondary,
              onPressed: () async {
                final result = await YumeiroFilter.show(
                  context: context,
                  title: '筛选下载任务',
                  initialValue: filter,
                  resetValue: defaultFilter,
                  builder: (context, draft, update) => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      YumeiroSelectionRow(
                        card: true,
                        title: const Text('仅显示已下载'),
                        selected: draft.completedOnly,
                        onChanged: (value) => update((
                          completedOnly: value,
                          includeArchived: draft.includeArchived,
                        )),
                      ),
                      YumeiroSelectionRow(
                        card: true,
                        title: const Text('包含归档任务'),
                        selected: draft.includeArchived,
                        onChanged: (value) => update((
                          completedOnly: draft.completedOnly,
                          includeArchived: value,
                        )),
                      ),
                    ],
                  ),
                );
                if (context.mounted && result != null) {
                  setState(() => filter = result);
                }
              },
            ),
            if (YumeiroModalityScope.metricsOf(context).isTouch)
              YumeiroButton(
                label: '打开基础底部面板',
                variant: YumeiroButtonVariant.secondary,
                onPressed: () => YumeiroBottomSheet.show<void>(
                  context: context,
                  builder: (panelContext) => YumeiroBottomSheet(
                    title: '下载说明',
                    actions: [
                      YumeiroButton(
                        label: '完成',
                        onPressed: () => Navigator.of(panelContext).pop(),
                      ),
                    ],
                    child: const Text('已下载的文件可在离线时查看。'),
                  ),
                ),
              ),
          ],
        ),
        Text(
          '当前筛选 · ${filter.completedOnly ? '仅已下载' : '全部下载状态'}'
          ' · ${filter.includeArchived ? '含归档任务' : '隐藏归档任务'}',
        ),
      ],
    ),
  );
}
// #endregion sheets

// #region toasts
Widget toastsDemo(BuildContext context) => Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  spacing: 8,
  children: [
    YumeiroButton(
      label: '显示成功通知',
      onPressed: () => showYumeiroToast(
        context,
        '任务已同步。',
        statusRole: YumeiroStatusRole.success,
        copyOnTap: false,
      ),
    ),
    const PersistentToastDemo(),
  ],
);

class PersistentToastDemo extends StatefulWidget {
  const PersistentToastDemo({super.key});

  @override
  State<PersistentToastDemo> createState() => _PersistentToastDemoState();
}

class _PersistentToastDemoState extends State<PersistentToastDemo> {
  int? _toastId;

  @override
  Widget build(BuildContext context) {
    final chinese = Localizations.localeOf(context).languageCode == 'zh';
    final controller = YumeiroToastScope.of(context);
    final activeId = controller.entries
        .where((entry) => entry.id == _toastId)
        .firstOrNull
        ?.id;
    final spacing = YumeiroTheme.of(context).spacing.sm;
    return Wrap(
      spacing: spacing,
      runSpacing: spacing,
      children: [
        YumeiroButton(
          label: chinese ? '显示常驻通知' : 'Show persistent notification',
          variant: YumeiroButtonVariant.secondary,
          onPressed: activeId == null
              ? () {
                  final id = controller.show(
                    message: chinese ? '等待手动关闭。' : 'Waiting for dismissal.',
                    statusRole: YumeiroStatusRole.info,
                    duration: Duration.zero,
                    copyOnTap: false,
                  );
                  setState(() => _toastId = id);
                }
              : null,
        ),
        YumeiroButton(
          label: chinese ? '关闭常驻通知' : 'Dismiss persistent notification',
          variant: YumeiroButtonVariant.secondary,
          onPressed: activeId == null
              ? null
              : () => controller.dismiss(activeId),
        ),
      ],
    );
  }
}
// #endregion toasts
