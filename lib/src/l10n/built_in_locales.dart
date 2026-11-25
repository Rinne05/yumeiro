import 'localizations.dart';

/// Default English localization strings for Yumeiro.
class YumeiroLocalizationsEn extends YumeiroLocalizations {
  const YumeiroLocalizationsEn();

  @override
  String get localeName => 'en';

  @override
  String get confirm => 'Confirm';

  @override
  String get cancel => 'Cancel';

  @override
  String get close => 'Close';

  @override
  String get ok => 'OK';

  @override
  String get back => 'Back';

  @override
  String get save => 'Save';

  @override
  String get saving => 'Saving...';

  @override
  String get apply => 'Apply';

  @override
  String get done => 'Done';

  @override
  String get add => 'Add';

  @override
  String get remove => 'Remove';

  @override
  String get reset => 'Reset';

  @override
  String get resetToDefault => 'Reset to default';

  @override
  String get retry => 'Retry';

  @override
  String get clear => 'Clear';

  @override
  String get selectAll => 'Select All';

  @override
  String get selectItem => 'Select Item';

  @override
  String get all => 'All';

  @override
  String get none => 'None';

  @override
  String get filter => 'Filter';

  @override
  String get clearFilters => 'Clear Filters';

  @override
  String get sort => 'Sort';

  @override
  String get actions => 'Actions';

  @override
  String get moreActions => 'More actions';

  @override
  String get copy => 'Copy';

  @override
  String get copied => 'Copied';

  @override
  String get showPassword => 'Show';

  @override
  String get hidePassword => 'Hide';

  @override
  String get requiredField => 'Required';

  @override
  String get defaultOption => 'Default';

  @override
  String get alreadyDefault => 'Already at default';

  @override
  String get showOptions => 'Show options';

  @override
  String get hideOptions => 'Hide options';

  @override
  String get hexColor => 'Hex Color';

  @override
  String get colorPickerTitle => 'Choose Color';

  @override
  String get hueSlider => 'Hue';

  @override
  String get hueSliderHint => 'Drag horizontally to adjust hue';

  @override
  String get hueSliderArrowHint => 'Left/right arrow keys adjust hue';

  @override
  String get saturationValuePanel => 'Saturation and brightness panel';

  @override
  String get saturationValueHint =>
      'Left/right adjusts saturation, up/down adjusts brightness';

  @override
  String get increaseBrightness => 'Increase brightness';

  @override
  String get decreaseBrightness => 'Decrease brightness';

  @override
  String get rating => 'Rating';

  @override
  String get unrated => 'Unrated';

  @override
  String get search => 'Search';

  @override
  String get searchHint => 'Search...';

  @override
  String get searchOrSelectHint => 'Search or select';

  @override
  String get searchFilterHint => 'Type to filter; use arrow keys to browse';

  @override
  String get tokenInputHint => 'Type and press Enter to add';

  @override
  String get selectPlaceholder => 'Select an option';

  @override
  String get selectOptionsHint => 'Press Enter or Space to expand options';

  @override
  String get noResults => 'No matching items';

  @override
  String get emptyTable => 'No data';

  @override
  String get loading => 'Loading...';

  @override
  String get emptyStateTitle => 'Nothing here yet';

  @override
  String get errorTitle => 'Unable to load';

  @override
  String get actionFailed => 'Action failed';

  @override
  String selectedCount(int count) => '$count selected';

  @override
  String confirmWithCount(int count) => 'Confirm ($count)';

  @override
  String filterWithCount(int count) => 'Filter ($count)';

  @override
  String removeItem(String label) => 'Remove $label';

  @override
  String ratingOutOfFive(String value) => '$value / 5';

  @override
  String searchHotkeyTooltip(String placeholder, String shortcut) =>
      '$placeholder ($shortcut)';

  @override
  String dropdownSelection(String label) => 'Dropdown: $label';

