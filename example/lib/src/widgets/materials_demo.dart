import 'package:material_ui/material_ui.dart';
import 'package:yumeiro/yumeiro.dart';

import 'gallery_backdrop.dart';
import 'gallery_widgets.dart';

/// Composes reusable materials without changing the surrounding preset.
class GalleryMaterialsDemo extends StatefulWidget {
  const GalleryMaterialsDemo({super.key});

  @override
  State<GalleryMaterialsDemo> createState() => _GalleryMaterialsDemoState();
}

class _GalleryMaterialsDemoState extends State<GalleryMaterialsDemo> {
  bool _selected = false;

  @override
  Widget build(BuildContext context) {
    final theme = YumeiroTheme.of(context);
    final metal = YumeiroMaterials.brushedMetal(color: const Color(0xFFD7DFE5));
    final ceramic = YumeiroMaterials.ceramic(color: const Color(0xFFF5EEE5));
    final acrylic = YumeiroMaterials.acrylic(tint: const Color(0x80FFFFFF));
    final transition = YumeiroVisualTransition(
      duration: theme.motion.fast,
      curve: Curves.easeOutCubic,
    );
    final caption = theme.typography.caption.copyWith(
      color: const Color(0xFF243744),
    );

    YumeiroVisualAppearance appearance(YumeiroVisualMaterial material) =>
        material.appearance(
          foreground: const Color(0xFF243744),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          transition: transition,
        );

    return YumeiroResolvedVisualSurface(
      appearance: appearance(metal),
      padding: const EdgeInsets.all(20),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('YumeiroMaterials.brushedMetal', style: caption),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: GalleryBackdrop(
              brightness: Brightness.light,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: YumeiroResolvedVisualSurface(
                  appearance: appearance(acrylic),
                  padding: const EdgeInsets.all(20),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('YumeiroMaterials.acrylic', style: caption),
                      const SizedBox(height: 8),
                      Text(
                        gText(
                          context,
                          en: 'Softly blurred color behind an opaque ceramic action.',
                          zh: '彩色背景透过卡片柔和模糊，陶瓷按钮保持不透明质感。',
                        ),
                        style: theme.typography.body.copyWith(
                          color: const Color(0xFF415460),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text('YumeiroMaterials.ceramic', style: caption),
                      SizedBox(height: theme.spacing.xs),
                      YumeiroButton(
                        label: _selected
                            ? gText(context, en: 'Selected', zh: '已选中')
                            : gText(context, en: 'Example A', zh: '示例 A'),
                        icon: _selected ? theme.icons.check : theme.icons.auto,
                        selected: _selected,
                        visualOverride: YumeiroVisualOverride(
                          base: YumeiroVisualDelta(
                            fill: ceramic.fill,
                            outline: ceramic.outline,
                            effects: ceramic.effects,
                            foreground: const Color(0xFF243744),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                        onPressed: () => setState(() => _selected = !_selected),
                      ),
                    ],
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
