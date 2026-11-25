import 'package:flutter/foundation.dart' show mapEquals;
import 'package:material_ui/material_ui.dart';
import 'package:yumeiro/yumeiro.dart';

import '../theme/gallery_registry.dart';

/// Sample row entity for [YumeiroDataTable] and [YumeiroDataRow].
@immutable
class GalleryRowItem {
  const GalleryRowItem({
    required this.id,
    required this.name,
    required this.category,
    required this.status,
    required this.progress,
    required this.rating,
  });

  final String id;
  final String name;
  final String category;
  final String status;
  final double progress;
  final double rating;
}

/// Sample artwork entity for [YumeiroPosterGrid], [YumeiroMediaCard], and
/// [YumeiroListTile.media].
@immutable
class GalleryMediaItem {
  const GalleryMediaItem({
    required this.id,
    required this.title,
    required this.meta,
    required this.rating,
    required this.progress,
    required this.badge,
    required this.startColor,
    required this.endColor,
    required this.icon,
  });

  final String id;
  final String title;
  final String meta;
  final double rating;
  final double progress;
  final String badge;
  final Color startColor;
  final Color endColor;
  final IconData icon;
}

/// Centralized reactive state controller driving all gallery showcase pages
/// and synchronizing design tokens from desktop to mobile preview.
class GalleryController extends ChangeNotifier {
  GalleryController({YumeiroThemeRegistry? registry})
    : registry = registry ?? createGalleryRegistry(),
      _ownsRegistry = registry == null;

  final YumeiroThemeRegistry registry;
  final bool _ownsRegistry;
  int _appearanceRevision = 0;

  /// Changes only when an appearance setting changes, independently of samples.
  int get appearanceRevision => _appearanceRevision;

  void _notifyAppearanceChanged() {
    _appearanceRevision++;
    notifyListeners();
  }

  // Global theme & pipeline state
  String _presetId = YumeiroThemePresetIds.classicDark;
  String get presetId => _presetId;
  YumeiroThemeVariant _preferredVariant = YumeiroThemeVariant.dark;
  YumeiroMaterialCapability capability = YumeiroMaterialCapability.fullOptical;
  YumeiroDensity density = YumeiroDensity.standard;
  Locale locale = const Locale('zh');
  Map<String, Object> _customizations = const <String, Object>{};
  Map<String, Object> get customizations => _customizations;
  bool advancedMotionEnabled = true;
  int navIndex = 0;

  // Interactive controls showcase state
  bool switchValue = true;
  bool checkboxValue = true;
  bool? tristateValue;
  bool checkboxRowValue = true;
  double sliderValue = 0.64;
  RangeValues rangeSliderValues = const RangeValues(.25, .75);
  double sliderInputValue = 48;
  int segmentValue = 0;
  String verticalSegmentValue = 'balanced';
  String selectValue = 'balanced';
  Set<String> multiSelectTags = const {'Tag A', 'Tag B'};
  String dropdownValue = 'optical';
  String? searchableValue = 'a';
  String cascadeValue = 'render/optical';
  String settingSelectValue = 'auto';
  Color? pickedColor = const Color(0xFF19857B);
  List<String> tokens = ['Tag A', 'Tag B', 'Tag C'];
  double? rating = 4.5;

  final TextEditingController textController = TextEditingController(
    text: 'Sample 01',
  );
  final TextEditingController formFieldController = TextEditingController(
    text: 'sample-01',
  );
  final TextEditingController searchController = TextEditingController();

  // Display / Layout / Overlays showcase state
  bool displayChipSelected = false;
  bool displayDenseChipSelected = false;
  List<String> removableTags = const ['Tag A', 'Tag B', 'Tag C'];
  final Set<String> selectedTags = {'Tag A', 'Tag B'};
  bool layoutSwitchValue = true;
  bool layoutSelectionValue = true;
  final Set<String> activeCategories = {'Category A', 'Category B'};
  Set<GalleryRowItem> selectedRows = const {};
  final Set<GalleryRowItem> _removedTableRows = {};

