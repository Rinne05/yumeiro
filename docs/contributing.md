# 维护文档

站点跟随当前版本的 Yumeiro。组件行为或公开接口发生变化时，在同一个提交中更新相关指南、示例和 Dart 文档注释。

## 本地启动

安装 Node.js 22 或以上版本和 [Yumeiro 要求的 Flutter SDK](/guide/getting-started)，确保 `flutter`、`dart` 和 `npm` 都能从命令行调用。从仓库根目录运行以下命令。

```sh
npm --prefix docs ci
npm --prefix docs run generate
npm --prefix docs run dev
```

打开终端输出的地址。Markdown、样式和 Vue 组件修改会由 VitePress 自动刷新。修改 Dart 示例、组件源码或注释后，重新运行 `generate` 即可更新 Flutter Web 与 Dartdoc。

只调试 Flutter 示例时，可以在 `example/` 中运行 `flutter run -d chrome -t lib/main_docs.dart`。从首页选择示例，或在浏览器地址后添加 `?demo=form-controls&modality=touch` 直接打开触控版表单。`flutter run` 启动完整画廊，其中控件页和布局页复用文档的表单、紧凑表和分页示例。

## 编写组件页面

在 `docs/components/` 中说明组件适合的场景、主要参数之间的关系、交互状态和无障碍用法。新增文件后，在 `docs/.vitepress/config.ts` 的对应分组添加侧栏项。

用 `<ApiLink>` 引用从 `package:yumeiro/yumeiro.dart` 导出的公开类型、函数及类型成员。源码的 Dartdoc 注释说明默认行为、回调触发条件、状态所有权和约束，页面提供选型与可运行示例。完整签名见生成的 <ApiLink />。

```md
<ApiLink symbol="YumeiroDataTable" />
<ApiLink symbol="YumeiroDataTable.rowKey" />
```

成员使用 `类型.成员`，例如 `YumeiroTableSelection.selectedKeys`。站点从 Dartdoc 索引查找目标。重命名公开成员时同时更新引用，站点构建会指出无法解析的名称。

可运行示例按功能放在 `example/lib/docs/`。用 `// #region <id>` 与 `// #endregion <id>` 标记 Dart 代码，并在 `example/lib/main_docs.dart` 注册同名示例。示例片段应包含自身需要的辅助定义。下面的路径以 `docs/components/` 下的 Markdown 文件为基准。首尾空行让 VitePress 在 Vue 组件内部解析 Markdown。

```md
<ComponentDemo id="compact-table" title="紧凑表预览" :overlay-height="360">

<<< ../../example/lib/docs/layout_demos.dart#compact-table

</ComponentDemo>
```

浏览器中的预览根据 Flutter 内容高度调整。`overlay-height` 给打开的面板预留交互空间。设置 `input-modes` 可切换指针和触控，附加 `compact-touch` 时，嵌入预览的触控视口宽度上限为 390 像素，适合演示竖屏的底部面板。设置 `theme-styles` 可对比经典、液态玻璃和复古像素。切换会重新加载该示例。也可以在独立预览中保留 `demo` 参数并追加 `&modality=pointer` 或 `&modality=touch`。

示例尽量使用本地素材和独立的演示状态。用键盘、窄视口和浅深外观检查关键交互。预览里的控件由真实 Flutter 代码驱动，光学材质依赖当前运行环境的[着色器能力](/guide/materials)。

## 构建与部署

GitHub Actions 使用 Flutter 3.50.1 和 Node.js 24 运行静态分析、库测试、示例测试、站点构建和包演练。`build` 先生成和校验 Dartdoc，再编译 Flutter Web 示例，最后构建 VitePress 并检查站内链接和代码片段路径。从仓库根目录可运行同一套检查。

```sh
flutter pub get
flutter analyze --no-pub
flutter test --no-pub
(cd example && flutter test --no-pub)
npm --prefix docs ci
npm --prefix docs run build
python3 tool/check_package.py --repository https://example.com/yumeiro
```

