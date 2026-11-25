import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform;
import 'package:material_ui/material_ui.dart';

import 'main_desktop.dart';
import 'main_mobile.dart';
import 'src/theme/gallery_registry.dart';

export 'main_desktop.dart' show YumeiroGalleryDesktopApp;
export 'main_mobile.dart' show YumeiroGalleryMobileApp;
export 'src/theme/gallery_registry.dart' show GalleryProfile;

const String _galleryProfileDefine = String.fromEnvironment('YUMEIRO_PROFILE');

/// Resolves the target gallery profile from `--dart-define=YUMEIRO_PROFILE`
/// (`mobile` | `desktop`) or falls back to [defaultTargetPlatform].
GalleryProfile resolveGalleryProfile() {
  switch (_galleryProfileDefine.trim().toLowerCase()) {
    case 'mobile':
      return GalleryProfile.mobile;
    case 'desktop':
      return GalleryProfile.desktop;
  }
  if (defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.fuchsia) {
    return GalleryProfile.mobile;
  }
  return GalleryProfile.desktop;
}

void main() {
  runApp(const YumeiroGalleryApp());
}

/// Auto-routing showcase root dispatching to either [YumeiroGalleryDesktopApp]
/// or [YumeiroGalleryMobileApp] based on platform or `--dart-define=YUMEIRO_PROFILE`.
class YumeiroGalleryApp extends StatelessWidget {
  const YumeiroGalleryApp({super.key, this.profile});

  final GalleryProfile? profile;

  @override
  Widget build(BuildContext context) {
    final resolved = profile ?? resolveGalleryProfile();
    return switch (resolved) {
      GalleryProfile.desktop => const YumeiroGalleryDesktopApp(),
      GalleryProfile.mobile => const YumeiroGalleryMobileApp(),
    };
  }
}
