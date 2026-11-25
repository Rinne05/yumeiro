---
description: 配置内置中英文，覆盖组件提示文字，并为应用注入字体和语义图标。
---

# 本地化与字体图标

Yumeiro 内置简体中文和英文。内置文案涵盖组件操作、提示、主题名称和预设选项；应用提供页面标题、业务字段和业务错误信息。

## 语言与内置文案

`YumeiroApp` 默认根据应用语言环境选择 `zh` 或 `en`。可以传入 `locale` 跟随应用设置，在组件里通过 `YumeiroLocalizations.of(context)` 读取当前文案。在已有 `MaterialApp` 中使用 `YumeiroScope` 时，推荐按[开始使用](./getting-started#接入已有应用)注册本地化委托，使路由和浮层共享已选语言。

```dart
Widget buildApplyButton(BuildContext context, VoidCallback onApply) {
  return YumeiroButton(
    label: YumeiroLocalizations.of(context).apply,
    variant: YumeiroButtonVariant.primary,
    onPressed: onApply,
  );
}
```

可以继承 `YumeiroLocalizationsZh` 或 `YumeiroLocalizationsEn`，只覆盖应用需要改写的字符串。`localizations` 接收当前使用的文案实例。如果应用支持切换语言，随 `locale` 选择对应的实例。

```dart
class AppStringsZh extends YumeiroLocalizationsZh {
  const AppStringsZh();

  @override
  String get confirm => '继续';
}

Widget buildChineseApp(Widget home) {
  return YumeiroApp(
    locale: const Locale('zh'),
    localizations: const AppStringsZh(),
    home: home,
  );
}
```

更多语言可在宿主应用实现 `YumeiroLocalizations`，与该语言的 `Locale` 一起提供。已有应用也可以在 `MaterialApp` 注册自己的 `LocalizationsDelegate<YumeiroLocalizations>`，由 `YumeiroScope` 继承已加载的文案。声明额外语言时，同时配置应用自己的 `supportedLocales` 和相关 Flutter 本地化委托。

`YumeiroApp` 优先使用显式传入的 `localizations` 实例，其次使用 `localizationsDelegates` 中支持当前语言的委托，最后使用内建文案。宿主委托也可以覆盖英文或中文。

### 区分文案实例和应用语言

`locale` 决定 Flutter 的语言环境，`localizations` 只替换 Yumeiro 组件使用的文案。传入固定文案实例时，切换 `locale` 后同时传入对应的新实例。需要按语言返回多套 Yumeiro 文案时，将自己的委托加到 `YumeiroApp.localizationsDelegates`，或在已有的 `MaterialApp` 中注册并由 `YumeiroScope` 继承。

本地化名称与持久化标识分开保存。用 preset 或 option 的 ID 查找记录，通过 `resolveLabel` 显示名称。自定义家族和选项可以提供文案回退。独立子树若没有语言环境，`YumeiroScope` 以英文初始化，`YumeiroLocalizations.of` 也有英文回退。

在自定义文案中覆盖 `familyNeumorphic` 这类家族名称时，默认的浅色和深色预设会一起使用新名称。只调整一种外观时，覆盖对应的 `presetNeumorphicLight` 或 `presetNeumorphicDark`。

## 注入字体

用 `YumeiroFontConfig` 设置正文/标题的 `fontFamily` 与 `fontFallback`，以及代码和数字的 `monoFontFamily` 与 `monoFontFallback`。如果应用通过资源分发字体，应先在应用 `pubspec.yaml` 中注册并使用同名 `family`。

```yaml
flutter:
  uses-material-design: true
  fonts:
    - family: AppMono
      fonts:
        - asset: assets/fonts/AppMono-Regular.ttf
```

复古像素主题可以通过 `monoFontFamily` 采用应用自己的像素字体。请同时为 CJK 等目标语言准备字形回退，以便混排时仍能读取标签。

`resolvedFontFallback` 将非空的 `fontFamily` 放到正文回退列表首位。保留默认 `fontFallback` 时，原生构建会按平台排序候选字体，Web 使用通用候选列表。如果传入自己的回退列表，按指定的顺序解析。预览与目标设备出现字宽差异时，用相同的字体资产和回退列表复查长标签和数字对齐。

## 注入图标

`YumeiroIconSet.material()` 提供默认图标。用 `copyWith` 替换某些语义槽位，通过 `YumeiroApp.icons` 或 `YumeiroScope.icons` 注入。组件自身的 `icon` 参数适合指定特定场景的图标，`YumeiroTheme.iconsOf(context)` 可以在自定义组件里读取共享图标集。

```dart
Widget buildBrandedApp(Widget home) {
  return YumeiroApp(
    fontConfig: const YumeiroFontConfig(monoFontFamily: 'AppMono'),
    icons: YumeiroIconSet.material().copyWith(search: Icons.search_outlined),
    home: home,
  );
}
```

<ApiLink symbol="YumeiroLocalizations" />

<ApiLink symbol="YumeiroLocalizationsZh" />

<ApiLink symbol="YumeiroFontConfig" />

<ApiLink symbol="YumeiroFontConfig.resolvedFontFallback" />

<ApiLink symbol="YumeiroIconSet" />