  Iterable<GalleryRowItem> get visibleTableItems =>
      tableItems.where((item) => !_removedTableRows.contains(item));
  bool get hasRemovedTableRows => _removedTableRows.isNotEmpty;
  int topNavTab = 0;
  String searchScopeQuery = '';
  String toolbarSearchQuery = '';
  String toolbarSort = 'Name';
  bool previewCardSelected = false;
  String lastOverlayEvent = '';
  String lastOverlayEventZh = '';
  String overlaySampleName = 'Example A';
  bool overlaySampleEnabled = true;
  bool overlaySamplePresent = true;
  String overlayCascadeValue = 'render/optical';

  /// Resolves against the actual registry before using the built-in fallback.
  /// Custom registries need not contain the initial Classic Dark preset.
  YumeiroThemePreset get activePreset => registry.presetById(presetId);

  YumeiroThemeFamily? get activeFamily =>
      registry.familyForPreset(activePreset);

  /// The user's mode preference survives visiting a fixed-variant family.
  YumeiroThemeVariant get preferredVariant => _preferredVariant;

  /// The active family's available mode, which may differ from the preference.
  YumeiroThemeVariant get effectiveVariant =>
      activeFamily?.variantOf(activePreset) ??
      (activePreset.brightness == Brightness.dark
          ? YumeiroThemeVariant.dark
          : YumeiroThemeVariant.light);

  bool get canSelectVariant => (activeFamily?.variants.length ?? 0) > 1;

  bool get isLiquidGlassPreset =>
      activePreset.id == YumeiroThemePresetIds.liquidGlassDark ||
      activePreset.id == YumeiroThemePresetIds.liquidGlassLight;

  bool get isOpticalGlassPreset =>
      isLiquidGlassPreset ||
      activePreset.id == YumeiroThemePresetIds.frostedGlassLight ||
      activePreset.id == YumeiroThemePresetIds.frostedGlassDark;

  static const tableItems = <GalleryRowItem>[
    GalleryRowItem(
      id: '1',
      name: 'Sample item 01',
      category: 'Category A',
      status: 'State A',
      progress: 0.92,
      rating: 4.9,
    ),
    GalleryRowItem(
      id: '2',
      name: 'Sample item 02',
      category: 'Category B',
      status: 'State B',
      progress: 0.76,
      rating: 4.5,
    ),
    GalleryRowItem(
      id: '3',
      name: 'Sample item 03',
      category: 'Category C',
      status: 'State C',
      progress: 0.48,
      rating: 4.2,
    ),
  ];

  static const mediaItems = <GalleryMediaItem>[
    GalleryMediaItem(
      id: 'a1',
      title: 'Sample item 01',
      meta: 'Group A',
      rating: 4.9,
      progress: 0.82,
      badge: 'A',
      startColor: Color(0xFF1D4ED8),
      endColor: Color(0xFF06B6D4),
      icon: Icons.blur_on_rounded,
    ),
    GalleryMediaItem(
      id: 'a2',
      title: 'Sample item 02',
      meta: 'Group B',
      rating: 4.6,
      progress: 0.55,
      badge: 'B',
      startColor: Color(0xFFB45309),
      endColor: Color(0xFFF59E0B),
      icon: Icons.draw_rounded,
    ),
    GalleryMediaItem(
      id: 'a3',
      title: 'Sample item 03',
      meta: 'Group C',
      rating: 4.4,
      progress: 0.34,
      badge: 'C',
      startColor: Color(0xFF6D28D9),
      endColor: Color(0xFFEC4899),
      icon: Icons.layers_rounded,
    ),
    GalleryMediaItem(
      id: 'a4',
      title: 'Sample item 04',
      meta: 'Group D',
      rating: 4.8,
      progress: 1.0,
      badge: 'D',
      startColor: Color(0xFF047857),
      endColor: Color(0xFF10B981),
      icon: Icons.terminal_rounded,
    ),
  ];