  @override
  String saturationBrightnessValue(
    int saturationPercent,
    int brightnessPercent,
  ) => 'Saturation $saturationPercent%, brightness $brightnessPercent%';

  @override
  String errorMessage(String error) => 'Error: $error';

  @override
  String get modalityPointer => 'Pointer';

  @override
  String get modalityTouch => 'Touch';

  @override
  String get densityCompact => 'Compact';

  @override
  String get densityStandard => 'Standard';

  @override
  String get densityComfortable => 'Comfortable';

  @override
  String get capabilityFullOptical => 'Optical Shader';

  @override
  String get capabilityBlurOnly => 'Blur Fallback';

  @override
  String get familyClassic => 'Classic';

  @override
  String get familyGeek => 'Geek';

  @override
  String get familySketch => 'Sketch';

  @override
  String get familyNeumorphic => 'Neumorphic';

  @override
  String get familyMinimal => 'Minimal';

  @override
  String get familyLiquidGlass => 'Liquid Glass';

  @override
  String get presetClassicDark => 'Classic · Dark';

  @override
  String get presetClassicLight => 'Classic · Light';

  @override
  String get presetGeek => 'Geek';

  @override
  String get presetSketch => 'Sketch';

  @override
  String get presetMinimalDark => 'Minimal · Dark';

  @override
  String get presetMinimalLight => 'Minimal · Light';

  @override
  String get presetLiquidGlassDark => 'Liquid Glass · Dark';

  @override
  String get presetLiquidGlassLight => 'Liquid Glass · Light';

  @override
  String get optionAccentColor => 'Accent Color';

  @override
  String get optionBorderColor => 'Custom Border Color';

  @override
  String get optionBackgroundTone => 'Background Tone';

  @override
  String get optionBackgroundToneDescription =>
      'Adjusts base surface hue and saturation while preserving luminance contrast.';

  @override
  String get optionRoundness => 'Corner Roundness';

  @override
  String get optionSelectionStrength => 'Selection Strength';

  @override
  String get optionSurfaceOpacity => 'Container Fill Opacity Scale';

  @override
  String get optionBorderOpacity => 'Border Opacity';

  @override
  String get optionOutlineWidth => 'Outline Width';

  @override
  String get optionShadowStrength => 'Shadow Strength';

  @override
  String get optionShadowDistance => 'Shadow Distance';

  @override
  String get optionShadowSoftness => 'Shadow Softness';

  @override
  String get optionPressScale => 'Press Feedback Scale';

  @override
  String get optionInnerHighlight => 'Inner Highlight';

  @override
  String get optionRaisedHighlight => 'Edge Highlight';

  @override
  String get optionShadowColor => 'Shadow Color';

  @override
  String get optionHardShadowColor => 'Hard Shadow Color';

  @override
  String get optionGlassRefraction => 'Refraction Strength';

  @override
  String get optionGlassOpacity => 'Glass Tint Opacity';

  @override
  String get optionTagOpacity => 'Tag Opacity';

  @override
  String get optionHighlightScale => 'Specular Highlight';

  @override
  String get optionGlassLighting => 'Directional Rim Light';

  @override
  String get optionGlassLightingDescription =>
      'Toggle directional edge highlights while keeping refraction and blur.';

  @override
  String get optionGlassEdgeThickness => 'Glass Edge Thickness';

  @override
  String get optionActionOpacity => 'Action Fill Opacity';

  @override
  String get play => 'Play';

  @override
  String ratingValue(String value) => 'Rating $value';

  @override
  String get motionPosterTilt => 'Poster 3D Tilt';

  @override
  String get motionPosterScale => 'Poster Hover Scale';

  @override
  String get motionPosterLighting => 'Poster Dynamic Lighting';

  @override
  String get motionDetailParallax => 'Detail Backdrop Parallax';

  @override
  String get motionChartHover => 'Chart Hover Morph';

  @override
  String get motionNavigationTransition => 'Navigation Highlight Transition';

