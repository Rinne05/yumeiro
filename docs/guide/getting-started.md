---
description: 在 Flutter 应用中引入 Yumeiro，运行第一个组件并接入已有路由。
---

# 开始使用

Yumeiro 是一套 Flutter 组件库。应用通过主题预设选择整体风格，组件根据语义角色解析颜色、轮廓、交互状态和材质。导航、数据加载和业务状态由应用管理。

## 安装

使用 Flutter 3.50.1 或更新版本，以及 Dart 3.14 或兼容的 Dart 3 版本。Yumeiro 当前通过源码接入，仓库中的 `pubspec.yaml` 设置了 `publish_to: none`。

如果应用旁边有一份 Yumeiro 检出，在应用的 `pubspec.yaml` 中声明相对路径。

```yaml
dependencies:
  flutter:
    sdk: flutter
  material_ui: ^1.11.1
  yumeiro:
    path: ../yumeiro

flutter:
  uses-material-design: true
```

如果团队从 Git 获取库，将 `path` 换成 `git`，把 `url` 设为克隆时使用的仓库地址，`ref` 固定到已验收的提交或标签。可在已有检出中通过 `git remote get-url origin` 和 `git rev-parse HEAD` 查看对应值。

保存后运行 `flutter pub get`。以下示例从 `material_ui` 导入 Flutter Material 控件和类型，从 `package:yumeiro/yumeiro.dart` 导入 Yumeiro 公开接口。

## 已验证的环境

以下构建和测试使用 Flutter 3.50.1 与 Dart 3.14.0。

| 环境 | 验证范围 |
| --- | --- |
| Flutter 测试后端 | 库和示例组件测试，涵盖键盘、触控布局、表单和路由。用 Impeller 测试后端另外验证光学材质。 |
| Web | 文档站和 Flutter Web 组件预览的正式构建。用 Chrome 运行组件测试，检查表单、键盘和响应式布局。 |
| Linux x64 | 示例画廊的正式构建。 |
| Android | 示例画廊的正式 APK 构建。在 Android 模拟器中检查对话框关闭及软键盘收起后保留输入。 |

