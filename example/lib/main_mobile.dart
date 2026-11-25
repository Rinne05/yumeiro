import 'package:material_ui/material_ui.dart';
import 'package:yumeiro/yumeiro.dart';

import 'src/shell/gallery_shell.dart';
import 'src/state/gallery_controller.dart';
import 'src/theme/gallery_registry.dart';

void main() {
  runApp(const YumeiroGalleryMobileApp());
}

/// Standalone touch-modality mobile showcase entrypoint.
///
/// Launches directly via `flutter run -t lib/main_mobile.dart` or embeds cleanly
/// inside an isolated `390×844` phone preview frame hosted by
/// [YumeiroGalleryDesktopApp].
class YumeiroGalleryMobileApp extends StatefulWidget {
  const YumeiroGalleryMobileApp({
    super.key,
    this.controller,
    this.simulatedViewportSize,
    this.simulatedSafeArea,
  });

  final GalleryController? controller;
  final Size? simulatedViewportSize;
  final EdgeInsets? simulatedSafeArea;

  @override
  State<YumeiroGalleryMobileApp> createState() =>
      _YumeiroGalleryMobileAppState();
}

class _YumeiroGalleryMobileAppState extends State<YumeiroGalleryMobileApp> {
  GalleryController? _ownedController;

  GalleryController get _controller =>
      widget.controller ?? (_ownedController ??= GalleryController());

  @override
  void dispose() {
    _ownedController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => YumeiroApp(
        title: 'Yumeiro Mobile Gallery',
        registry: controller.registry,
        preset: controller.activePreset,
        capability: controller.capability,
        modality: YumeiroModality.touch,
        density: controller.density,
        locale: controller.locale,
        customizations: controller.customizations,
        advancedMotionEnabled: controller.advancedMotionEnabled,
        visualsAugmenter: augmentGalleryVisuals,
        builder: (context, child) {
          final size = widget.simulatedViewportSize;
          final padding = widget.simulatedSafeArea;
          if (size == null && padding == null) {
            return child ?? const SizedBox.shrink();
          }
          final mq = MediaQuery.of(context);
          return MediaQuery(
            data: mq.copyWith(
              size: size ?? mq.size,
              padding: padding ?? mq.padding,
              viewPadding: padding ?? mq.viewPadding,
              viewInsets: EdgeInsets.zero,
            ),
            child: child ?? const SizedBox.shrink(),
          );
        },
        home: GalleryShellPage(
          profile: GalleryProfile.mobile,
          controller: controller,
        ),
      ),
    );
  }
}
