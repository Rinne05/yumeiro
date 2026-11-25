import 'package:material_ui/material_ui.dart';

import 'glass_backdrop.dart';

/// Shares one live backdrop snapshot between non-overlapping controls on the
/// same background. Place this after their common background is painted.
/// Painted surfaces create a new sampling boundary for their own contents.
/// Optical surfaces use an independent input snapshot to keep
/// their clipped texture coordinates aligned with their geometry.
class YumeiroBackdropGroup extends StatefulWidget {
  const YumeiroBackdropGroup({super.key, required this.child});

  final Widget child;

  @override
  State<YumeiroBackdropGroup> createState() => _YumeiroBackdropGroupState();
}

class _YumeiroBackdropGroupState extends State<YumeiroBackdropGroup> {
  final _key = BackdropKey();

  @override
  Widget build(BuildContext context) {
    final parent = YumeiroGlassSamplingScope.maybeOf(context);
    return YumeiroGlassSamplingScope(
      backdropKey: parent?.backdropKey ?? _key,
      child: widget.child,
    );
  }
}
