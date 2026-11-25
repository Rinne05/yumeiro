import 'package:material_ui/material_ui.dart';
import 'package:yumeiro/yumeiro.dart';

import '../state/gallery_controller.dart';
import 'gallery_examples.dart';

export 'gallery_examples.dart' show GalleryExample, GalleryExampleScope;

/// Bilingual copy helper selecting [zh] when active locale is Chinese, else [en].
String gText(BuildContext context, {required String en, required String zh}) =>
    Localizations.localeOf(context).languageCode == 'zh' ? zh : en;

/// Localizes neutral fixture labels without coupling values to the UI language.
String gSample(BuildContext context, String value) {
  if (Localizations.localeOf(context).languageCode != 'zh') return value;
  const prefixes = {
    'Example ': '示例 ',
    'Description ': '说明 ',
    'Sample item ': '示例项目 ',
    'Category ': '分类 ',
    'Group ': '分组 ',
    'State ': '状态 ',
    'Tag ': '标签 ',
    'Option ': '选项 ',
    'Metric ': '指标 ',
    'User ': '用户 ',
  };
  for (final entry in prefixes.entries) {
    if (value.startsWith(entry.key)) {
      return value.replaceFirst(entry.key, entry.value);
    }
  }
  return value;
}

/// Consistent section wrapper with [YumeiroSectionHeader] and responsive spacing.
class GallerySection extends StatelessWidget {
  const GallerySection({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    required this.children,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = YumeiroTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        YumeiroSectionHeader(
          title: title,
          subtitle: subtitle,
          trailing: trailing,
        ),
        SizedBox(height: theme.spacing.md),
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) SizedBox(height: theme.spacing.md),
          children[i],
        ],
      ],
    );
  }
}

/// Pairs an API identifier with the sample that demonstrates it.
class GalleryComponent extends StatelessWidget {
  const GalleryComponent(this.api, {super.key, required this.child});

  const GalleryComponent.sample(this.api, this.child, {super.key});

  final String api;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = YumeiroTheme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: theme.spacing.xs,
      children: [
        Text(api, style: theme.typography.caption.copyWith(color: theme.muted)),
        child,
      ],
    );
  }
}

/// Framed group of related samples.
class GalleryCard extends StatelessWidget {
  const GalleryCard({
    super.key,
    required String this.title,
    this.description,
    this.trailing,
    required this.child,
  }) : example = null;

  const GalleryCard.example({
    super.key,
    required GalleryExample this.example,
    this.description,
    this.trailing,
    required this.child,
  }) : title = null;

  final GalleryExample? example;
  final String? title;
  final String? description;
  final Widget? trailing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = YumeiroTheme.of(context);
    final sample = example;
    final title = sample == null
        ? this.title!
        : gText(context, en: sample.en, zh: sample.zh);
    final card = YumeiroCard.panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.typography.title.copyWith(color: theme.text),
                    ),
                    if (description != null && description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        description!,
                        style: theme.typography.supporting.copyWith(
                          color: theme.muted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[
                SizedBox(width: theme.spacing.sm),
                trailing!,
              ],
            ],
          ),
          SizedBox(height: theme.spacing.md),
          const YumeiroDivider(),
          SizedBox(height: theme.spacing.md),
          child,
        ],
      ),
    );
    return sample == null
        ? card
        : GalleryExampleScope.anchor(context, sample, card);
  }
}

/// One theme-family choice, previewed using the preferred available variant.
class GalleryPresetCard extends StatelessWidget {
  const GalleryPresetCard({
    super.key,
    required this.family,
    required this.preset,
    required this.selected,
    required this.onTap,
    this.width,
  });

  final YumeiroThemeFamily family;
  final YumeiroThemePreset preset;
  final bool selected;
  final VoidCallback onTap;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final theme = YumeiroTheme.of(context);
    final metrics = YumeiroModalityScope.metricsOf(context);
    final l10n = YumeiroLocalizations.of(context);
    final colors = preset.colors;
    final familyLabel = family.resolveLabel(l10n);
    final fixed = family.variants.length == 1;
    final dark = preset.brightness == Brightness.dark;
    final subtitle = fixed
        ? (dark
              ? gText(context, en: 'Fixed dark', zh: '固定深色')
              : gText(context, en: 'Fixed light', zh: '固定浅色'))
        : (dark
              ? gText(context, en: 'Dark preview', zh: '深色预览')
              : gText(context, en: 'Light preview', zh: '浅色预览'));

