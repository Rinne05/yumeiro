import 'package:yumeiro_example/src/state/gallery_controller.dart';

/// Select a fixture theme through the same family and appearance controls as the gallery.
void selectGalleryPreset(GalleryController controller, String presetId) {
  final preset = controller.registry.maybePresetById(presetId)!;
  final family = controller.registry.familyForPreset(preset)!;
  if (family.variants.length > 1) {
    controller.setPreferredVariant(family.variantOf(preset)!);
  }
  controller.setThemeFamily(family.id);
}
