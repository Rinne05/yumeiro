library;

// Localization
export 'src/l10n/built_in_locales.dart';
export 'src/l10n/localizations.dart';

// Foundation
export 'src/foundation/colors.dart';
export 'src/foundation/icons.dart';
export 'src/foundation/input.dart';
export 'src/foundation/modality.dart';
export 'src/foundation/motion.dart';
export 'src/foundation/radii.dart';
export 'src/foundation/spacing.dart';
export 'src/foundation/typography.dart';

// Theme & Material Pipeline
export 'src/theme/effect_pass.dart';
export 'src/theme/materials.dart';
export 'src/theme/semantic_visuals.dart' hide resolveYumeiroStatusFeedback;
export 'src/theme/theme.dart' hide applyYumeiroTypography;
export 'src/theme/theme_extension.dart';
export 'src/theme/theme_options.dart'
    hide customizeYumeiroColors, customizeYumeiroVisuals;
export 'src/theme/theme_preset.dart';
export 'src/theme/theme_registry.dart';
export 'src/theme/visual_role.dart';

// Rendering Primitives
export 'src/primitives/backdrop_group.dart';
export 'src/primitives/pixel_border.dart';
export 'src/primitives/glass_backdrop.dart'
    show YumeiroGlassBackdrop, YumeiroGlassSamplingScope;
export 'src/primitives/visual_scope.dart';
export 'src/primitives/visual_surface.dart';

// One-Stop Root Scope
export 'src/scope/yumeiro_scope.dart';

// Components - Controls
export 'src/components/controls/async_select.dart';
export 'src/components/controls/buttons.dart';
export 'src/components/controls/cascading_select.dart';
export 'src/components/controls/checkboxes.dart' show YumeiroCheckbox;
export 'src/components/controls/color_picker.dart';
export 'src/components/controls/date_time_pickers.dart';
export 'src/components/controls/inputs.dart';
export 'src/components/controls/multi_select.dart';
export 'src/components/controls/rating_editor.dart';
export 'src/components/controls/search_action.dart';
export 'src/components/controls/segmented.dart';
export 'src/components/controls/select.dart';
export 'src/components/controls/sliders.dart';
export 'src/components/controls/switches.dart';
export 'src/components/controls/token_input.dart';

// Components - Display
export 'src/components/display/badges.dart';
export 'src/components/display/callouts.dart';
export 'src/components/display/chips.dart';
export 'src/components/display/loading.dart';
export 'src/components/display/media_images.dart';
export 'src/components/display/media_overlays.dart';

// Components - Layout
export 'src/components/layout/action_bar.dart' show YumeiroActionBar;
export 'src/components/layout/data_table.dart';
export 'src/components/layout/disclosure.dart';
export 'src/components/layout/input_action_group.dart';
export 'src/components/layout/list_tile.dart';
export 'src/components/layout/navigation_shell.dart';
export 'src/components/layout/page_header.dart' hide buildYumeiroCompactHeader;
export 'src/components/layout/panels.dart';
export 'src/components/layout/scaffolds.dart';
export 'src/components/layout/scroll_view.dart';
export 'src/components/layout/selection_row.dart';
export 'src/components/layout/setting_row.dart';
export 'src/components/layout/table_selection.dart'
    show YumeiroTableSelection, YumeiroTableSelectionMode;

// Components - Navigation
export 'src/components/navigation/page_transition.dart';
export 'src/components/navigation/pagination.dart';
export 'src/components/navigation/toolbars.dart';
export 'src/components/navigation/top_navigation.dart';

// Components - Overlays
export 'src/components/overlays/context_menu.dart';
export 'src/components/overlays/dialogs.dart' hide presentYumeiroSheet;
export 'src/components/overlays/editor.dart';
export 'src/components/overlays/filter.dart';
export 'src/components/overlays/menu_actions.dart'
    show
        YumeiroMenuEntry,
        YumeiroMenuAction,
        YumeiroMenuHeader,
        YumeiroMenuDivider;
export 'src/components/overlays/sheets.dart'
    hide
        buildMenuSelectionList,
        buildMultiSelectOptions,
        buildSearchSelectionResults,
        buildSheetSelectionList,
        filterSelectionOptions,
        presentMultiSelectionSheet,
        presentSingleSelectionSheet,
        SearchableSelectionSheet;
export 'src/components/overlays/toasts.dart';
export 'src/components/overlays/tooltip.dart';
