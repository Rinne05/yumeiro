# Yumeiro Example Gallery

Interactive showcase application demonstrating all Yumeiro theme presets, live parameter customization, semantic roles, custom effect passes, and modality-adaptive components.

Each sample keeps its own interaction state. The chip sample supports selection, removal, and reset. The editor uses a local draft, simulates saving, and asks before discarding changes.

## Run the gallery

From the repository root, use Flutter 3.50.1 or later to install the example's dependencies. The gallery includes runners for Linux, Android, and Web.

```sh
cd example
flutter pub get
flutter run -d linux
flutter run -d chrome
```

For Android, run `flutter devices` with an emulator or device connected, then run `flutter run -d <device-id>`. The default entrypoint uses Flutter's target platform, including on Web. Android and iOS browsers use the touch gallery, and desktop browsers use the pointer gallery. To open the touch gallery in a desktop browser, run `flutter run -d chrome -t lib/main_mobile.dart` or add `--dart-define=YUMEIRO_PROFILE=mobile` to the default run command. Use `lib/main_desktop.dart` or `--dart-define=YUMEIRO_PROFILE=desktop` to force the pointer gallery.

The Linux gallery uses a minimum content size of `960×640`. Narrow pointer viewports collapse the sidebar to icons and retain pointer controls. The isolated `390×844` touch preview is available alongside the pointer gallery at a window width of 960 logical pixels or more.

To run the standalone browser previews used by the documentation, run `flutter run -d chrome -t lib/main_docs.dart` from `example/`. Select a demo from its index, or append a query such as `?demo=form-controls&modality=touch` to the browser URL. The full documentation site includes the same previews and their source snippets. Build it from the repository root with Node.js 22 or later.

```sh
npm --prefix docs ci
npm --prefix docs run build
npm --prefix docs run preview
```

## Showcase Structure

- `lib/src/theme/gallery_registry.dart` — 13 built-in families (24 presets: 11 light/dark pairs, dark-only Geek, and light-only 素描（Sketch）) + host-registered `Nordic Amber` preset, custom semantic roles, and `GalleryPrismPass`
- `lib/src/state/gallery_controller.dart` — centralized state and desktop → mobile preview token synchronization
- `lib/src/shell/gallery_shell.dart` — adaptive `YumeiroNavigationShell`, `YumeiroSearchHost` / `YumeiroSearchScope`, and mobile viewport toggle
- `lib/src/pages/` — 5 focused showcase pages:
  - `themes_page.dart` — presets, live `YumeiroThemeOption` customization, density/locale/motion, contextual Liquid Glass / Thick Frosted Glass fallback simulation, a ceramic + metal + acrylic material mix, tokens & custom effect pass
  - `controls_page.dart` — text input variants, interactive tags, standalone selectors, date and time pickers, numeric controls, and a form with validation and reset
  - `display_page.dart` — badges, indicators, feedback, image loading and fallback, media results, and standalone and sliver poster grids
  - `layout_page.dart` — page headers and tabs, adaptive navigation, a page with a scrolling list, containers, settings and list rows, data tables, and server pagination
  - `overlays_page.dart` — dialogs, editor drafts and saving, compound filters, adaptive action menus, notifications, tooltips, and touch examples for sheets and detail routes

The gallery uses labels such as Example A and Option A for sample data. API captions sit above their samples. A named entry such as `YumeiroSelect.searchable` or a distinct configuration such as `YumeiroDialog.confirm(destructive: true)` has its own caption. Interactions such as choosing an option, moving a slider, and toggling a switch stay in the same sample. Use the header search button or `Ctrl+F` (`⌘F` on macOS) to find a section by title or API caption. [Sample titles and search terms](lib/src/widgets/gallery_examples.dart)

## Form interactions

Change Field A to update the options in Field B, or enter `retry` in Field B to simulate a failed request. Field H searches a fixed list and saves the selected value with the other fields. Submit to see validation and a saved summary, then reset to restore the starting values. Related fields sit side by side when space permits. The documentation preview runs the same form.

## Material previews

