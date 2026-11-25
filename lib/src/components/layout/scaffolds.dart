import 'package:material_ui/material_ui.dart';

import 'page_header.dart';
import 'scroll_view.dart';

/// Safe-area and keyboard-aware page scaffold with no routing or business ownership.
class YumeiroPageScaffold extends StatelessWidget {
  const YumeiroPageScaffold({
    super.key,
    required Widget this._appBar,
    this.bottomBar,
    required this.body,
  }) : _detail = null;

  /// Builds a [YumeiroPageHeader.compact] and optionally scrolls the body.
  const YumeiroPageScaffold.detail({
    super.key,
    required String title,
    required this.body,
    VoidCallback? onBack,
    List<Widget> actions = const [],
    this.bottomBar,
    bool scrollable = true,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
  }) : _appBar = null,
       _detail = (
         title: title,
         onBack: onBack,
         actions: actions,
         scrollable: scrollable,
         padding: padding,
       );

  final Widget? _appBar;
  final ({
    String title,
    VoidCallback? onBack,
    List<Widget> actions,
    bool scrollable,
    EdgeInsetsGeometry padding,
  })?
  _detail;

  Widget get appBar =>
      _appBar ??
      YumeiroPageHeader.compact(
        title: _detail!.title,
        onBack: _detail.onBack,
        actions: _detail.actions,
      );
  final Widget? bottomBar;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    final detail = _detail;
    final content = detail == null
        ? body
        : detail.scrollable
        ? YumeiroScrollView(padding: detail.padding, child: body)
        : Padding(padding: detail.padding, child: body);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: appBar,
            ),
            Expanded(child: content),
            ?bottomBar,
          ],
        ),
      ),
    );
  }
}