  @override
  String get motionControlPressScale => 'Control Press Scale';
}

/// Built-in Simplified Chinese localization strings for Yumeiro.
class YumeiroLocalizationsZh extends YumeiroLocalizations {
  const YumeiroLocalizationsZh();

  @override
  String get previousPage => '上一页';

  @override
  String get nextPage => '下一页';

  @override
  String pageNumber(int page) => '第 $page 页';

  @override
  String pagePosition(int page, int count) => '第 $page 页，共 $count 页';

  @override
  String get jumpToPage => '跳转到指定页';

  @override
  String get pageNumberLabel => '页码';

  @override
  String pageNumberRange(int count) => '请输入 1–$count 的页码。';

  @override
  String get localeName => 'zh';

  @override
  String get confirm => '确认';

  @override
  String get cancel => '取消';

  @override
  String get close => '关闭';

  @override
  String get ok => '确定';

  @override
  String get back => '返回';

  @override
  String get save => '保存';

  @override
  String get saving => '保存中...';

  @override
  String get apply => '应用';

  @override
  String get done => '完成';

  @override
  String get add => '添加';

  @override
  String get remove => '移除';

  @override
  String get reset => '重置';

  @override
  String get resetToDefault => '重置为默认值';

  @override
  String get retry => '重试';

  @override
  String get clear => '清空';

  @override
  String get selectAll => '全选';

  @override
  String get selectItem => '选择项目';

  @override
  String get all => '全部';

  @override
  String get none => '无';

  @override
  String get filter => '筛选';

  @override
  String get clearFilters => '清空筛选';

  @override
  String get sort => '排序';

  @override
  String get actions => '操作';

  @override
  String get moreActions => '更多操作';

  @override
  String get copy => '复制';

  @override
  String get copied => '已复制';

  @override
  String get showPassword => '显示';

  @override
  String get hidePassword => '隐藏';

  @override
  String get requiredField => '必填';

  @override
  String get defaultOption => '默认';

  @override
  String get alreadyDefault => '已是默认值';

  @override
  String get showOptions => '显示选项';

  @override
  String get hideOptions => '收起选项';

  @override
  String get hexColor => '十六进制颜色';

  @override
  String get colorPickerTitle => '选择颜色';

  @override
  String get hueSlider => '色相';

  @override
  String get hueSliderHint => '左右拖动调整色相';

  @override
  String get hueSliderArrowHint => '左右方向键调整色相';

  @override
  String get saturationValuePanel => '饱和度和明度色板';

  @override
  String get saturationValueHint => '左右方向键调整饱和度，上下方向键调整明度';

  @override
  String get increaseBrightness => '提高明度';

  @override
  String get decreaseBrightness => '降低明度';

  @override
  String get rating => '评分';

  @override
  String get unrated => '未评分';

  @override
  String get search => '搜索';

  @override
  String get searchHint => '搜索...';

  @override
  String get searchOrSelectHint => '搜索或选择';

  @override
  String get searchFilterHint => '输入以筛选；使用上下方向键浏览选项';

  @override
  String get tokenInputHint => '输入后按 Enter 添加';

  @override
  String get selectPlaceholder => '请选择';

  @override
  String get selectOptionsHint => '按 Enter 或空格键展开选项';

  @override
  String get noResults => '暂无匹配项';

  @override
  String get emptyTable => '暂无数据';

  @override
  String get loading => '加载中...';

  @override
  String get emptyStateTitle => '暂无内容';

  @override
  String get errorTitle => '暂时无法加载';

  @override
  String get actionFailed => '操作失败';

  @override
  String selectedCount(int count) => '已选 $count 项';

  @override
  String confirmWithCount(int count) => '确认（$count）';

  @override
  String filterWithCount(int count) => '筛选（$count）';

  @override
  String removeItem(String label) => '移除 $label';

  @override
  String ratingOutOfFive(String value) => '$value / 5';

  @override
  String searchHotkeyTooltip(String placeholder, String shortcut) =>
      '$placeholder ($shortcut)';

