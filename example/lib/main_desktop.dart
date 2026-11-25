import 'package:material_ui/material_ui.dart';
import 'package:yumeiro/yumeiro.dart';

import 'main_mobile.dart';
import 'src/shell/gallery_shell.dart';
import 'src/state/gallery_controller.dart';
import 'src/theme/gallery_registry.dart';

void main() {
  runApp(const YumeiroGalleryDesktopApp());
}

/// Standalone pointer-modality desktop showcase entrypoint.
///
/// Launches directly via `flutter run -t lib/main_desktop.dart` and hosts an
/// optional isolated `390×844` mobile device frame running
/// [YumeiroGalleryMobileApp] in its own [YumeiroModality.touch], [MediaQuery],
/// and root [Navigator] scope while synchronizing theme, capability, density,
/// locale, motion, and live preset customization tokens.
class YumeiroGalleryDesktopApp extends StatefulWidget {
  const YumeiroGalleryDesktopApp({
    super.key,
    this.initialShowMobilePreview = false,
  });

  final bool initialShowMobilePreview;

  @override
  State<YumeiroGalleryDesktopApp> createState() =>
      _YumeiroGalleryDesktopAppState();
}

class _YumeiroGalleryDesktopAppState extends State<YumeiroGalleryDesktopApp> {
  late final YumeiroThemeRegistry _sharedRegistry = createGalleryRegistry();
  late final GalleryController _desktopController = GalleryController(
    registry: _sharedRegistry,
  );
  late final GalleryController _mobileController = GalleryController(
    registry: _sharedRegistry,
  );
  late bool _showMobilePreview = widget.initialShowMobilePreview;
  late int _lastSyncedAppearanceRevision;

  @override
  void initState() {
    super.initState();
    _lastSyncedAppearanceRevision = _desktopController.appearanceRevision;
    _desktopController.addListener(_syncDesktopTokensToMobile);
  }

  void _syncDesktopTokensToMobile() {
    final revision = _desktopController.appearanceRevision;
    if (revision == _lastSyncedAppearanceRevision) return;
    _lastSyncedAppearanceRevision = revision;
    _mobileController.copyDesignSettingsFrom(_desktopController);
  }

  @override
  void dispose() {
    _desktopController.removeListener(_syncDesktopTokensToMobile);
    _desktopController.dispose();
    _mobileController.dispose();
    _sharedRegistry.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: ColoredBox(
        color: const Color(0xFF0B0E14),
        child: LayoutBuilder(
          builder: (context, constraints) {
            const minDesktopPaneWidth = 530.0;
            final canShowMobilePreview =
                constraints.maxWidth >=
                minDesktopPaneWidth + _IsolatedMobileDevicePane.paneWidth;
            final mobilePreviewOpen =
                canShowMobilePreview && _showMobilePreview;
            return Row(
              children: [
                Expanded(
                  child: ListenableBuilder(
                    listenable: _desktopController,
                    builder: (context, _) => YumeiroApp(
                      title: 'Yumeiro Desktop Gallery',
                      registry: _desktopController.registry,
                      preset: _desktopController.activePreset,
                      capability: _desktopController.capability,
                      modality: YumeiroModality.pointer,
                      density: _desktopController.density,
                      locale: _desktopController.locale,
                      customizations: _desktopController.customizations,
                      advancedMotionEnabled:
                          _desktopController.advancedMotionEnabled,
                      visualsAugmenter: augmentGalleryVisuals,
                      builder: (context, child) => LayoutBuilder(
                        builder: (context, constraints) => MediaQuery(
                          data: MediaQuery.of(context)
                              .copyWith(size: constraints.biggest),
                          child: child!,
                        ),
                      ),
                      home: GalleryShellPage(
                        profile: GalleryProfile.desktop,
                        controller: _desktopController,
                        mobilePreviewOpen: mobilePreviewOpen,
                        onToggleMobilePreview: canShowMobilePreview
                            ? () => setState(
                                () => _showMobilePreview = !_showMobilePreview,
                              )
                            : null,
                      ),
                    ),
                  ),
                ),
                if (mobilePreviewOpen)
                  _IsolatedMobileDevicePane(
                    controller: _mobileController,
                    onClose: () => setState(() => _showMobilePreview = false),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _IsolatedMobileDevicePane extends StatelessWidget {
  const _IsolatedMobileDevicePane({
    required this.controller,
    required this.onClose,
  });

  final GalleryController controller;
  final VoidCallback onClose;

  static const paneWidth = 430.0;
  static const _deviceSize = Size(390, 844);
  static const _safeArea = EdgeInsets.only(top: 44, bottom: 28);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: paneWidth,
      decoration: const BoxDecoration(
        color: Color(0xFF0E1219),
        border: Border(left: BorderSide(color: Color(0x26FFFFFF))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.smartphone_rounded,
                size: 16,
                color: Color(0xCCFFFFFF),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Isolated Mobile Viewport · 390×844 (Touch)',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xCCFFFFFF),
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
              YumeiroButton(
                variant: YumeiroButtonVariant.ghost,
                icon: Icons.close_rounded,
                semanticLabel: 'Close mobile viewport',
                width: 32,
                height: 32,
                onPressed: onClose,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Center(
              child: FittedBox(
                fit: BoxFit.contain,
                child: Container(
                  width: _deviceSize.width + 16,
                  height: _deviceSize.height + 16,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF161B24),
                    borderRadius: BorderRadius.circular(42),
                    border: Border.all(
                      color: const Color(0x33FFFFFF),
                      width: 2,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x66000000),
                        blurRadius: 32,
                        offset: Offset(0, 16),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(34),
                    child: Stack(
                      children: [
                        SizedBox(
                          width: _deviceSize.width,
                          height: _deviceSize.height,
                          child: YumeiroGalleryMobileApp(
                            controller: controller,
                            simulatedViewportSize: _deviceSize,
                            simulatedSafeArea: _safeArea,
                          ),
                        ),
                        const Positioned(
                          top: 12,
                          left: 0,
                          right: 0,
                          child: IgnorePointer(
                            child: Center(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: Color(0xFF000000),
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(99),
                                  ),
                                ),
                                child: SizedBox(width: 96, height: 22),
                              ),
                            ),
                          ),
                        ),
                        const Positioned(
                          bottom: 10,
                          left: 0,
                          right: 0,
                          child: IgnorePointer(
                            child: Center(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: Color(0x66FFFFFF),
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(99),
                                  ),
                                ),
                                child: SizedBox(width: 120, height: 4),
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
          ),
        ],
      ),
    );
  }
}