CI 另用 Mesa 软件 Vulkan 驱动运行 Impeller 测试。`YUMEIRO_REQUIRE_OPTICAL` 会检查运行时实际支持着色器过滤。本地光学测试命令见[材质与玻璃](./guide/materials#排查折射和模糊)。

包演练复制当前 Git 工作树中的源码到临时目录，通过 `flutter pub publish --dry-run` 检查归档内容。项目通过源码分发，`pubspec.yaml` 设置为 `publish_to: none`。本地尚未配置远端时，可以用上面的 `example.com` 地址满足演练副本的元数据校验。已有仓库地址时，将它传给 `--repository`。GitHub Actions 会使用当前仓库的 URL。缺少 `repository` 和 `homepage` 时，pub 的演练会以非零状态退出。归档保留 Flutter shader 和示例，文档站源码随 Git 仓库分发。

站点的静态发布目录是 `docs/.vitepress/dist/`。将完整目录上传到静态托管即可，目录内包含 `api/` 和 `preview/`。依赖、生成物和 VitePress 缓存都在 `docs/` 的 Git 忽略规则中。

Flutter Web 引擎文件随预览一同生成。缺少字形时，Flutter Web 仍可按运行时配置请求补充字体。 [Flutter Web 初始化配置](https://docs.flutter.dev/platform-integration/web/initialization)

部署到子路径时，构建、开发或预览命令都使用相同的 `YUMEIRO_DOCS_BASE`。它以 `/` 开头和结尾，默认值是 `/`。

```sh
YUMEIRO_DOCS_BASE=/yumeiro/ npm --prefix docs run build
YUMEIRO_DOCS_BASE=/yumeiro/ npm --prefix docs run preview
```

在 PowerShell 中先执行 `$env:YUMEIRO_DOCS_BASE = '/yumeiro/'`。浏览器应能在同一前缀下加载文档、Dartdoc 和 Flutter Web 资源。

## 部署到 Vercel

将 Yumeiro 仓库连接到 Vercel，或从仓库根目录运行 `npx vercel` 部署。站点构建读取 `lib/` 和 `example/`，在 Vercel 中将 Root Directory 保持在仓库根目录，Node.js Version 选 `24.x`。独立域名和子域名使用默认的 `/`。 [Vercel 构建配置](https://vercel.com/docs/builds/configure-a-build)

新项目的第一次部署使用 Production 环境。后续可从仓库根目录运行 `npx vercel`，或推送到连接仓库的非生产分支，创建 Preview 部署。 [Vercel 部署环境](https://vercel.com/docs/deployments/environments#first-deployment)

仓库根目录的 `vercel.json` 已配置框架预设、依赖安装、Flutter 3.50.1 和文档构建。Vercel 从源码生成 API 文档和 Flutter Web 示例，并发布 `docs/.vitepress/dist`。更新 CI 的 Flutter 版本时也请同步更新此配置。 [Vercel 项目配置](https://vercel.com/docs/project-configuration/vercel-json)

通过 CLI 上传源码时，`.vercelignore` 排除本地 Flutter 构建产物、生成的文档和工具缓存。 [Vercel 上传排除规则](https://vercel.com/docs/deployments/vercel-ignore)

部署后用预览链接验证直接访问组件页、打开交互示例和 API 成员页。保留生成的 `.html` 路径和静态目录结构。Vercel CDN 为支持的浏览器压缩 JavaScript 和 WASM。若首屏慢，在浏览器 Network 中检查 `main.dart.js`、`canvaskit.wasm` 的响应状态、`Content-Encoding` 和下载时间。Flutter 初始化和 iframe 重启仍在访客浏览器发生。 [Vercel CDN 压缩](https://vercel.com/docs/how-vercel-cdn-works/compression)

VitePress 带内容哈希的资源可以长期缓存。当前 Flutter Web 的 `main.dart.js`、`flutter_bootstrap.js` 和自托管的 `canvaskit/` 使用稳定文件名，发布时保留重新验证，以便访客获取新版本。 [Flutter Web 缓存策略](https://docs.flutter.dev/deployment/web)

## 排查本地预览

`npm --prefix docs ci` 报缺少锁文件，同时 `build` 找不到 `docs/package.json` 时，先核对当前目录。应从包含 `lib/yumeiro.dart` 与 `docs/package-lock.json` 的 Yumeiro 仓库根目录运行命令。

`npm --prefix docs run preview` 的冷请求可能花较长时间实时压缩 Flutter JavaScript。只查看已构建的产物时，可使用直接提供静态文件的本地服务器。下面的命令适用于默认根路径构建，从仓库根目录执行。

```sh
python3 -m http.server 4174 --bind 127.0.0.1 --directory docs/.vitepress/dist
```

打开 `http://127.0.0.1:4174/`。修改 Markdown 时使用 `npm --prefix docs run dev`，修改 Dart 预览源码时重新生成产物。

页面能打开但 Flutter 预览空白时，从浏览器 Network 核对 iframe 地址、`flutter_bootstrap.js`、CanvasKit 的 WASM 和 `assets/` 请求。子路径部署时，Flutter 预览地址和 VitePress 页面应共享构建时的前缀。浏览器能画出玻璃但光学效果与原生不同，按[材质能力](./guide/materials#材质能力)确认实际档位。

## 更新站点依赖

将 `docs/package.json` 和 `docs/package-lock.json` 一起更新。当前使用 VitePress 1.6.4，并通过 npm `overrides` 将 Vite 锁定在已修复开发服务器安全问题的 6.4.6。更新 VitePress 时检查它的 Vite 依赖，并验证 `npm ci`、开发模式和生产构建。
