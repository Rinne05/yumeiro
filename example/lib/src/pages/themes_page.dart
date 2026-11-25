import 'package:material_ui/material_ui.dart';
import 'package:yumeiro/yumeiro.dart';

import '../state/gallery_controller.dart';
import '../theme/gallery_registry.dart';
import '../widgets/gallery_widgets.dart';
import '../widgets/materials_demo.dart';

/// Page 1: Showcases all built-in and custom [YumeiroThemePreset]s, dynamic
/// [YumeiroThemeOption] parameter tuning, runtime capability simulation,
/// density/locale/motion preferences, color tokens, and custom roles/passes.
class ThemesPage extends StatelessWidget {
  const ThemesPage({
    super.key,
    required this.controller,
    required this.profile,
  });

  final GalleryController controller;
  final GalleryProfile profile;

  @override
  Widget build(BuildContext context) {
    final theme = YumeiroTheme.of(context);
    final l10n = YumeiroLocalizations.of(context);
    final activePreset = controller.activePreset;
    final families = controller.registry.families;
    final effectiveCapability = YumeiroMaterialCapabilityScope.of(context)
        .resolveForRuntime();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GallerySection(
          title: gText(
            context,
            en: 'Theme Style & Appearance',
            zh: '主题风格与外观模式',
          ),
          subtitle: gText(
            context,
            en: 'Light and dark preferences carry over between styles.',
            zh: '切换主题风格时会保留明暗偏好。',
          ),
          trailing: YumeiroBadge(
            label: activePreset.resolveLabel(l10n),
            statusRole: YumeiroStatusRole.accent,
            icon: activePreset.resolveIcon(theme.icons),
          ),
          children: [
            YumeiroCard.panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _GalleryAppearancePicker(controller: controller),
                  SizedBox(height: theme.spacing.lg),
                  const YumeiroDivider(),
                  SizedBox(height: theme.spacing.lg),
                  GalleryComponent(
                    'YumeiroCard',
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final spacing = theme.spacing.md;
                        final columns =
                            ((constraints.maxWidth + spacing) / (210 + spacing))
                                .floor()
                                .clamp(1, 5);
                        final cardWidth =
                            ((constraints.maxWidth - spacing * (columns - 1)) /
                                    columns)
                                .floorToDouble();
                        return Wrap(
                          spacing: spacing,
                          runSpacing: spacing,
                          children: [
                            for (final family in families)
                              GalleryPresetCard(
                                key: ValueKey('theme-family-${family.id}'),
                                family: family,
                                preset: family.resolve(
                                  controller.preferredVariant,
                                ),
                                selected:
                                    family.id == controller.activeFamily?.id,
                                width: cardWidth,
                                onTap: () =>
                                    controller.setThemeFamily(family.id),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: theme.spacing.xl),
        GallerySection(
          title: gText(
            context,
            en: 'Preset Customization Engine',
            zh: '预设参数实时定制',
          ),
          trailing: YumeiroButton(
            label: gText(context, en: 'Reset Options', zh: '重置参数'),
            icon: theme.icons.refresh,
            onPressed: controller.customizations.isEmpty
                ? null
                : controller.resetCustomizations,
          ),
          children: [
            GalleryCard.example(
              example: GalleryExample.themeOptions,
              description: activePreset.resolveLabel(l10n),
              child: GalleryPresetOptionsEditor(
                preset: activePreset,
                controller: controller,
              ),
            ),
          ],
        ),
        SizedBox(height: theme.spacing.xl),
        GallerySection(
          title: gText(
            context,
            en: 'Density, Locale & Optical Capability',
            zh: '密度、语言与光学材质能力',
          ),
          children: [
            GalleryCard.example(
              example: GalleryExample.preferences,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  YumeiroSettingRow(
                    title: gText(context, en: 'Layout Density', zh: '界面密度'),
                    subtitle: gText(
                      context,
                      en: 'Scales spacing, control heights, and list compactness.',
                      zh: '统一缩放控件高度、间距与列表紧凑程度。',
                    ),
                    editor: GalleryComponent(
                      'YumeiroSegmentedControl',
                      child: YumeiroSegmentedControl<YumeiroDensity>(
                        value: controller.density,
                        options: [
                          YumeiroSegmentOption(
                            value: YumeiroDensity.compact,
                            label: gText(context, en: 'Compact', zh: '紧凑'),
                          ),
                          YumeiroSegmentOption(
                            value: YumeiroDensity.standard,
                            label: gText(context, en: 'Standard', zh: '标准'),
                          ),
                          YumeiroSegmentOption(
                            value: YumeiroDensity.comfortable,
                            label: gText(context, en: 'Comfortable', zh: '宽松'),
                          ),
                        ],
                        onChanged: controller.setDensity,
                      ),
                    ),
                  ),
                  const YumeiroDivider(height: 24, touchHeight: 1),
                  YumeiroSettingRow(
                    title: gText(context, en: 'Localization', zh: '语言切换'),
                    editor: GalleryComponent(
                      'YumeiroSegmentedControl',
                      child: YumeiroSegmentedControl<String>(
                        value: controller.locale.languageCode,
                        options: const [
                          YumeiroSegmentOption(value: 'en', label: 'English'),
                          YumeiroSegmentOption(value: 'zh', label: '简体中文'),
                        ],
                        onChanged: (code) => controller.setLocale(Locale(code)),
                      ),
                    ),
                  ),
                  const YumeiroDivider(height: 24, touchHeight: 1),
                  YumeiroSettingRow(
                    title: gText(context, en: 'Advanced Motion', zh: '高级动效'),
                    subtitle: gText(
                      context,
                      en: 'Enables component animations in the gallery.',
                      zh: '启用画廊中的组件过渡动效。',
                    ),
                    trailing: GalleryComponent(
                      'YumeiroSwitch',
                      child: YumeiroSwitch(
                        value: controller.advancedMotionEnabled,
                        onChanged: controller.setAdvancedMotionEnabled,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (controller.isOpticalGlassPreset)
              GalleryCard(
                title: gText(
                  context,
                  en: controller.isLiquidGlassPreset
                      ? 'Liquid Glass Fallback Simulation'
                      : 'Frosted Glass Fallback Simulation',
                  zh: controller.isLiquidGlassPreset ? '液态玻璃降级模拟' : '厚磨砂玻璃降级模拟',
                ),
                description: gText(
                  context,
                  en: 'Compare optical edge refraction with Gaussian blur fallback. Unsupported runtimes use blur automatically. Frosted Acrylic uses blur at either capability tier.',
                  zh: '对比边缘光学折射与高斯模糊降级；不支持着色器的环境会自动降级。磨砂亚克力在两档能力下均使用高斯模糊。',
                ),
                trailing: YumeiroBadge(
                  label:
                      effectiveCapability ==
                          YumeiroMaterialCapability.fullOptical
                      ? gText(context, en: 'Optical Shader', zh: '光学折射')
                      : gText(context, en: 'Blur Fallback', zh: '模糊降级'),
                  statusRole:
                      effectiveCapability ==
                          YumeiroMaterialCapability.fullOptical
                      ? YumeiroStatusRole.success
                      : YumeiroStatusRole.warning,
                ),
                child: GalleryComponent(
                  'YumeiroSegmentedControl',
                  child: YumeiroSegmentedControl<YumeiroMaterialCapability>(
                    value: controller.capability,
                    options: [
                      YumeiroSegmentOption(
                        value: YumeiroMaterialCapability.fullOptical,
                        label: gText(context, en: 'Optical Shader', zh: '光学折射'),
                      ),
                      YumeiroSegmentOption(
                        value: YumeiroMaterialCapability.blurOnly,
                        label: gText(context, en: 'Blur Fallback', zh: '模糊降级'),
                      ),
                    ],
                    onChanged: controller.setCapability,
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: theme.spacing.xl),
        GallerySection(
          title: gText(
            context,
            en: 'One Page, Three Materials',
            zh: '同一页面，三种材质',
          ),
          subtitle: gText(
            context,
            en: 'These materials stay the same when you switch themes.',
            zh: '切换主题后，此示例中的材质保持不变。',
          ),
          children: const [GalleryMaterialsDemo()],
        ),
        SizedBox(height: theme.spacing.xl),
        GallerySection(
          title: gText(
            context,
            en: 'Color Palette & Custom Effect Passes',
            zh: '色彩令牌与自定义视觉通道',
          ),
          children: [
            const GalleryCard.example(
              example: GalleryExample.themeTokens,
              child: GalleryTokenPaletteStrip(),
            ),
            GalleryComponent(
              'YumeiroCard.panel',
              child: YumeiroCard.panel(
                role: gallerySampleSurfaceRole,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: theme.spacing.sm,
                  children: [
                    Text(
                      gText(context, en: 'Example A', zh: '示例 A'),
                      style: theme.typography.title.copyWith(color: theme.text),
                    ),
                    Text(
                      gText(
                        context,
                        en: 'The surface uses gallerySampleSurfaceRole with GalleryPrismPass.',
                        zh: '此表面使用 gallerySampleSurfaceRole，并通过 GalleryPrismPass 绘制光效。',
                      ),
                      style: theme.typography.supporting.copyWith(
                        color: theme.muted,
                      ),
                    ),
                    GalleryComponent(
                      'YumeiroBadge',
                      child: YumeiroBadge(
                        label: gSample(context, 'State A'),
                        statusRole: gallerySampleStatusRole,
                        icon: Icons.auto_awesome_rounded,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _GalleryAppearancePicker extends StatelessWidget {
  const _GalleryAppearancePicker({required this.controller});

  final GalleryController controller;

  @override
  Widget build(BuildContext context) {
    final theme = YumeiroTheme.of(context);
    final canChange = controller.canSelectVariant;
    final dark = controller.effectiveVariant == YumeiroThemeVariant.dark;
    final label = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          gText(context, en: 'Appearance mode', zh: '外观模式'),
          style: theme.typography.title,
        ),
        const SizedBox(height: 4),
        Text(
          canChange
              ? gText(
                  context,
                  en: 'Keep this preference when choosing another style.',
                  zh: '切换主题风格时保留此偏好。',
                )
              : (dark
                    ? gText(context, en: 'Fixed dark', zh: '固定深色')
                    : gText(context, en: 'Fixed light', zh: '固定浅色')),
          style: theme.typography.supporting.copyWith(color: theme.muted),
        ),
      ],
    );
    final picker = GalleryComponent(
      'YumeiroSegmentedControl',
      child: YumeiroSegmentedControl<YumeiroThemeVariant>(
        key: const ValueKey('theme-appearance-mode'),
        value: controller.effectiveVariant,
        expand: true,
        options: [
          YumeiroSegmentOption(
            value: YumeiroThemeVariant.light,
            label: gText(context, en: 'Light', zh: '浅色'),
            icon: theme.icons.themeLight,
          ),
          YumeiroSegmentOption(
            value: YumeiroThemeVariant.dark,
            label: gText(context, en: 'Dark', zh: '深色'),
            icon: theme.icons.themeDark,
          ),
        ],
        onChanged: canChange ? controller.setPreferredVariant : null,
      ),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 480) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              label,
              SizedBox(height: theme.spacing.md),
              picker,
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: label),
            SizedBox(width: theme.spacing.lg),
            SizedBox(width: 220, child: picker),
          ],
        );
      },
    );
  }
}