  /// Synchronizes global appearance, preset customizations, and motion tokens
  /// from another controller (e.g. desktop -> isolated mobile preview pane).
  void copyDesignSettingsFrom(GalleryController source) {
    if (_presetId == source._presetId &&
        _preferredVariant == source._preferredVariant &&
        capability == source.capability &&
        density == source.density &&
        locale == source.locale &&
        advancedMotionEnabled == source.advancedMotionEnabled &&
        mapEquals(_customizations, source._customizations)) {
      return;
    }
    _presetId = source._presetId;
    _preferredVariant = source._preferredVariant;
    capability = source.capability;
    density = source.density;
    locale = source.locale;
    advancedMotionEnabled = source.advancedMotionEnabled;
    _customizations = source._customizations;
    _notifyAppearanceChanged();
  }

  /// Selects a material/style family using the stored light/dark preference.
  /// Switching families clears customizations; re-resolving the current family
  /// preserves them, matching [setPreferredVariant].
  void setThemeFamily(String familyId) {
    final family = registry.familyById(familyId);
    if (family == null) return;
    final next = family.resolve(_preferredVariant);
    final changedFamily = activeFamily?.id != family.id;
    if (!changedFamily && presetId == next.id) return;
    _presetId = next.id;
    if (changedFamily) {
      _customizations = const <String, Object>{};
    }
    _notifyAppearanceChanged();
  }

  /// Updates the preference even for fixed-variant families, so the next
  /// family with both modes can honor it. Existing family customizations stay.
  void setPreferredVariant(YumeiroThemeVariant value) {
    final nextId = activeFamily?.resolve(value).id ?? presetId;
    if (_preferredVariant == value && presetId == nextId) return;
    _preferredVariant = value;
    _presetId = nextId;
    _notifyAppearanceChanged();
  }

  void setCapability(YumeiroMaterialCapability value) {
    if (capability == value) return;
    capability = value;
    _notifyAppearanceChanged();
  }

  void setDensity(YumeiroDensity value) {
    if (density == value) return;
    density = value;
    _notifyAppearanceChanged();
  }

  void setLocale(Locale value) {
    if (locale == value) return;
    locale = value;
    _notifyAppearanceChanged();
  }

  void setCustomization(String id, Object value) {
    if (_customizations[id] == value) return;
    _customizations = Map.unmodifiable({..._customizations, id: value});
    _notifyAppearanceChanged();
  }

  void clearCustomization(String id) {
    if (!_customizations.containsKey(id)) return;
    final next = Map<String, Object>.of(_customizations)..remove(id);
    _customizations = Map.unmodifiable(next);
    _notifyAppearanceChanged();
  }

  void resetCustomizations() {
    if (_customizations.isEmpty) return;
    _customizations = const <String, Object>{};
    _notifyAppearanceChanged();
  }

  void setAdvancedMotionEnabled(bool value) {
    if (advancedMotionEnabled == value) return;
    advancedMotionEnabled = value;
    _notifyAppearanceChanged();
  }

  void setNavIndex(int value) {
    if (navIndex == value) return;
    navIndex = value;
    notifyListeners();
  }

  void setSwitchValue(bool value) {
    switchValue = value;
    notifyListeners();
  }

  void setCheckboxValue(bool? value) {
    checkboxValue = value ?? false;
    notifyListeners();
  }

  void setTristateValue(bool? value) {
    tristateValue = value;
    notifyListeners();
  }

  void setCheckboxRowValue(bool value) {
    checkboxRowValue = value;
    notifyListeners();
  }

  void setSliderValue(double value) {
    sliderValue = value;
    notifyListeners();
  }

  void setRangeSliderValues(RangeValues values) {
    rangeSliderValues = values;
    notifyListeners();
  }

  void setSliderInputValue(double value) {
    sliderInputValue = value;
    notifyListeners();
  }

  void setSegmentValue(int value) {
    segmentValue = value;
    notifyListeners();
  }

  void setVerticalSegmentValue(String value) {
    verticalSegmentValue = value;
    notifyListeners();
  }

  void setSelectValue(String value) {
    selectValue = value;
    notifyListeners();
  }

  void setMultiSelectTags(Set<String> value) {
    multiSelectTags = Set<String>.unmodifiable(value);
    notifyListeners();
  }

  void setDropdownValue(String value) {
    dropdownValue = value;
    notifyListeners();
  }

  void setSearchableValue(String? value) {
    searchableValue = value;
    notifyListeners();
  }

  void setCascadeValue(String value) {
    cascadeValue = value;
    notifyListeners();
  }

