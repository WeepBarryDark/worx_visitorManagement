# Printer Configuration Documentation
# 打印机配置文档

## 概述 (Overview)

本文档详细说明 WORX Visitor Management 系统中打印机信息的来源、配置流程和数据流。

---

## 目录 (Table of Contents)

1. [打印机信息来源](#打印机信息来源)
2. [配置流程](#配置流程)
3. [数据流图](#数据流图)
4. [纸张类型配置](#纸张类型配置)
5. [打印状态跟踪](#打印状态跟踪)
6. [故障排除](#故障排除)

---

## 打印机信息来源

### 1. 网络发现 (Network Discovery)

打印机信息主要通过以下两种方式获取：

#### A. Brother SDK mDNS 发现（Android）
- **文件位置**: `lib/services/printer_service.dart`
- **方法**: `_scanNetworkWithBrotherSDK()`
- **行号**: 86-136
- **工作原理**:
  ```dart
  final printerInstance = printer.Printer();
  final netPrinters = await printerInstance.getNetPrinters(supportedModels);
  ```
- **获取的信息**:
  - 打印机型号 (`modelName`)
  - IP 地址 (`ipAddress`)
  - MAC 地址 (`macAddress`)

#### B. 手动网络扫描（iOS / 所有平台备用）
- **文件位置**: `lib/services/printer_service.dart`
- **方法**: `_scanNetworkManually()`
- **行号**: 139-183
- **工作原理**:
  1. 获取本地 IP 地址
  2. 扫描子网 (优先 IP + 完整扫描)
  3. 对每个 IP 进行验证

### 2. 打印机验证 (Printer Verification)

系统使用多层验证确保打印机兼容性：

#### A. 端口 9100 连接测试
- **文件位置**: `lib/services/printer_service.dart`
- **方法**: `_checkPrinterAtAddressInternal()`
- **行号**: 229-248
- **验证内容**: 检查打印机是否在端口 9100 上监听（Brother 打印机标准端口）

#### B. DNS 主机名验证
- **方法**: `_checkPrinterAtAddressInternal()`
- **行号**: 251-269
- **验证内容**: 检查主机名是否以 `BRN` 或 `BRW` 开头（Brother 命名模式）

#### C. HTTP 信息页面解析
- **方法**: `_queryPrinterModelViaHTTP()`
- **行号**: 390-462
- **验证内容**:
  - 访问 `http://<IP>/general/information.html`
  - 解析型号、制造商、序列号
  - 验证是否为 Brother 品牌
  - 验证型号是否支持（QL-820NWB / QL-720NW）

#### D. Brother SDK 状态验证
- **方法**: `_verifyViaBrotherSDK()`
- **行号**: 320-361
- **验证内容**:
  ```dart
  final testPrinter = printer.Printer();
  printer.Printer.setUserPrinterInfo(testPrinterInfo);
  final status = await testPrinter.getPrinterStatus();
  ```
- **接受的状态**:
  - `ERROR_NONE`: 打印机正常
  - `COVER_OPEN`: 打印机盖子打开（打印机存在但未就绪）
  - `PAPER_*`: 纸张相关错误（打印机存在但缺纸）

### 3. 手动添加打印机

用户可以手动输入 IP 地址添加打印机：

- **文件位置**: `lib/services/printer_service.dart`
- **方法**: `addManualPrinter()`
- **行号**: 503-593
- **UI 位置**: Dashboard → Printer Status Card → "Manual IP" 按钮
- **验证步骤**:
  1. IP 地址格式验证
  2. 端口 9100 连接测试
  3. HTTP 信息验证
  4. SDK 状态验证

---

## 配置流程

### 阶段 1: Dashboard 初始化

```
用户打开 Dashboard
  ↓
DashboardController.initState()
  ↓
initializePrinter() [延迟 3 秒启动]
  ↓
tryConnectToSavedPrinter()  // 尝试快速重连上次使用的打印机
  ↓
[如果失败] discoverPrinters()  // 扫描网络寻找新打印机
```

**相关文件**:
- `lib/features/dashboard/views/dashboard_page.dart` (行 69-113)
- `lib/features/dashboard/controllers/dashboard_controller.dart`
- `lib/services/printer_service.dart`

### 阶段 2: 打印机选择和保存

```
打印机被发现
  ↓
selectPrinter(discoveredPrinter)
  ↓
_saveDiscoveredPrinter()  // 保存到 Secure Storage
  ↓
SecureStorageService.saveLastPrinter()
```

**保存的信息** (`lib/services/secure_storage_service.dart`):
```dart
{
  'name': 'Brother QL-820NWB at 192.168.1.191',
  'address': '192.168.1.191',
  'model': 'QL-820NWB'
}
```

**Storage Key**: `'lastPrinter'`

### 阶段 3: 纸张类型配置

用户在 Dashboard 选择纸张类型：

```
用户选择纸张类型 (Dropdown)
  ↓
_savePaperType(paperType)
  ↓
SecureStorageService.savePaperType(jsonEncode(paperType.toJson()))
```

**保存的信息** (`lib/core/models/paper_type.dart`):
```dart
{
  'labelNameIndex': 17,
  'name': '62mm Continuous (Black/White)',
  'description': 'Continuous length tape',
  'dimensions': '62mm width',
  'isContinuous': true,
  'isSpecialTape': false  // false = Black/White, true = Red/Black
}
```

**Storage Key**: `'paperType'`

**UI 位置**: `lib/widgets/dashboard_custom_widgets.dart` (行 429-550)

---

## 数据流图

### 打印机发现和配置流程

```
┌─────────────────────────────────────────────────────┐
│                  Dashboard Page                      │
│  lib/features/dashboard/views/dashboard_page.dart   │
└─────────────────┬───────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────┐
│              DashboardController                     │
│  lib/features/dashboard/controllers/                │
│          dashboard_controller.dart                   │
│                                                      │
│  • printVisitorBadge: bool                          │
│  • initialized: bool                                │
│  • printerName: string                              │
│  • printerIp: string                                │
└─────────────────┬───────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────┐
│               PrinterService                         │
│  lib/services/printer_service.dart                  │
│                                                      │
│  Methods:                                           │
│  • discoverPrinters()          [行 39-83]          │
│  • _scanNetworkWithBrotherSDK() [行 86-136]        │
│  • _scanNetworkManually()       [行 139-183]       │
│  • addManualPrinter()           [行 503-593]       │
│  • selectPrinter()              [行 496-500]       │
│  • printImage()                 [行 715-746]       │
└─────────────────┬───────────────────────────────────┘
                  │
          ┌───────┴───────┐
          │               │
          ▼               ▼
┌──────────────────┐  ┌─────────────────────────┐
│ Brother SDK      │  │  SecureStorageService   │
│ another_brother  │  │  lib/services/          │
│                  │  │  secure_storage_        │
│ • getNetPrinters │  │  service.dart           │
│ • printImage     │  │                         │
│ • getPrinterStatus│  │ • saveLastPrinter()    │
└──────────────────┘  │ • getLastPrinter()     │
                      │ • savePaperType()      │
                      │ • getPaperType()       │
                      └────────────────────────┘
```

### 打印流程

```
┌─────────────────────────────────────────────────────┐
│          Visitor Sign In Complete                    │
│  lib/features/visitor_sign_in/views/                │
│       visitor_sign_in_page.dart                      │
│                                                      │
│  _BadgePreviewPage                                  │
│   ↓                                                  │
│  _autoPrintBadge()  [行 1198-1229]                 │
└─────────────────┬───────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────┐
│  DashboardController.printerService.printImage()    │
│                                                      │
│  Parameters:                                         │
│  • image: ui.Image (徽章图像)                       │
│  • onStatusUpdate: callback (状态更新回调)         │
└─────────────────┬───────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────┐
│         PrinterService._printMobile()                │
│  lib/services/printer_service.dart [行 749-823]    │
│                                                      │
│  Steps:                                             │
│  1. 发送状态: Connecting                            │
│  2. 从 Storage 加载纸张类型                         │
│  3. 配置打印机参数:                                  │
│     • paperSize: CUSTOM                             │
│     • orientation: PORTRAIT                         │
│     • isAutoCut: true                               │
│     • labelNameIndex: (从纸张类型)                  │
│     • isSpecialTape: (Black/White or Red/Black)    │
│  4. 发送状态: Sending                               │
│  5. 调用 Brother SDK                                │
│  6. 发送状态: Printing                              │
│  7. 发送状态: Completed / Failed                    │
└─────────────────┬───────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────┐
│            Brother Printer                           │
│         (QL-820NWB / QL-720NW)                      │
│                                                      │
│  • Receives print job via network (port 9100)      │
│  • Prints badge on selected paper type             │
│  • Returns success/error code                       │
└─────────────────────────────────────────────────────┘
```

---

## 纸张类型配置

### 支持的纸张类型

定义在 `lib/core/models/paper_type.dart`:

#### 黑白纸张 (Black/White)
| labelNameIndex | 名称 | 描述 | 尺寸 |
|----------------|------|------|------|
| 17 | 62mm Continuous | 连续长度胶带 | 62mm 宽 |
| 4 | 62mm x 100mm | 预裁标签 | 62mm x 100mm |
| 5 | 29mm x 90mm | 地址标签 | 29mm x 90mm |
| 8 | 62mm x 29mm | 小标签 | 62mm x 29mm |
| 15 | 29mm Continuous | 窄连续胶带 | 29mm 宽 |

#### 红黑纸张 (Red/Black)
| labelNameIndex | 名称 | 描述 | 尺寸 |
|----------------|------|------|------|
| 17 | 62mm Continuous | 双色连续胶带 | 62mm 宽 |
| 4 | 62mm x 100mm | 双色预裁标签 | 62mm x 100mm |
| 5 | 29mm x 90mm | 双色地址标签 | 29mm x 90mm |
| 8 | 62mm x 29mm | 双色小标签 | 62mm x 29mm |
| 15 | 29mm Continuous | 双色窄胶带 | 29mm 宽 |

**注意**: 红黑纸张与黑白纸张使用相同的 `labelNameIndex`，通过 `isSpecialTape` 标志区分。

### 纸张类型选择流程

1. **仅在打印机连接后显示**: Dashboard 的纸张选择器只在 `controller.initialized == true` 时显示
2. **自动保存**: 用户选择后立即保存到 Secure Storage
3. **自动加载**: 页面初始化时自动加载上次选择
4. **打印时应用**: 打印时自动读取并应用保存的纸张类型

**相关代码**:
- UI: `lib/widgets/dashboard_custom_widgets.dart` (行 429-551)
- 加载: `_loadSavedPaperType()` (行 78-99)
- 保存: `_savePaperType()` (行 102-117)
- 应用: `printer_service.dart` → `_printMobile()` (行 770-781)

---

## 打印状态跟踪

### 打印状态枚举

定义在 `lib/core/models/print_status.dart`:

```dart
enum PrintStatus {
  idle,        // 空闲
  connecting,  // 连接中
  sending,     // 发送打印任务
  receiving,   // 等待响应
  queued,      // 排队中
  printing,    // 打印中
  completed,   // 完成
  failed,      // 失败
}
```

### 状态更新流程

```
1. idle → connecting
   └─ PrinterService: 建立与打印机的连接

2. connecting → sending
   └─ PrinterService: 开始发送打印数据

3. sending → printing
   └─ PrinterService: 数据已发送，打印机开始打印

4. printing → completed / failed
   └─ PrinterService: 打印完成或出错
```

### 状态显示组件

定义在 `lib/widgets/print_progress_widget.dart`:

#### A. PrintProgressWidget
- **用途**: 完整的打印进度卡片
- **显示内容**:
  - 状态图标和文本
  - 详细消息
  - 队列位置（如果排队）
  - 加载动画（进行中时）

#### B. PrintProgressCompact
- **用途**: 紧凑的单行进度显示
- **显示内容**: 图标 + 状态文本

#### C. PrintProgressTimeline
- **用途**: 时间线式进度显示
- **显示内容**: 步骤列表，当前步骤高亮

### Kiosk 集成

**文件**: `lib/features/visitor_sign_in/views/visitor_sign_in_page.dart`

**关键功能**:
1. **状态追踪** (行 1188): `PrintProgress _printProgress`
2. **状态更新回调** (行 1207-1213):
   ```dart
   onStatusUpdate: (progress) {
     setState(() {
       _printProgress = progress;
     });
   }
   ```
3. **UI 显示** (行 1380-1388): `PrintProgressWidget`
4. **阻止提前退出** (行 1272-1290): `PopScope` - 打印中时禁用返回按钮
5. **按钮禁用** (行 1394-1396): 打印中时"Return to Kiosk"按钮禁用

---

## 故障排除

### 常见问题

#### 1. 打印机未被发现

**可能原因**:
- 打印机未开机
- 打印机与设备不在同一 WiFi 网络
- 网络防火墙阻止设备通信
- 打印机 IP 地址已更改

**解决方案**:
1. 检查打印机电源和网络连接
2. 确认打印机和设备在同一子网
3. 使用 "Manual IP" 功能手动添加
4. 检查路由器是否允许设备间通信

#### 2. 打印失败

**可能原因**:
- 纸张类型配置错误
- 打印机缺纸
- 打印机盖子打开
- 网络连接中断

**解决方案**:
1. 检查 Dashboard 中的纸张类型设置
2. 检查打印机物理状态（纸张、盖子）
3. 重试打印
4. 重启打印机

#### 3. 纸张类型不匹配

**症状**: 打印输出质量差或打印机报错

**解决方案**:
1. 在 Dashboard → Printer Status → Paper Type 中选择正确的纸张类型
2. 确认 `isSpecialTape` 设置（Black/White vs Red/Black）
3. 确认纸张尺寸与实际安装的纸张匹配

#### 4. 无法退出打印页面

**正常行为**: 这是设计功能！

打印过程中，系统会：
- 禁用"Return to Kiosk"按钮
- 阻止后退按钮
- 显示警告消息

**等待**: 打印完成后（状态变为 `completed`），按钮会自动启用，或 5 秒后自动返回。

---

## 技术规格

### Brother Printer SDK

**包**: `another_brother` v2.2.4
**文档**: https://pub.dev/packages/another_brother

**关键类和枚举**:
- `Printer`: 打印机实例
- `PrinterInfo`: 打印机配置
- `Model`: 打印机型号枚举（QL_820NWB, QL_720NW）
- `Port.NET`: 网络端口
- `PaperSize.CUSTOM`: 自定义纸张大小
- `Orientation.PORTRAIT`: 纵向打印
- `PrintMode.FIT_TO_PAGE`: 适应页面模式
- `Halftone.ERRORDIFFUSION`: 半色调模式
- `ErrorCode`: 错误代码枚举

### Secure Storage

**包**: `flutter_secure_storage` v10.0.0

**存储位置**:
- iOS: Keychain
- Android: Keystore

**相关 Keys**:
- `'lastPrinter'`: 上次使用的打印机信息
- `'paperType'`: 纸张类型配置

---

## 相关文件清单

### 核心服务
- `lib/services/printer_service.dart` - 打印机服务（814 行）
- `lib/services/badge_generator.dart` - 徽章生成服务
- `lib/services/secure_storage_service.dart` - 安全存储服务（657 行）

### 模型
- `lib/core/models/paper_type.dart` - 纸张类型模型（176 行）
- `lib/core/models/print_status.dart` - 打印状态模型

### UI 组件
- `lib/widgets/dashboard_custom_widgets.dart` - Dashboard 自定义组件（878 行）
  - `PrintStatusCard` - 打印机状态卡片
- `lib/widgets/print_progress_widget.dart` - 打印进度组件
  - `PrintProgressWidget` - 完整进度卡片
  - `PrintProgressCompact` - 紧凑进度显示
  - `PrintProgressTimeline` - 时间线进度显示

### 页面
- `lib/features/dashboard/views/dashboard_page.dart` - Dashboard 页面（824 行）
- `lib/features/dashboard/controllers/dashboard_controller.dart` - Dashboard 控制器（469 行）
- `lib/features/visitor_sign_in/views/visitor_sign_in_page.dart` - 访客签到页面
  - `_BadgePreviewPage` - 徽章预览和打印状态页面

---

## 更新历史

### 2026-01-03
- ✅ 添加打印状态追踪系统
- ✅ 创建打印进度显示组件
- ✅ 集成到 Kiosk 成功页面
- ✅ 添加打印中页面退出阻止功能
- ✅ 修改 Dashboard 纸张选择显示逻辑（仅在连接后显示）
- ✅ 编写完整的打印机配置文档

### 之前版本
- ✅ 纸张类型选择功能
- ✅ 自动打印徽章功能
- ✅ 打印机网络发现功能
- ✅ Secure Storage 持久化

---

## 联系和支持

如有技术问题，请参考：
- Brother SDK 文档: https://pub.dev/packages/another_brother
- Flutter 文档: https://flutter.dev
- 项目 GitHub: (添加您的项目链接)

---

**文档版本**: 1.0
**最后更新**: 2026-01-03
**作者**: Claude + Development Team