The family cards cover 釉面陶瓷 (Ceramic Glaze), 拉丝金属 (Brushed Metal), 新粗野主义 (Neo-Brutalist), 复古像素 (Pixel Retro), 磨砂亚克力 (Frosted Acrylic), 软硅胶 (Soft Silicone), and 厚磨砂玻璃 (Thick Frosted Glass). Each of these families and 新拟态 (Neumorphic) provides light and dark variants. Their live controls use the selected preset's own options; the original light IDs remain valid.

A deterministic color backdrop is confined to the material mix example and clipped to its bounds. Changing a preset keeps the gallery's normal page background; host applications choose any artwork behind their own translucent surfaces. Acrylic always uses Gaussian blur; the optical fallback switch is shown for Frosted Glass and Liquid Glass. Actual shader support is still determined by the runtime.

The **One Page, Three Materials / 同一页面，三种材质** section combines a working ceramic button, frosted acrylic card, and brushed metal panel independently of the selected preset. Pixel Retro uses monospace by default; host apps can provide an actual pixel font through `YumeiroFontConfig`.

## Theme selection

**主题风格与外观模式 / Theme Style & Appearance** presents one card per family: 13 built-in styles plus Nordic Amber, for 14 cards. Choose a style card, then use the separate **浅色 / 深色 (Light / Dark)** selector. Card palettes follow the preferred mode, and exactly one family is selected.

Geek and Nordic Amber show **固定深色 (Fixed Dark)**; 素描（Sketch） shows **固定浅色 (Fixed Light)**. Their mode selector is disabled. Visiting these styles retains the preferred mode: Light → Geek → Ceramic Glaze returns to Ceramic Glaze Light. Switching modes within the same style preserves the current accent and live options; changing styles resets those values for the new family.

Desktop selection synchronizes the active preset, preferred mode, and appearance settings into the isolated mobile preview, including when a fixed style keeps the same active preset. Mobile navigation and sample interaction state remain independent.

Only appearance changes trigger that synchronization; desktop navigation and sample actions preserve the mobile preview's own theme and locale choices. Switching pages starts at the top of the new page.

## Table interactions

The adaptive table includes its search and selection toolbars in the same card. Try applying a filter and inspecting the count on the toolbar. Switch between browsing, single selection, and multiple selection. Search matches names, categories, and statuses. In multiple selection, Select All applies to the current results, and changing the search removes hidden rows from the selection. Right-click or long-press a row to open actions for that row. On touch, compare summary rows with the horizontally scrolling column layout.

The compact and lazy tables section opens short table previews in desktop dialogs or touch bottom sheets. Below them, switch between standard and compact `YumeiroDataTable` layouts and compare single-line and stacked rows. View all switches to `YumeiroDataTable.sliver` and shows 120 records. Select a few distant rows, then use Hide to return to the first three records and check that the selection count still includes hidden rows. The separate server pagination example covers sorting, filtering, retry, and cross-page selection. Select All applies to the current page, and Clear all selections applies to every page.

## Selection and overlays

The Controls page shows fixed, searchable, and remote selectors alongside date and time fields. **Inline selection list** groups single choice without a search field, multiple choices with search and clear actions, and a long list that scrolls within its bounds. **Choose multiple tags** shows a confirmation picker beside editable tokens and removable chips. The form sample shows both inline field types and the confirmation picker.

On the Display page, the poster samples compare an embedded grid, a grid with its own viewport, and a sliver inside a scroll view. On the Layout page, edit both disclosure fields and collapse and reopen them to see how `maintainState` affects the draft.

On the Overlays page, **Dialogs & Routes** includes ordinary and destructive confirmations, compound filters, and an editor with a save delay and a discard confirmation. The editor opens as a dialog for pointer input and a bottom sheet on a compact portrait touch viewport. The touch gallery also shows a secondary detail route with a themed page background and explicit single- and multi-select sheets. Under **Menus & Feedback**, the item-actions sample opens a pointer menu or a touch action panel from the same button. Notifications include an embedded card, timed toasts, and a toast that stays in the queue until dismissed. Touch tooltips include long-press and tap examples.