    return SizedBox(
      width: width ?? 210,
      child: YumeiroCard(
        selected: selected,
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  family.resolveIcon(theme.icons),
                  size: theme.iconSizes.sm,
                  color: selected ? null : theme.muted,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: YumeiroTextStyle(
                    style: theme.typography.control(selected: selected),
                    child: Text(
                      familyLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            YumeiroTextStyle(
              style: theme.typography.caption,
              child: Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: selected ? null : TextStyle(color: theme.subtle),
              ),
            ),
            const SizedBox(height: 10),
            ConstrainedBox(
              constraints: BoxConstraints(minHeight: metrics.chipHeight),
              child: Row(
                children: [
                  _SwatchDot(
                    color: colors.background,
                    border: colors.lineStrong,
                  ),
                  const SizedBox(width: 4),
                  _SwatchDot(color: colors.surface, border: colors.lineStrong),
                  const SizedBox(width: 4),
                  _SwatchDot(color: colors.accent, border: colors.lineStrong),
                  const SizedBox(width: 4),
                  _SwatchDot(
                    color: colors.accentSoft,
                    border: colors.lineStrong,
                  ),
                  const Spacer(),
                  if (selected) ...[
                    const SizedBox(width: 4),
                    Semantics(
                      selected: true,
                      child: Icon(
                        theme.icons.check,
                        semanticLabel: gText(
                          context,
                          en: 'Current theme',
                          zh: '当前主题',
                        ),
                        size: theme.iconSizes.sm,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SwatchDot extends StatelessWidget {
  const _SwatchDot({required this.color, required this.border});

  final Color color;
  final Color border;

  @override
  Widget build(BuildContext context) => Container(
    width: 16,
    height: 16,
    decoration: BoxDecoration(
      color: color,
      shape: BoxShape.circle,
      border: Border.all(color: border),
    ),
  );
}

/// Displays active [YumeiroColorTokens] and [YumeiroThemeExtension.categoricalPalette].
class GalleryTokenPaletteStrip extends StatelessWidget {
  const GalleryTokenPaletteStrip({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = YumeiroTheme.of(context);
    final colors = theme.colors;
    final palette = theme.categoricalPalette;
    final tokens = <(String, Color)>[
      ('background', colors.background),
      ('surface', colors.surface),
      ('elevated', colors.surfaceElevated),
      ('accent', colors.accent),
      ('accentSoft', colors.accentSoft),
      ('success', colors.success),
      ('warning', colors.warning),
      ('danger', colors.danger),
      ('info', colors.info),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: theme.spacing.md,
      children: [
        GalleryComponent(
          'YumeiroColorTokens',
          child: Wrap(
            spacing: theme.spacing.sm,
            runSpacing: theme.spacing.sm,
            children: [
              for (final (name, color) in tokens)
                YumeiroBadge(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _SwatchDot(color: color, border: colors.lineStrong),
                      SizedBox(width: theme.spacing.xs),
                      Flexible(child: Text(name)),
                    ],
                  ),
                ),
            ],
          ),
        ),
        GalleryComponent(
          'YumeiroThemeExtension.categoricalPalette',
          child: Row(
            spacing: theme.spacing.xs,
            children: [
              for (final color in palette)
                Expanded(
                  child: Container(
                    height: 18,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(theme.radii.chip),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Dynamically renders live parameter editors for the active preset's
/// [YumeiroThemePreset.options].
class GalleryPresetOptionsEditor extends StatelessWidget {
  const GalleryPresetOptionsEditor({
    super.key,
    required this.preset,
    required this.controller,
  });

  final YumeiroThemePreset preset;
  final GalleryController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = YumeiroLocalizations.of(context);
    final options = preset.options;
    final capability = YumeiroMaterialCapabilityScope.of(context)
        .resolveForRuntime();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < options.length; i++) ...[
          if (i > 0) const YumeiroDivider(height: 24, touchHeight: 1),
          _buildOptionRow(context, l10n, options[i], capability),
        ],
      ],
    );
  }

  Widget _buildOptionRow(
    BuildContext context,
    YumeiroLocalizations l10n,
    YumeiroThemeOption option,
    YumeiroMaterialCapability capability,
  ) {
    final label = option.resolveLabel(l10n);
    final automaticBorder =
        option.adjustment == YumeiroThemeAdjustment.borderColor ||
        option.adjustment == YumeiroThemeAdjustment.paletteBorderColor;
    final supported = capability.supports(option.minCapability);
    final rimLightDisabled =
        option.adjustment == YumeiroThemeAdjustment.highlight &&
        controller.customizations['glassLighting'] == false;
    final enabled = supported && !rimLightDisabled;
    final String? description;
    if (!supported) {
      description = option.id == yumeiroActionOpacityOption.id
          ? l10n.optionActionOpacityFallbackDescription
          : l10n.optionRequiresOpticalDescription;
    } else if (rimLightDisabled) {
      description = l10n.optionRimLightDisabledDescription;
    } else if (capability == YumeiroMaterialCapability.blurOnly &&
        option.adjustment == YumeiroThemeAdjustment.glassOpacity) {
      description = l10n.optionGlassOpacityFallbackDescription;
    } else {
      description = option.resolveDescription(l10n);
    }

    return switch (option) {
      YumeiroThemeColorOption() => YumeiroSettingRow(
        title: label,
        subtitle: description,
        enabled: enabled,
        trailing: GalleryComponent(
          'YumeiroColorPickerButton',
          child: YumeiroColorPickerButton(
            enabled: enabled,
            value: controller.customizations.containsKey(option.id)
                ? option.resolve(controller.customizations)
                : null,
            defaultColor: option.defaultValue,
            defaultLabel: automaticBorder
                ? l10n.optionPresetBorder
                : gText(context, en: 'Preset Default', zh: '预设默认'),
            showDefaultSwatch: !automaticBorder,
            presets: const [
              YumeiroColorPickerPreset(label: 'Sky', color: Color(0xFF0EA5E9)),
              YumeiroColorPickerPreset(
                label: 'Violet',
                color: Color(0xFF8B5CF6),
              ),
              YumeiroColorPickerPreset(
                label: 'Emerald',
                color: Color(0xFF10B981),
              ),
              YumeiroColorPickerPreset(
                label: 'Amber',
                color: Color(0xFFF59E0B),
              ),
              YumeiroColorPickerPreset(label: 'Rose', color: Color(0xFFF43F5E)),
            ],
            onChanged: (color) {
              if (color == null) {
                controller.clearCustomization(option.id);
                return;
              }
              controller.setCustomization(option.id, color);
            },
          ),
        ),
      ),
      YumeiroThemeNumberOption() => GalleryComponent(
        'YumeiroSliderInput',
        child: YumeiroSliderInput(
          title: label,
          subtitle: description,
          enabled: enabled,
          value: option.resolve(controller.customizations),
          defaultValue: option.defaultValue,
          min: option.min,
          max: option.max,
          step: option.step > 0 ? option.step : null,
          divisions: option.step > 0
              ? ((option.max - option.min) / option.step).round().clamp(1, 200)
              : null,
          decimalPlaces:
              option.decimalPlaces ?? _decimalPlacesForStep(option.step),
          suffixText: option.unit.isEmpty ? null : option.unit,
          onChanged: (value) => controller.setCustomization(option.id, value),
          onReset: () => controller.clearCustomization(option.id),
        ),
      ),
      YumeiroThemeToggleOption() => YumeiroSettingRow(
        title: label,
        subtitle: description,
        enabled: enabled,
        trailing: GalleryComponent(
          'YumeiroSwitch',
          child: YumeiroSwitch(
            value: option.resolve(controller.customizations),
            onChanged: enabled
                ? (value) => controller.setCustomization(option.id, value)
                : null,
          ),
        ),
      ),
      YumeiroThemeChoiceOption() => YumeiroSettingRow(
        title: label,
        subtitle: description,
        enabled: enabled,
        editor: GalleryComponent(
          'YumeiroSegmentedControl',
          child: YumeiroSegmentedControl<String>(
            value: option.resolve(controller.customizations),
            options: [
              for (final entry in option.resolveChoices(l10n).entries)
                YumeiroSegmentOption(value: entry.key, label: entry.value),
            ],
            onChanged: enabled
                ? (value) => controller.setCustomization(option.id, value)
                : null,
          ),
        ),
      ),
    };
  }

  static int _decimalPlacesForStep(double step) {
    if (step <= 0 || step == step.roundToDouble()) return 0;
    final text = step.toString();
    final dot = text.indexOf('.');
    return dot == -1 ? 0 : (text.length - dot - 1).clamp(0, 4);
  }
}

/// Procedural local artwork widget eliminating external network dependencies.
class GalleryPosterArt extends StatelessWidget {
  const GalleryPosterArt({
    super.key,
    required this.startColor,
    required this.endColor,
    required this.icon,
    this.iconSize = 34,
  });

  final Color startColor;
  final Color endColor;
  final IconData icon;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [startColor, endColor],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            right: -18,
            top: -18,
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.14),
              ),
            ),
          ),
          Positioned(
            left: -14,
            bottom: -20,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withValues(alpha: 0.16),
              ),
            ),
          ),
          Center(
            child: Icon(
              icon,
              size: iconSize,
              color: Colors.white.withValues(alpha: 0.92),
            ),
          ),
        ],
      ),
    );
  }
}