  @override
  String dropdownSelection(String label) => '下拉选择：$label';

  @override
  String saturationBrightnessValue(
    int saturationPercent,
    int brightnessPercent,
  ) => '饱和度 $saturationPercent%，明度 $brightnessPercent%';

  @override
  String errorMessage(String error) => '错误：$error';

  @override
  String get modalityPointer => '桌面指针';

  @override
  String get modalityTouch => '触控交互';

  @override
  String get densityCompact => '紧凑';

  @override
  String get densityStandard => '标准';

  @override
  String get densityComfortable => '宽松';

  @override
  String get capabilityFullOptical => '光学折射';

  @override
  String get capabilityBlurOnly => '模糊降级';

  @override
  String get familyClassic => '经典';

  @override
  String get familyGeek => '极客';

  @override
  String get familySketch => '素描';

  @override
  String get familyNeumorphic => '新拟态';

  @override
  String get familyMinimal => '极简';

  @override
  String get familyLiquidGlass => '液态玻璃';

  @override
  String get familyCeramic => '釉面陶瓷';

  @override
  String get familyBrushedMetal => '拉丝金属';

  @override
  String get familyNeoBrutalist => '新粗野主义';

  @override
  String get familyPixel => '复古像素';

  @override
  String get familyAcrylic => '磨砂亚克力';

  @override
  String get familySilicone => '软硅胶';

  @override
  String get familyFrostedGlass => '厚磨砂玻璃';

  @override
  String get presetClassicDark => '经典 · 深色';

  @override
  String get presetClassicLight => '经典 · 浅色';

  @override
  String get presetGeek => '极客';

  @override
  String get presetSketch => '素描';

  @override
  String get presetMinimalDark => '极简 · 深色';

  @override
  String get presetMinimalLight => '极简 · 浅色';

  @override
  String get presetLiquidGlassDark => '液态玻璃 · 深色';

  @override
  String get presetLiquidGlassLight => '液态玻璃 · 浅色';

  @override
  String get presetNeumorphicLight => '$familyNeumorphic · 浅色';

  @override
  String get presetNeumorphicDark => '$familyNeumorphic · 深色';

  @override
  String get presetCeramicLight => '$familyCeramic · 浅色';

  @override
  String get presetCeramicDark => '$familyCeramic · 深色';

  @override
  String get presetBrushedMetalLight => '$familyBrushedMetal · 浅色';

  @override
  String get presetBrushedMetalDark => '$familyBrushedMetal · 深色';

  @override
  String get presetNeoBrutalistLight => '$familyNeoBrutalist · 浅色';

  @override
  String get presetNeoBrutalistDark => '$familyNeoBrutalist · 深色';

  @override
  String get presetPixelLight => '$familyPixel · 浅色';

  @override
  String get presetPixelDark => '$familyPixel · 深色';

  @override
  String get presetAcrylicLight => '$familyAcrylic · 浅色';

  @override
  String get presetAcrylicDark => '$familyAcrylic · 深色';

  @override
  String get presetSiliconeLight => '$familySilicone · 浅色';

  @override
  String get presetSiliconeDark => '$familySilicone · 深色';

  @override
  String get presetFrostedGlassLight => '$familyFrostedGlass · 浅色';

  @override
  String get presetFrostedGlassDark => '$familyFrostedGlass · 深色';

  @override
  String get optionAccentColor => '主题强调色';

  @override
  String get optionBorderColor => '自定义描边色';

  @override
  String get optionBorderColorDescription => '应用纯色覆盖。预设描边会根据材质和交互状态变化。';

  @override
  String get optionPresetBorder => '预设描边';

  @override
  String get optionBackgroundTone => '背景色调';

  @override
  String get optionBackgroundToneDescription => '调整底板色相与饱和度，同时保留明暗层次。';

  @override
  String get optionPanelColor => '面板底色';

