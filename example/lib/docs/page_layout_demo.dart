import 'package:material_ui/material_ui.dart';
import 'package:yumeiro/yumeiro.dart';

// #region layout
Widget layoutDemo(BuildContext context) => const _PageLayoutDemo();

enum _NotificationChannel {
  system('系统通知', '从系统通知中心查看已完成的任务。'),
  inApp('应用内消息', '在应用内的消息列表中查看已完成的任务。');

  const _NotificationChannel(this.label, this.description);

  final String label;
  final String description;
}

class _PageLayoutDemo extends StatefulWidget {
  const _PageLayoutDemo();

  @override
  State<_PageLayoutDemo> createState() => _PageLayoutDemoState();
}

class _PageLayoutDemoState extends State<_PageLayoutDemo> {
  bool _notifyOnCompletion = true;
  _NotificationChannel _channel = _NotificationChannel.system;
  _NotificationChannel? _draftChannel;

  @override
  Widget build(BuildContext context) {
    final draft = _draftChannel;
    return draft == null ? _settings(context) : _details(draft);
  }

  Widget _settings(BuildContext context) {
    final theme = YumeiroTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const YumeiroPageHeader(title: '下载设置'),
        const SizedBox(height: 12),
        YumeiroCard.panel(
          padding: const EdgeInsets.all(10),
          child: YumeiroSettingRow(
            title: '任务完成通知',
            trailing: YumeiroSwitch(
              semanticLabel: '任务完成通知',
              value: _notifyOnCompletion,
              onChanged: (value) => setState(() => _notifyOnCompletion = value),
            ),
          ),
        ),
        const SizedBox(height: 12),
        YumeiroCard(
          padding: const EdgeInsets.all(12),
          onTap: () => setState(() => _draftChannel = _channel),
          child: YumeiroActionRow(
            leading: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('通知渠道', style: theme.typography.title),
                Text(_channel.label, style: theme.typography.supporting),
              ],
            ),
            actions: const [Icon(Icons.chevron_right_rounded)],
          ),
        ),
      ],
    );
  }

  Widget _details(_NotificationChannel draft) => SizedBox(
    // The embedded detail page needs a bounded viewport for its scroll view.
    height: 360,
    child: YumeiroCard.panel(
      padding: EdgeInsets.zero,
      child: YumeiroPageScaffold.detail(
        title: '通知渠道',
        onBack: _closeDetails,
        bottomBar: YumeiroActionBar(
          showBackground: false,
          primaryAction: YumeiroButton(
            label: '应用设置',
            variant: YumeiroButtonVariant.primary,
            onPressed: draft == _channel
                ? null
                : () => setState(() {
                    _channel = draft;
                    _draftChannel = null;
                  }),
          ),
          secondaryActions: [
            YumeiroButton(
              label: '取消',
              variant: YumeiroButtonVariant.secondary,
              onPressed: _closeDetails,
            ),
          ],
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const YumeiroSectionHeader(title: '选择通知渠道'),
            for (final channel in _NotificationChannel.values) ...[
              const SizedBox(height: 8),
              YumeiroCard(
                selected: channel == draft,
                padding: const EdgeInsets.all(12),
                onTap: () => setState(() => _draftChannel = channel),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(channel.label),
                    const SizedBox(height: 4),
                    Text(channel.description),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );

  void _closeDetails() => setState(() => _draftChannel = null);
}
// #endregion layout