  void setSettingSelectValue(String value) {
    settingSelectValue = value;
    notifyListeners();
  }

  void setPickedColor(Color? value) {
    pickedColor = value;
    notifyListeners();
  }

  void setTokens(List<String> value) {
    tokens = List<String>.unmodifiable(value);
    notifyListeners();
  }

  void setRating(double? value) {
    rating = value;
    notifyListeners();
  }

  void toggleTag(String tag) {
    if (!removableTags.contains(tag)) return;
    if (!selectedTags.remove(tag)) {
      selectedTags.add(tag);
    }
    notifyListeners();
  }

  void removeTag(String tag) {
    if (!removableTags.contains(tag)) return;
    removableTags = List<String>.unmodifiable(
      removableTags.where((item) => item != tag),
    );
    selectedTags.remove(tag);
    notifyListeners();
  }

  void resetRemovableTags() {
    removableTags = const ['Tag A', 'Tag B', 'Tag C'];
    selectedTags
      ..clear()
      ..addAll(const ['Tag A', 'Tag B']);
    notifyListeners();
  }

  void setDisplayChipSelected(bool value) {
    displayChipSelected = value;
    notifyListeners();
  }

  void setDisplayDenseChipSelected(bool value) {
    displayDenseChipSelected = value;
    notifyListeners();
  }

  void setLayoutSwitchValue(bool value) {
    layoutSwitchValue = value;
    notifyListeners();
  }

  void setLayoutSelectionValue(bool value) {
    layoutSelectionValue = value;
    notifyListeners();
  }

  void setActiveCategories(Set<String> genres) {
    activeCategories
      ..clear()
      ..addAll(genres);
    notifyListeners();
  }

  void setSelectedRows(Set<GalleryRowItem> rows) {
    selectedRows = Set<GalleryRowItem>.unmodifiable(rows);
    notifyListeners();
  }

  void removeTableRows(Set<GalleryRowItem> rows) {
    _removedTableRows.addAll(rows);
    setSelectedRows(selectedRows.difference(rows));
  }

  void restoreTableRows() {
    _removedTableRows.clear();
    notifyListeners();
  }

  void setTopNavTab(int index) {
    if (topNavTab == index) return;
    topNavTab = index;
    notifyListeners();
  }

  void setSearchScopeQuery(String value) {
    searchScopeQuery = value;
    notifyListeners();
  }

  void setToolbarSearchQuery(
    String value, {
    required Iterable<GalleryRowItem> visibleItems,
  }) {
    toolbarSearchQuery = value;
    selectedRows = Set<GalleryRowItem>.unmodifiable(
      selectedRows.intersection(visibleItems.toSet()),
    );
    notifyListeners();
  }

  void cycleToolbarSort() {
    setToolbarSort(switch (toolbarSort) {
      'Name' => 'Progress',
      'Progress' => 'Status',
      _ => 'Name',
    });
  }

  void setToolbarSort(String value) {
    toolbarSort = value;
    notifyListeners();
  }

  void setPreviewCardSelected(bool value) {
    previewCardSelected = value;
    notifyListeners();
  }

  void setOverlayCascadeValue(String value) {
    overlayCascadeValue = value;
    notifyListeners();
  }

  void setOverlaySampleEnabled(bool value) {
    if (!overlaySamplePresent || overlaySampleEnabled == value) return;
    overlaySampleEnabled = value;
    notifyListeners();
  }

  void saveOverlaySample(String name, bool enabled) {
    overlaySampleName = name;
    overlaySampleEnabled = enabled;
    overlaySamplePresent = true;
    notifyListeners();
  }

  void resetOverlaySample() => saveOverlaySample('Example A', true);

  void deleteOverlaySample() {
    overlaySamplePresent = false;
    notifyListeners();
  }

  void recordOverlayEvent({required String en, required String zh}) {
    lastOverlayEvent = en;
    lastOverlayEventZh = zh;
    notifyListeners();
  }

  @override
  void dispose() {
    textController.dispose();
    formFieldController.dispose();
    searchController.dispose();
    if (_ownsRegistry) {
      registry.dispose();
    }
    super.dispose();
  }
}