  @override
  String get optionPanelColorDescription => '独立设置面板的填充颜色。';

  @override
  String get optionSurfaceColor => '内容表面底色';

  @override
  String get optionSurfaceColorDescription => '设置卡片、表格和弹窗共用的基础色。';

  @override
  String get optionSecondarySurfaceColor => '次表面底色';

  @override
  String get optionSecondarySurfaceColorDescription => '设置输入框和内嵌表面的基础色。';

  @override
  String get optionSurfaceHoverColor => '悬停底色';

  @override
  String get optionSurfaceHoverColorDescription => '设置轻量控件悬停和按压时的基础色。';

  @override
  String get optionRoundness => '圆角比例';

  @override
  String get optionSelectionStrength => '选中态强度';

  @override
  String get optionSurfaceOpacity => '容器底色不透明度倍率';

  @override
  String get optionSurfaceOpacityDescription => '按比例调整导航、面板、卡片和浮层的预设底色不透明度。';

  @override
  String get optionBorderOpacity => '描边不透明度';

  @override
  String get optionOutlineWidth => '描边粗细';

  @override
  String get optionOutlineWidthDescription => '按比例调整装饰描边，复选框可保留用于辨识的边界。';

  @override
  String get optionShadowStrength => '阴影强度';

  @override
  String get optionShadowDistance => '阴影距离';

  @override
  String get optionShadowSoftness => '阴影柔和度';

  @override
  String get optionPressScale => '按压缩放反馈';

  @override
  String get optionInnerHighlight => '内高光强度';

  @override
  String get optionRaisedHighlight => '边缘高光';

  @override
  String get optionShadowColor => '阴影颜色';

  @override
  String get optionHardShadowColor => '硬阴影颜色';

  @override
  String get optionGlassRefraction => '光学折射强度';

  @override
  String get optionOpticalSizeLimitDescription => '有效范围取决于表面尺寸，小控件可能会提前达到上限。';

  @override
  String get optionRequiresOpticalDescription => '光学渲染可用时可调整。';

  @override
  String get optionGlassOpacity => '玻璃底色浓度';

  @override
  String get optionGlassOpacityDescription => '调节表面染色浓度，模糊与折射保持原设置。';

  @override
  String get optionGlassOpacityFallbackDescription =>
      '模糊降级会额外绘制 76% 不透明度的基础染色。';

  @override
  String get optionTagOpacity => '胶囊底色浓度';

  @override
  String get optionHighlightScale => '高光强度缩放';

  @override
  String get optionGlassLighting => '玻璃光源效果';

  @override
  String get optionGlassLightingDescription => '切换固定方向边缘高光，同时保留折射与模糊。';

  @override
  String get optionRimLightDisabledDescription => '开启玻璃光源效果后，可调整高光强度。';

  @override
  String get optionGlassEdgeThickness => '玻璃边缘厚度';

  @override
  String get optionActionOpacity => '主操作填充浓度';

  @override
  String get optionActionOpacityFallbackDescription =>
      '模糊降级时，主操作和危险按钮使用实色底板以保持可读性。';

  @override
  String get optionTextureStrength => '纹理强度';

  @override
  String get optionBackdropBlur => '背景模糊';

  @override
  String get optionMaterialOpacity => '材质染色强度';

  @override
  String get optionMaterialOpacityDescription => '按比例调整预设染色，模糊与折射由各自的选项控制。';

  @override
  String get play => '播放';

  @override
  String ratingValue(String value) => '评分 $value';

  @override
  String get motionPosterTilt => '海报透视倾斜';

  @override
  String get motionPosterScale => '海报悬停缩放';

  @override
  String get motionPosterLighting => '海报动态明暗';

  @override
  String get motionDetailParallax => '详情背景视差';

  @override
  String get motionChartHover => '图表悬停形变';

  @override
  String get motionNavigationTransition => '导航强调背景过渡';

  @override
  String get motionControlPressScale => '控件按压缩放';
}
