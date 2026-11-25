import 'package:material_ui/material_ui.dart';
import 'package:yumeiro/yumeiro.dart';

// #region theme-preview
Widget themePreviewDemo(BuildContext context) => DecoratedBox(
  decoration: const BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF416B89), Color(0xFF785985), Color(0xFFC58868)],
    ),
  ),
  child: Padding(
    padding: const EdgeInsets.all(16),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: YumeiroCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 12,
            children: [
              YumeiroTextField.form(label: '任务名称', initialValue: '核对发布资料'),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: YumeiroButton(
                  label: '查看详情',
                  variant: YumeiroButtonVariant.primary,
                  onPressed: () => YumeiroDialog.show<void>(
                    context: context,
                    builder: (_) => const YumeiroDialog(
                      title: '发布资料',
                      child: Text('检查安装指南、变更记录和示例。'),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  ),
);
// #endregion theme-preview
