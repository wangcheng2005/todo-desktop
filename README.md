# Todo Desktop

一个基于 Flutter 的 Windows 桌面待办事项管理应用，支持系统托盘集成和实时任务提醒。

## 功能特性

- 📝 **待办事项管理** - 创建、编辑、删除、完成任务
- 🏷️ **分类与优先级** - 按工作、个人、学习、健康、其他分类，设置高中低优先级
- 📅 **时间管理** - 设置开始时间和截止时间，自动提醒
- 👀 **右下角提醒面板** - 常驻浮动面板显示待办项，可折叠，不影响桌面操作
- 🔔 **系统托盘** - 最小化到托盘，右键快速操作
- 💾 **本地存储** - 使用 Hive 数据库，快速、可靠的本地数据持久化
- 🎨 **现代 UI** - 支持 Material You 设计规范

## 项目结构

```
lib/
├── main.dart                     # 应用入口，主窗口和多窗口控制
├── app.dart                      # 应用 Widget 定义
├── core/
│   ├── notification/
│   │   └── reminder_popup_app.dart          # 右下角提醒浮动面板UI（子窗口）
│   ├── scheduler/
│   │   └── scheduler_service.dart           # 待办调度服务（管理提醒弹窗）
│   ├── storage/
│   │   └── storage_service.dart             # 数据存储服务（Hive 操作）
│   └── tray/
│       └── tray_service.dart                # 系统托盘服务
├── features/
│   ├── todo/
│   │   ├── model/
│   │   │   └── todo_model.dart              # Todo 数据模型和枚举
│   │   ├── provider/
│   │   │   └── todo_provider.dart           # Riverpod 状态管理
│   │   └── ui/
│   │       └── pages/
│   │           └── home_page.dart           # 主页面
│   └── settings/
│       └── settings_dialog.dart             # 设置对话框
└── shared/
    ├── constants.dart                       # 常量定义
    └── theme.dart                           # 应用主题配置

windows/                          # Windows 原生代码
```

## 核心技术栈

- **框架**: Flutter with Dart
- **状态管理**: Flutter Riverpod
- **本地存储**: Hive
- **窗口管理**: 
  - `window_manager` - 主窗口管理（托盘、最小化等）
  - `desktop_multi_window` - 多窗口IPC通信
- **系统集成**: 
  - `system_tray` - 系统托盘
  - Win32 FFI - 窗口定位和样式控制

## 快速开始

### 环境要求

- Flutter 3.24.0 或更高版本
- Dart 3.5.0 或更高版本
- Windows 10/11
- Visual Studio 或 Visual Studio Build Tools（用于编译C++代码）

### 安装依赖

```bash
flutter pub get
```

### 运行项目

#### 开发模式

```bash
flutter run -d windows
```

#### 生产模式（更快的性能）

```bash
flutter run -d windows --release
```

### 编译项目

#### 编译为可执行文件（Release 版本）

```bash
flutter build windows --release
```

编译后的可执行文件位于：
```
build/windows/x64/runner/Release/
└── todo_desktop.exe
```

#### 编译为 MSIX 安装包（可选）

```bash
flutter pub global activate msix
flutter pub global run msix:create
```

生成的 `.msix` 安装包可以直接安装到 Windows 系统。

## 使用说明

### 主窗口

- **新建待办** - 点击 `+` 按钮创建新任务
- **编辑任务** - 双击或右键任务进行编辑
- **完成任务** - 勾选任务或点击完成按钮
- **删除任务** - 右键删除或点击删除按钮
- **分类/优先级** - 创建或编辑时选择

### 托盘集成

- **最小化** - 点击关闭按钮将主窗口最小化到托盘
- **托盘菜单** - 右键托盘图标可打开菜单
- **快速打开** - 左键点击托盘图标打开主窗口

### 右下角提醒面板

- **自动显示** - 启动时或创建新任务时显示
- **折叠/展开** - 点击标题栏可折叠/展开面板
- **快速完成** - 点击任务后的✓按钮直接完成
- **关闭** - 点击✗按钮关闭面板
- **置顶** - 面板始终显示在其他窗口上方

## 开发指南

### 添加新的依赖

```bash
flutter pub add package_name
```

### 运行代码分析

```bash
flutter analyze
```

### 格式化代码

```bash
dart format lib/
```

### 生成代码

该项目使用 `build_runner` 生成部分代码（如 Hive 适配器）：

```bash
flutter pub run build_runner build
```

或监听变化自动生成：

```bash
flutter pub run build_runner watch
```

## 项目架构说明

### 多窗口架构

1. **主窗口** (`main window`)
   - 完整的 Flutter Widget 树
   - 管理整个应用的数据和状态（Riverpod）
   - 集成托盘服务和调度器

2. **提醒弹窗** (`sub-window`)
   - 独立的 Flutter 引擎实例
   - 通过 `desktop_multi_window` 与主窗口通信
   - 使用 Win32 FFI 实现右下角固定位置
   - 不占用系统任务栏

### 数据流

```
Storage (Hive)
     ↓
TodoProvider (Riverpod) ← ref.listen()
     ↓
Main Window UI ← 用户输入
     ↓
SchedulerService ← todoListProvider 变化
     ↓
PopupWindow (IPC: updateTodos)
```

### IPC 通信

- **主窗口 → 弹窗**: 使用 `WindowController.invokeMethod('updateTodos', ...)`
- **弹窗 → 主窗口**: 使用 `WindowMethodChannel.invokeMethod('markComplete', ...)`

## 常见问题

### Q: 编译时出错 "CMake not found"
A: 安装 Visual Studio Build Tools 并确保包含 C++ 开发工具和 CMake。

### Q: 弹窗显示位置不正确
A: 检查显示器分辨率和工作区设置。工作区信息通过 `SystemParametersInfo` 动态获取。

### Q: 托盘图标不显示
A: 确保 `assets/icons/app_icon.ico` 文件存在。如果不存在，系统会使用默认图标。

### Q: 关闭主窗口后程序仍在运行
A: 这是正常行为。主窗口最小化到托盘，需要从托盘"退出"才能完全关闭应用。

## 许可证

本项目采用 MIT 许可证。

## 联系与反馈

如有问题或建议，欢迎提交 Issue。