应用在运行时按[材质能力](./materials#材质能力)选择光学玻璃或模糊降级。移动真机、macOS 和 Windows 暂待逐平台验收。

## 运行第一个页面

把下列内容放入应用的 `lib/main.dart`，然后运行 `flutter run`。外层画布应用当前主题的页面背景，按钮的回调连接应用自己的状态或业务动作。

```dart
import 'package:material_ui/material_ui.dart';
import 'package:yumeiro/yumeiro.dart';

void main() {
  runApp(
    YumeiroApp(
      title: 'Yumeiro 示例',
      preset: YumeiroThemePresets.classicLight,
      locale: const Locale('zh'),
      home: const YumeiroVisualSurface(
        role: YumeiroSurfaceRole.canvas,
        child: ExamplePage(),
      ),
    ),
  );
}

class ExamplePage extends StatefulWidget {
  const ExamplePage({super.key});

  @override
  State<ExamplePage> createState() => _ExamplePageState();
}

class _ExamplePageState extends State<ExamplePage> {
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    return YumeiroPageScaffold.detail(
      title: '第一个页面',
      body: YumeiroCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('已点击 $_count 次'),
            const SizedBox(height: 12),
            YumeiroButton(
              label: '增加次数',
              variant: YumeiroButtonVariant.primary,
              onPressed: () => setState(() => _count++),
            ),
          ],
        ),
      ),
    );
  }
}
```

## 接入已有应用

宿主从 `package:material_ui/material_ui.dart` 导入 `MaterialApp`、`ThemeData` 和 `GlobalMaterialLocalizations` 等 Material 类型。`yumeiroThemeData` 返回 `material_ui` 的 `ThemeData`，可传给同一包的 `MaterialApp` 或 `Theme`。与 Yumeiro 共用的颜色方案、按钮样式和 Material 路由也使用该包的类型。

使用 Cupertino 组件或本地化代理时，从 `package:cupertino_ui/cupertino_ui.dart` 导入。应用直接导入哪个包，就在自己的 `pubspec.yaml` 中声明相应依赖。上面的安装示例使用 `material_ui: ^1.11.1`，应用按需添加 `cupertino_ui: ^1.1.7`。通用 Flutter API 可继续从 `package:flutter/widgets.dart`、`foundation.dart`、`services.dart` 和 `gestures.dart` 导入。

`YumeiroApp` 封装 `MaterialApp`，设置主题和本地化，并在导航树上方安装 `YumeiroScope`。已有 `MaterialApp.router` 时，在 `builder` 中用 `YumeiroScope` 包裹现有路由子树，让页面和浮层都读取 Yumeiro 配置。

```dart
Widget buildRoutedApp(RouterConfig<Object> routerConfig) {
  final preset = YumeiroThemePresets.classicDark;

  return MaterialApp.router(
    routerConfig: routerConfig,
    theme: yumeiroThemeData(preset: preset),
    supportedLocales: YumeiroLocalizations.supportedLocales,
    localizationsDelegates: [
      YumeiroLocalizations.delegate,
      ...GlobalMaterialLocalizations.delegates,
    ],
    builder: (context, child) => YumeiroScope(
      inheritTheme: true,
      child: child ?? const SizedBox.shrink(),
    ),
  );
}
```

`yumeiroThemeData` 生成带有 `YumeiroThemeExtension` 的 `ThemeData`。组件通过 `YumeiroTheme.of(context)` 读取它，作用域还提供输入追踪、主题注册表、材质能力、Toast 容器和模糊背景组。

`inheritTheme: true` 保留宿主当前的 Material 主题，以及其中已有的 Yumeiro 令牌。宿主可以分别配置 `theme` 和 `darkTheme`。如果当前宿主主题缺少 Yumeiro 扩展，作用域会从自己的主题设置派生并补入它。默认模式会应用作用域生成的主题，同时保留宿主的其他 `ThemeExtension`。

设置子树的 `locale` 时，作用域优先使用支持目标语言的宿主翻译，再回退到 Material 内置翻译。设为 `null` 可恢复继承宿主语言。启用和撤销局部语言设置都会保留页面状态。

### 确定应用根部的配置

| 接入方式 | 适用场景 | 配置边界 |
| --- | --- | --- |
| `YumeiroApp` | 新建页面或独立应用 | 创建 `MaterialApp`，其 `builder` 接收到的子树已安装 `YumeiroScope`。包装时把该子树保留在返回结果里。 |
| `YumeiroScope` | 接入已有应用或配置局部区域 | 从 `MaterialApp.builder` 包裹导航子树，让普通路由和从路由打开的浮层同时继承配置。使用 `inheritTheme: true` 由宿主管理 Material 主题。 |
| `yumeiroThemeData` | 生成可交给宿主的 `ThemeData` | 提供 Material 主题和 Yumeiro 令牌。如果页面还需要通知宿主、自定义材质能力或输入跟踪，再安装相应的作用域。 |

组件读取调用位置最近的主题。弹窗和通知需要使用页面子树里的 `BuildContext`。如果自定义导航出现回退到 Classic Dark、弹窗文案与页面语言不同或通知找不到宿主，先检查调用上下文及导航器与作用域的上下级关系。

如果宿主创建 `toastController` 或 `inputController` 并传给 `YumeiroScope`，由宿主释放它们。省略时，作用域会管理自己的控制器。可以在宿主状态中创建并复用主题注册表。按 `presetId` 选中的预设会随注册表的替换和删除更新。

对话框、编辑器和底部面板默认加入根导航器。需要让浮层随某个标签页或嵌套路由管理时，从该页面调用浮层函数并传入 `useRootNavigator: false`。使用浮层构建器收到的上下文关闭路由。

<ApiLink symbol="YumeiroApp" />

<ApiLink symbol="YumeiroScope" />

<ApiLink symbol="yumeiroThemeData" />

<ApiLink symbol="YumeiroTheme.of" />

继续阅读[主题与预设](./theming)了解如何切换主题，或在[组件目录](/components/)查找需要的控件。
