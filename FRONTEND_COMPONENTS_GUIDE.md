# Worx Visitor Management - Frontend Components Guide
# Worx访客管理系统 - 前端组件指南

## 📚 Table of Contents / 目录

1. [Core Components / 核心组件](#core-components)
2. [Custom Widgets / 自定义组件](#custom-widgets)
3. [Services / 服务层](#services)
4. [Page Templates / 页面模板](#page-templates)
5. [State Management / 状态管理](#state-management)
6. [Best Practices / 最佳实践](#best-practices)

---

## 🧩 Core Components / 核心组件

### 1. KioskBody Widget

**Purpose / 用途**: Universal container for all kiosk pages providing consistent layout with header logos and footer.
**用途**: 为所有kiosk页面提供统一布局的通用容器，包含头部logo和底部。

**Location / 位置**: `lib/widgets/kiosk_body.dart`

**Key Features / 主要特性**:
- ✅ Displays client and Worx logos / 显示客户和Worx的logo
- ✅ Shows site title / 显示站点标题
- ✅ Optional supervisor name display / 可选的主管名称显示
- ✅ Optional printer ready indicator / 可选的打印机就绪指示器
- ✅ Customizable footer action button / 可自定义底部操作按钮

**Usage Example / 使用示例**:

```dart
KioskBody(
  siteTitle: 'Visitor Sign In',                    // Page title / 页面标题
  supervisorName: 'John Smith',                     // Optional / 可选
  printerReady: true,                               // Printer status / 打印机状态
  logo1Bytes: logoBytes,                            // Client logo / 客户logo
  logo1Url: 'path/to/logo.svg',                     // Alternative logo path / 备用logo路径
  logo2Url: 'lib/assets/images/Worx_PoweredBy_Logo_Mono.svg',  // Worx logo
  footerAction: IconButton(                         // Footer button / 底部按钮
    icon: const Icon(Icons.admin_panel_settings),
    onPressed: () => _handleAdminSignIn(context),
  ),
  menuContent: YourContentWidget(),                 // Main content / 主要内容
)
```

**Visual Structure / 视觉结构**:
```
┌─────────────────────────────┐
│      [Client Logo]          │  Header / 头部
│    [Worx Powered By]        │
│      Site Title             │
│    Supervisor: John         │
│    Printer: ✓ Ready         │
├─────────────────────────────┤
│                             │
│     Menu Content            │  Main Content / 主要内容
│     (Your Widget)           │
│                             │
├─────────────────────────────┤
│    [Footer Action]          │  Footer / 底部
└─────────────────────────────┘
```

---

### 2. KioskGuard Widget

**Purpose / 用途**: Prevents users from exiting kiosk mode using system gestures.
**用途**: 防止用户使用系统手势退出kiosk模式。

**Location / 位置**: `lib/widgets/kiosk_guard.dart`

**Key Features / 主要特性**:
- 🔒 Disables back gesture / 禁用返回手势
- 🔒 Prevents system navigation / 阻止系统导航
- 🔒 Shows warning on exit attempt / 尝试退出时显示警告

**Usage Example / 使用示例**:

```dart
// Wrap your entire page scaffold / 包裹整个页面scaffold
return KioskGuard(
  child: Scaffold(
    body: YourPageContent(),
  ),
);
```

**Implementation Pattern / 实现模式**:
```dart
// ❌ WRONG - Guard inside Scaffold / 错误 - Guard在Scaffold内部
Scaffold(
  body: KioskGuard(
    child: Content(),
  ),
)

// ✅ CORRECT - Guard wraps Scaffold / 正确 - Guard包裹Scaffold
KioskGuard(
  child: Scaffold(
    body: Content(),
  ),
)
```

---

### 3. KioskField Widget

**Purpose / 用途**: Customized text input field with consistent styling for kiosk forms.
**用途**: 为kiosk表单提供统一样式的自定义文本输入字段。

**Location / 位置**: `lib/widgets/kiosk_field.dart`

**Key Features / 主要特性**:
- 📝 Consistent styling across all forms / 所有表单样式一致
- 📝 Built-in validation support / 内置验证支持
- 📝 Required field indicator / 必填字段指示器
- 📝 Autofill hints support / 自动填充提示支持

**Usage Example / 使用示例**:

```dart
KioskField(
  controller: _nameCtrl,
  title: 'Full Name',                    // Field label / 字段标签
  required: true,                        // Show asterisk / 显示星号
  autofill: const [AutofillHints.name], // Autofill hints / 自动填充提示
  keyboardType: TextInputType.name,     // Keyboard type / 键盘类型
  validator: (value) {                  // Validation / 验证
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }
    return null;
  },
  onChanged: (value) {                  // On change callback / 变更回调
    print('Name changed to: $value');
  },
)
```

**Common Field Types / 常见字段类型**:

```dart
// Email field / 邮箱字段
KioskField(
  controller: _emailCtrl,
  title: 'Email Address',
  required: true,
  keyboardType: TextInputType.emailAddress,
  autofill: const [AutofillHints.email],
  validator: (v) {
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v ?? '')) {
      return 'Enter a valid email';
    }
    return null;
  },
)

// Phone field / 电话字段
KioskField(
  controller: _phoneCtrl,
  title: 'Phone Number',
  keyboardType: TextInputType.phone,
  autofill: const [AutofillHints.telephoneNumber],
)

// Read-only field / 只读字段
TextField(
  controller: _visitorIdCtrl,
  readOnly: true,
  decoration: InputDecoration(
    hintText: 'Click "Search" to select',
    filled: true,
    fillColor: Colors.grey.shade100,
  ),
)
```

---

### 4. PrintProgressWidget

**Purpose / 用途**: Displays real-time printing progress and status messages.
**用途**: 显示实时打印进度和状态消息。

**Location / 位置**: `lib/widgets/print_progress_widget.dart`

**Key Features / 主要特性**:
- 🖨️ Real-time status updates / 实时状态更新
- 🖨️ Color-coded progress indicators / 彩色进度指示器
- 🖨️ Error message display / 错误消息显示
- 🖨️ Optional icon and timestamp / 可选图标和时间戳

**Usage Example / 使用示例**:

```dart
class _YourPageState extends State<YourPage> {
  PrintProgress _printProgress = PrintProgress.idle();

  Future<void> _printBadge() async {
    final success = await printerService.printImage(
      badgeImage,
      onStatusUpdate: (progress) {
        if (mounted) {
          setState(() {
            _printProgress = progress;  // Update progress / 更新进度
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Your content / 你的内容

        // Show progress widget / 显示进度组件
        if (_printProgress.status != PrintStatus.idle) ...[
          PrintProgressWidget(
            progress: _printProgress,
            showIcon: true,            // Show status icon / 显示状态图标
            showTimestamp: false,      // Hide timestamp / 隐藏时间戳
          ),
        ],
      ],
    );
  }
}
```

**Status Colors / 状态颜色**:
- 🟢 **Completed / 完成** - Green background
- 🔵 **In Progress / 进行中** - Blue background
- 🔴 **Failed / 失败** - Red background
- ⚪ **Idle / 空闲** - Gray background

---

### 5. QRScannerWidget

**Purpose / 用途**: Camera-based QR code scanner for visitor badge scanning.
**用途**: 基于摄像头的QR码扫描器，用于扫描访客徽章。

**Location / 位置**: `lib/widgets/qr_scanner_widget.dart`

**Key Features / 主要特性**:
- 📷 Front camera by default / 默认前置摄像头
- 📷 Camera switching / 摄像头切换
- 📷 Torch/flashlight toggle / 手电筒开关
- 📷 Automatic QR detection / 自动QR检测

**Usage Example / 使用示例**:

```dart
// Open scanner and get result / 打开扫描器获取结果
final String? qrCode = await Navigator.push<String>(
  context,
  MaterialPageRoute(
    builder: (_) => const QRScannerWidget(),
  ),
);

if (qrCode != null && qrCode.isNotEmpty) {
  // Process the scanned QR code / 处理扫描的QR码
  print('Scanned QR Code: $qrCode');
  _visitorIdCtrl.text = qrCode;
}
```

**Scanner Configuration / 扫描器配置**:
```dart
// In qr_scanner_widget.dart
final MobileScannerController _controller = MobileScannerController(
  detectionSpeed: DetectionSpeed.noDuplicates,  // No duplicate scans / 无重复扫描
  formats: const [BarcodeFormat.qrCode],        // Only QR codes / 仅QR码
  facing: CameraFacing.front,                   // Front camera / 前置摄像头
);
```

---

## 🎨 Custom Widgets / 自定义组件

### 6. Contact Selector Dialog

**Purpose / 用途**: Searchable dialog for selecting a supervisor/contact from a list.
**用途**: 可搜索的对话框，用于从列表中选择主管/联系人。

**Location / 位置**: Embedded in `lib/features/visitor_sign_in/views/visitor_sign_in_page.dart`

**Usage Example / 使用示例**:

```dart
// Show dialog and get selected contact / 显示对话框并获取选中的联系人
final selected = await showDialog<ContactDetail>(
  context: context,
  builder: (context) => _ContactSelectorDialog(
    contacts: availableSupervisors,
    currentSelection: _selectedContactDetail,
  ),
);

if (selected != null) {
  setState(() {
    _selectedContactDetail = selected;
  });
}
```

**Features / 特性**:
- 🔍 Real-time search filtering / 实时搜索过滤
- 🔍 Search by name or email / 按姓名或邮箱搜索
- 🔍 Shows contact count / 显示联系人数量
- 🔍 Visual selection indicator / 可视化选择指示器

---

### 7. Badge Preview Component

**Purpose / 用途**: Preview generated visitor badge before/during printing.
**用途**: 在打印前/打印期间预览生成的访客徽章。

**Usage Example / 使用示例**:

```dart
// Generate badge image / 生成徽章图像
final ui.Image badgeImage = await BadgeGenerator.generateBadgeImage(
  BadgeData(
    visitorId: 'VIS123',
    fullName: 'John Smith',
    email: 'john@example.com',
    phone: '+61 412 345 678',
    company: 'ABC Corp',
    siteName: 'Main Office',
    clientLogoBytes: logoBytes,
    visitorPhotoBytes: photoBytes,  // Will show "Photo Uploaded" / 会显示"Photo Uploaded"
  ),
);

// Convert to bytes for preview / 转换为字节用于预览
final byteData = await badgeImage.toByteData(format: ui.ImageByteFormat.png);
final badgeBytes = byteData!.buffer.asUint8List();

// Display in UI / 在UI中显示
Container(
  constraints: const BoxConstraints(maxHeight: 400),
  child: Image.memory(badgeBytes, fit: BoxFit.contain),
)
```

**Badge Data Fields / 徽章数据字段**:
```dart
class BadgeData {
  final String visitorId;           // Required / 必需 - QR code data
  final String? fullName;           // Optional / 可选
  final String? email;              // Optional / 可选
  final String? phone;              // Optional / 可选
  final String? workType;           // Optional / 可选
  final String? company;            // Optional / 可选
  final String? address;            // Optional / 可选
  final String? supervisor;         // Optional / 可选
  final String? signInTime;         // Optional / 可选
  final String siteName;            // Required / 必需
  final Uint8List? clientLogoBytes; // Optional / 可选 - Custom logo
  final String? clientLogoUrl;      // Optional / 可选 - Logo URL
  final Uint8List? visitorPhotoBytes; // Optional / 可选 - Shows "Photo Uploaded"
}
```

---

## 🔧 Services / 服务层

### 8. ApiService

**Purpose / 用途**: Centralized API communication service for all HTTP requests.
**用途**: 集中式API通信服务，处理所有HTTP请求。

**Location / 位置**: `lib/services/api_service.dart`

**Key Methods / 主要方法**:

#### Submit Sign In Ledger / 提交签到记录
```dart
final response = await ApiService.submitSignInLedger(
  token: authToken,
  siteId: 'SITE123',
  name: 'John Smith',
  email: 'john@example.com',
  questions: {'agree_terms': true, 'agree_safety': true},
  uniqueId: '',  // Server generates / 服务器生成
  // Optional fields / 可选字段
  organisation: 'ABC Corp',
  phone: '+61 412 345 678',
  address: '123 Main St',
  workType: 'Contractor',
  supervisor: 'Jane Doe',
  signInTime: '2026-01-08 14:30',
  visitorPhotos: {
    'VIS123': 'base64_encoded_photo_string',  // ID as key / ID作为键
  },
);

// Response / 响应
// {
//   "message": "Login Complete",
//   "visitor_id": "VIS123456",
//   "unique_id": "VIS123456"
// }
```

#### Fetch Site Questions / 获取站点问题
```dart
final questions = await ApiService.fetchSiteQuestions(token, siteId);
// Returns / 返回: List of custom site induction questions
```

#### Submit Sign Out / 提交签出
```dart
await ApiService.submitSignOut(
  token: authToken,
  visitorId: 'VIS123',
  signOutTime: '2026-01-08 17:30',
);
```

---

### 9. SecureStorageService

**Purpose / 用途**: Encrypted local storage for sensitive data.
**用途**: 敏感数据的加密本地存储。

**Location / 位置**: `lib/services/secure_storage_service.dart`

**Key Methods / 主要方法**:

```dart
// Authentication / 身份验证
await SecureStorageService.saveAuthToken('token_here');
final token = await SecureStorageService.getAuthToken();

// Client configuration / 客户配置
await SecureStorageService.saveClient(jsonEncode(clientData));
final clientJson = await SecureStorageService.getClient();

// Selected site / 选中的站点
await SecureStorageService.saveSelectedSite(jsonEncode(siteData));
final siteJson = await SecureStorageService.getSelectedSite();

// Admin PIN / 管理员PIN
await SecureStorageService.saveAdminPin('1234');
final pin = await SecureStorageService.getAdminPin();

// Signed visitors / 已签到访客
await SecureStorageService.addSignedVisitor(
  visitorId: 'VIS123',
  email: 'john@example.com',
  fullName: 'John Smith',
  supervisorId: 'SUP456',
  supervisorName: 'Jane Doe',
  supervisorEmail: 'jane@example.com',
  supervisorPhone: '+61 400 123 456',
);

final visitors = await SecureStorageService.getSignedVisitors();
await SecureStorageService.removeSignedVisitor('VIS123');
```

---

### 10. PrinterService

**Purpose / 用途**: Brother printer integration for badge printing.
**用途**: Brother打印机集成，用于徽章打印。

**Location / 位置**: `lib/services/printer_service.dart`

**Key Methods / 主要方法**:

```dart
// Initialize printer / 初始化打印机
final printerService = PrinterService();
await printerService.initialize(
  modelName: 'QL-820NWB',
  networkAddress: '192.168.1.100',
);

// Print badge image / 打印徽章图像
final success = await printerService.printImage(
  badgeImage,  // ui.Image object
  onStatusUpdate: (PrintProgress progress) {
    print('Status: ${progress.status}');
    print('Message: ${progress.message}');
  },
);

// Print test label / 打印测试标签
await printerService.printTestLabel();

// Disconnect / 断开连接
await printerService.disconnect();
```

---

### 11. BadgeGenerator

**Purpose / 用途**: Generate visitor badge images with QR codes and visitor information.
**用途**: 生成包含QR码和访客信息的访客徽章图像。

**Location / 位置**: `lib/services/badge_generator.dart`

**Usage Example / 使用示例**:

```dart
// Generate badge as ui.Image (for printing) / 生成为ui.Image（用于打印）
final ui.Image badgeImage = await BadgeGenerator.generateBadgeImage(
  BadgeData(
    visitorId: 'VIS123',
    fullName: 'John Smith',
    email: 'john@example.com',
    siteName: 'Main Office',
    visitorPhotoBytes: photoBytes,  // Shows "Photo Uploaded" on badge
  ),
);

// Generate badge as bytes (for preview) / 生成为字节（用于预览）
final Uint8List badgeBytes = await BadgeGenerator.generateBadgeBytes(badgeData);

// Display in widget / 在组件中显示
Image.memory(badgeBytes)
```

---

### 12. NotificationService

**Purpose / 用途**: Send SMS and email notifications to supervisors.
**用途**: 向主管发送短信和邮件通知。

**Location / 位置**: `lib/services/notification_service.dart`

**Usage Example / 使用示例**:

```dart
// Send SMS notification / 发送短信通知
final smsSuccess = await NotificationService.sendTextMessage(
  userId: contactId,
  mobile: '+61 412 345 678',
  message: 'John Smith from ABC Corp has arrived to see you.',
);

// Send email notification / 发送邮件通知
final emailSuccess = await NotificationService.sendEmail(
  userId: contactId,
  name: 'John Smith',
  email: 'supervisor@example.com',
  phone: '+61 412 345 678',
  message: 'Visitor arrival notification...',
  logoUrl: 'https://example.com/logo.png',
);

// Build visitor sign-in message / 构建访客签到消息
final message = NotificationService.buildVisitorSignInMessage(
  siteName: 'Main Office',
  visitorName: 'John Smith',
  company: 'ABC Corp',
  phoneNumber: '+61 412 345 678',
  workType: 'Contractor',
);
```

---

## 📄 Page Templates / 页面模板

### Template 1: Visitor Sign In Page

**Purpose / 用途**: Main visitor registration page with form validation and badge printing.
**用途**: 主访客登记页面，包含表单验证和徽章打印。

**Location / 位置**: `lib/features/visitor_sign_in/views/visitor_sign_in_page.dart`

**Page Flow / 页面流程**:
```
1. User fills form / 用户填写表单
   ↓
2. Form validation / 表单验证
   ↓
3. Site questions page / 站点问题页面
   ↓
4. Submit to API / 提交到API
   ↓
5. Send notifications / 发送通知
   ↓
6. Generate badge / 生成徽章
   ↓
7. Badge preview & print / 徽章预览和打印
   ↓
8. Return to kiosk / 返回kiosk
```

**Code Structure / 代码结构**:
```dart
class VisitorSignInPage extends StatefulWidget {
  @override
  State<VisitorSignInPage> createState() => _VisitorSignInPageState();
}

class _VisitorSignInPageState extends State<VisitorSignInPage> {
  // Form controllers / 表单控制器
  final _formKey = GlobalKey<FormState>();
  final _fullNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  // State variables / 状态变量
  ContactDetail? _selectedContactDetail;
  Uint8List? _visitorPhotoBytes;
  bool _submitting = false;

  @override
  Widget build(BuildContext context) {
    return KioskGuard(
      child: Scaffold(
        body: Container(
          // Background image if configured / 背景图片（如果配置）
          decoration: useCustomBackground ? BackgroundDecoration() : null,
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 720),
              child: KioskBody(
                siteTitle: 'Visitor Sign In',
                menuContent: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Form fields based on dashboard config
                      // 根据dashboard配置的表单字段
                      if (showFullName) KioskField(...),
                      if (showEmail) KioskField(...),
                      if (showPhone) KioskField(...),

                      // Contact selector / 联系人选择器
                      if (showContactDetail) ContactSelectorWidget(...),

                      // Visitor photo section / 访客照片部分
                      if (reqVisitorPhoto) PhotoCaptureSection(...),

                      // Submit button / 提交按钮
                      FilledButton(
                        onPressed: _submitting ? null : _onSubmit,
                        child: Text('Next'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onSubmit() async {
    // 1. Validate form / 验证表单
    if (!_formKey.currentState!.validate()) return;

    // 2. Check required photo / 检查必需的照片
    if (reqVisitorPhoto && _visitorPhotoBytes == null) {
      showSnackBar('Photo required');
      return;
    }

    // 3. Show site questions / 显示站点问题
    final answers = await Navigator.push(...SiteQuestionsPage);
    if (answers == null) return;

    // 4. Submit to API / 提交到API
    final response = await ApiService.submitSignInLedger(...);
    final visitorId = response['visitor_id'];

    // 5. Send notifications / 发送通知
    await _sendNotifications();

    // 6. Generate badge / 生成徽章
    final badgeImage = await BadgeGenerator.generateBadgeImage(...);

    // 7. Navigate to preview / 导航到预览
    Navigator.push(...BadgePreviewPage);
  }
}
```

---

### Template 2: Visitor Sign Out Page

**Purpose / 用途**: Quick visitor sign-out with QR scanning or manual search.
**用途**: 快速访客签出，支持QR扫描或手动搜索。

**Location / 位置**: `lib/features/visitor_sign_out/views/visitor_sign_out_page.dart`

**Key Features / 主要特性**:
- 📷 QR code scanning / QR码扫描
- 🔍 Manual visitor search / 手动访客搜索
- 📋 Visitor list with search filter / 可搜索的访客列表
- ✅ One-click sign out / 一键签出

**Code Pattern / 代码模式**:
```dart
// Scan QR code / 扫描QR码
Future<void> _scanQRCode() async {
  final qrCode = await Navigator.push<String>(
    context,
    MaterialPageRoute(builder: (_) => const QRScannerWidget()),
  );

  if (qrCode != null) {
    _visitorIdCtrl.text = qrCode;
    await _signOutVisitor(qrCode);
  }
}

// Search visitor / 搜索访客
Future<void> _showVisitorsList() async {
  final selected = await showDialog<SignedVisitor>(
    context: context,
    builder: (context) => _SearchableVisitorDialog(
      visitors: _signedInVisitors,
    ),
  );

  if (selected != null) {
    await _signOutVisitor(selected.id);
  }
}

// Sign out / 签出
Future<void> _signOutVisitor(String visitorId) async {
  await ApiService.submitSignOut(
    token: authToken,
    visitorId: visitorId,
    signOutTime: currentTime,
  );

  // Remove from local storage / 从本地存储移除
  await SecureStorageService.removeSignedVisitor(visitorId);

  showSnackBar('Signed out successfully');
}
```

---

### Template 3: Reprint Badge Page

**Purpose / 用途**: Reprint visitor badges for already signed-in visitors.
**用途**: 为已签到的访客重新打印徽章。

**Location / 位置**: `lib/features/reprint_badge/views/reprint_badge_page.dart`

**Key Features / 主要特性**:
- 🔍 Search signed-in visitors / 搜索已签到访客
- 👁️ Badge preview / 徽章预览
- 🖨️ Print with progress tracking / 带进度跟踪的打印
- ⚙️ Respects dashboard field settings / 遵循dashboard字段设置

**Code Pattern / 代码模式**:
```dart
class _ReprintBadgePageState extends State<ReprintBadgePage> {
  ui.Image? _badgeImage;
  Uint8List? _badgeImageBytes;
  PrintProgress _printProgress = PrintProgress.idle();

  Future<void> _loadVisitorBadge(_SignedVisitor visitor) async {
    final controller = DashboardController.instance;

    // Respect dashboard settings / 遵循dashboard设置
    final badgeData = BadgeData(
      visitorId: visitor.id,
      fullName: (controller?.reqFullName ?? true) && visitor.fullName.isNotEmpty
          ? visitor.fullName
          : null,
      email: (controller?.reqEmail ?? true) && visitor.email.isNotEmpty
          ? visitor.email
          : null,
      // ... other fields
    );

    // Generate badge / 生成徽章
    final badgeImage = await BadgeGenerator.generateBadgeImage(badgeData);
    final byteData = await badgeImage.toByteData(format: ui.ImageByteFormat.png);

    setState(() {
      _badgeImage = badgeImage;
      _badgeImageBytes = byteData!.buffer.asUint8List();
    });
  }

  Future<void> _printBadge() async {
    setState(() => _isPrinting = true);

    final success = await controller.printerService.printImage(
      _badgeImage!,
      onStatusUpdate: (progress) {
        if (mounted) {
          setState(() => _printProgress = progress);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search button / 搜索按钮
        FilledButton(
          onPressed: _showSignedInVisitorsList,
          child: Text('Search Visitor'),
        ),

        // Badge preview / 徽章预览
        if (_badgeImageBytes != null)
          Image.memory(_badgeImageBytes!),

        // Print progress / 打印进度
        if (_printProgress.status != PrintStatus.idle)
          PrintProgressWidget(progress: _printProgress),

        // Print button / 打印按钮
        FilledButton(
          onPressed: _badgeImage != null ? _printBadge : null,
          child: Text('Print Badge'),
        ),
      ],
    );
  }
}
```

---

### Template 4: Contractor Sign In Page

**Purpose / 用途**: Quick contractor sign-in using QR code scanning.
**用途**: 使用QR码扫描快速签到承包商。

**Location / 位置**: `lib/features/contractor_sign_in/views/contractor_sign_in_page.dart`

**Code Pattern / 代码模式**:
```dart
Future<void> _scanContractorQR() async {
  final qrCode = await Navigator.push<String>(
    context,
    MaterialPageRoute(builder: (_) => const QRScannerWidget()),
  );

  if (qrCode != null) {
    // Parse QR code data / 解析QR码数据
    final contractorData = _parseQRData(qrCode);

    // Submit to API / 提交到API
    await ApiService.submitContractorSignIn(
      token: authToken,
      contractorId: contractorData['id'],
      siteId: currentSiteId,
    );

    showSnackBar('Contractor signed in successfully');
  }
}
```

---

## 🎯 State Management / 状态管理

### DashboardController

**Purpose / 用途**: Global application state management using ChangeNotifier.
**用途**: 使用ChangeNotifier的全局应用状态管理。

**Location / 位置**: `lib/features/dashboard/controllers/dashboard_controller.dart`

**Key Properties / 主要属性**:
```dart
class DashboardController extends ChangeNotifier {
  // Singleton instance / 单例实例
  static DashboardController? instance;

  // Printer service / 打印机服务
  final PrinterService printerService;
  bool initialized = false;  // Printer ready / 打印机就绪

  // Site configuration / 站点配置
  List<SiteDetail> sites = [];
  SiteDetail? currentSite;

  // Field visibility settings / 字段可见性设置
  bool reqFullName = true;
  bool reqEmail = true;
  bool reqPhone = false;
  bool reqCompany = false;
  bool reqAddress = false;
  bool reqWorkType = false;
  bool reqSupervisor = false;
  bool reqSignInTime = true;
  bool reqVisitorPhoto = false;

  // Notification settings / 通知设置
  bool notifyVisitorEmail = false;
  bool notifyVisitorSms = false;

  // Badge printing settings / 徽章打印设置
  bool printVisitorBadge = true;

  // Branding / 品牌
  String? backgroundImageUrl;
  bool useCustomBackground = false;
  Uint8List? clientLogoBytes;
  String? clientLogoUrl;

  // Contacts / 联系人
  List<ContactDetail> availableSupervisors = [];

  // Test print tracking / 测试打印跟踪
  bool hasTestPrinted = false;

  // Methods / 方法
  void selectSite(SiteDetail site) {
    currentSite = site;
    notifyListeners();
  }

  void markTestPrinted() {
    hasTestPrinted = true;
    notifyListeners();
  }

  void resetTestPrintFlag() {
    hasTestPrinted = false;
    notifyListeners();
  }
}
```

**Usage Example / 使用示例**:
```dart
// Access controller / 访问控制器
final controller = DashboardController.instance;

// Check field visibility / 检查字段可见性
if (controller?.reqFullName ?? true) {
  // Show full name field / 显示全名字段
}

// Check printer status / 检查打印机状态
if (controller?.initialized ?? false) {
  // Printer is ready / 打印机就绪
  await controller!.printerService.printImage(image);
}

// Get current site / 获取当前站点
final siteName = controller?.currentSite?.title ?? 'Unknown Site';
```

---

## 📐 Best Practices / 最佳实践

### 1. Form Validation / 表单验证

```dart
// ✅ GOOD - Proper validation / 良好 - 正确的验证
KioskField(
  controller: _emailCtrl,
  validator: (v) {
    final text = (v ?? '').trim();
    if (text.isEmpty) return 'Email is required';

    final emailReg = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailReg.hasMatch(text)) {
      return 'Enter a valid email';
    }

    // Check against contacts / 检查是否与联系人冲突
    final exists = controller?.availableSupervisors.any(
      (contact) => contact.email.toLowerCase() == text.toLowerCase(),
    ) ?? false;

    if (exists) {
      return 'This email belongs to a staff member';
    }

    return null;
  },
)

// ❌ BAD - No validation / 差 - 无验证
TextField(controller: _emailCtrl)
```

---

### 2. Async Operations / 异步操作

```dart
// ✅ GOOD - Proper async handling / 良好 - 正确的异步处理
Future<void> _submitForm() async {
  if (!_formKey.currentState!.validate()) return;

  setState(() => _submitting = true);

  // Cache BuildContext before async gap / 在异步操作前缓存BuildContext
  final scaffoldMessenger = ScaffoldMessenger.of(context);
  final navigator = Navigator.of(context);

  try {
    final response = await ApiService.submitSignInLedger(...);

    if (!mounted) return;  // Check mounted / 检查mounted

    scaffoldMessenger.showSnackBar(
      SnackBar(content: Text('Success')),
    );

    navigator.pushNamed('/next-page');
  } catch (e) {
    if (!mounted) return;

    scaffoldMessenger.showSnackBar(
      SnackBar(content: Text('Error: $e')),
    );
  } finally {
    if (mounted) {
      setState(() => _submitting = false);
    }
  }
}

// ❌ BAD - Context usage after await / 差 - await后使用context
Future<void> _submitForm() async {
  await ApiService.submitSignInLedger(...);
  ScaffoldMessenger.of(context).showSnackBar(...);  // ❌ Wrong!
}
```

---

### 3. Resource Cleanup / 资源清理

```dart
// ✅ GOOD - Proper cleanup / 良好 - 正确的清理
class _MyPageState extends State<MyPage> {
  final _nameCtrl = TextEditingController();
  Timer? _timer;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _timer?.cancel();
    super.dispose();
  }
}

// ❌ BAD - No cleanup / 差 - 无清理
class _MyPageState extends State<MyPage> {
  final _nameCtrl = TextEditingController();
  // No dispose method / 无dispose方法
}
```

---

### 4. Error Handling / 错误处理

```dart
// ✅ GOOD - Comprehensive error handling / 良好 - 全面的错误处理
try {
  final response = await ApiService.submitSignInLedger(...);

  if (response.containsKey('error')) {
    throw Exception(response['error']);
  }

  // Process success / 处理成功
} on TimeoutException {
  showError('Request timed out. Please try again.');
} on SocketException {
  showError('No internet connection.');
} catch (e, stackTrace) {
  debugPrint('Error: $e');
  debugPrint('Stack trace: $stackTrace');
  showError('An unexpected error occurred: $e');
}

// ❌ BAD - Generic error handling / 差 - 通用错误处理
try {
  await ApiService.submitSignInLedger(...);
} catch (e) {
  print('Error');  // Not helpful / 没有帮助
}
```

---

### 5. Image/Photo Handling / 图片/照片处理

```dart
// ✅ GOOD - Convert to base64 for API / 良好 - 转换为base64发送到API
Future<void> _takePhoto() async {
  final XFile? photo = await _imagePicker.pickImage(
    source: ImageSource.camera,
    preferredCameraDevice: CameraDevice.front,  // Front camera / 前置摄像头
    maxWidth: 800,   // Resize / 调整大小
    maxHeight: 800,
    imageQuality: 85,  // Compress / 压缩
  );

  if (photo != null) {
    final bytes = await photo.readAsBytes();
    setState(() => _visitorPhotoBytes = bytes);
  }
}

// Send to API / 发送到API
final tempVisitorId = 'VIS${DateTime.now().millisecondsSinceEpoch}';
Map<String, String>? photosPayload;
if (_visitorPhotoBytes != null) {
  photosPayload = {
    tempVisitorId: base64Encode(_visitorPhotoBytes!),  // ID as key / ID作为键
  };
}

await ApiService.submitSignInLedger(
  visitorPhotos: photosPayload,
  ...
);

// ❌ BAD - Send raw bytes / 差 - 发送原始字节
await ApiService.submitSignInLedger(
  visitorPhoto: _visitorPhotoBytes,  // Can't serialize / 无法序列化
);
```

---

### 6. Loading States / 加载状态

```dart
// ✅ GOOD - Show loading indicator / 良好 - 显示加载指示器
if (_isInitializing) {
  return Scaffold(
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading...'),
        ],
      ),
    ),
  );
}

// Show actual content when loaded / 加载完成后显示实际内容
return KioskGuard(
  child: Scaffold(
    body: YourContent(),
  ),
);
```

---

### 7. Responsive Layout / 响应式布局

```dart
// ✅ GOOD - Constrained width / 良好 - 约束宽度
SingleChildScrollView(
  padding: const EdgeInsets.all(16),
  child: ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 720),  // Max width / 最大宽度
    child: KioskBody(...),
  ),
)

// ✅ GOOD - Adaptive button layout / 良好 - 自适应按钮布局
LayoutBuilder(
  builder: (context, constraints) {
    final isStacked = constraints.maxWidth < 440;

    if (isStacked) {
      return Column(
        children: [printButton, backButton],
      );
    }

    return Row(
      children: [
        Expanded(child: backButton),
        SizedBox(width: 16),
        Expanded(child: printButton),
      ],
    );
  },
)
```

---

## 🎨 Common UI Patterns / 常见UI模式

### Pattern 1: Search Dialog / 搜索对话框

```dart
Future<T?> _showSearchDialog<T>(
  BuildContext context,
  List<T> items,
  String Function(T) displayText,
) async {
  return showDialog<T>(
    context: context,
    builder: (context) => Dialog(
      child: Column(
        children: [
          // Search field / 搜索字段
          TextField(
            decoration: InputDecoration(
              labelText: 'Search',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (query) {
              // Filter items / 过滤项目
            },
          ),

          // Results list / 结果列表
          Expanded(
            child: ListView.builder(
              itemCount: filteredItems.length,
              itemBuilder: (context, index) {
                final item = filteredItems[index];
                return ListTile(
                  title: Text(displayText(item)),
                  onTap: () => Navigator.pop(context, item),
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}
```

---

### Pattern 2: Progress Indicator / 进度指示器

```dart
Widget buildProgressIndicator(PrintProgress progress) {
  Color backgroundColor;
  IconData icon;

  switch (progress.status) {
    case PrintStatus.completed:
      backgroundColor = AppTheme.successColor;
      icon = Icons.check_circle;
      break;
    case PrintStatus.failed:
      backgroundColor = AppTheme.dangerColor;
      icon = Icons.error;
      break;
    case PrintStatus.printing:
      backgroundColor = AppTheme.primaryBlue;
      icon = Icons.print;
      break;
    default:
      backgroundColor = Colors.grey;
      icon = Icons.info;
  }

  return Container(
    padding: EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: backgroundColor.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: backgroundColor),
    ),
    child: Row(
      children: [
        Icon(icon, color: backgroundColor),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            progress.displayMessage,
            style: TextStyle(color: backgroundColor),
          ),
        ),
      ],
    ),
  );
}
```

---

### Pattern 3: Confirmation Dialog / 确认对话框

```dart
Future<bool> _showConfirmationDialog(
  BuildContext context,
  String title,
  String message,
) async {
  return await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text('Confirm'),
        ),
      ],
    ),
  ) ?? false;
}

// Usage / 使用
if (await _showConfirmationDialog(
  context,
  'Sign Out',
  'Are you sure you want to sign out this visitor?',
)) {
  // Proceed with sign out / 继续签出
}
```

---

## 📸 Visual Examples / 视觉示例

### Page Layout Structure / 页面布局结构

```
┌────────────────────────────────────────┐
│         [Client Logo]                  │
│      [Worx Powered By Logo]            │
│                                        │
│      VISITOR SIGN IN                   │  ← KioskBody Header
│   Supervisor: John Smith               │
│   Printer: ✓ Ready                     │
├────────────────────────────────────────┤
│ ┌────────────────────────────────────┐ │
│ │  Full Name *                       │ │  ← KioskField
│ │  [__________________________]      │ │
│ └────────────────────────────────────┘ │
│                                        │
│ ┌────────────────────────────────────┐ │
│ │  Email Address *                   │ │
│ │  [__________________________]      │ │
│ └────────────────────────────────────┘ │
│                                        │  ← Menu Content
│ ┌────────────────────────────────────┐ │
│ │  Person Visiting                   │ │
│ │  [Select person ▼]                 │ │
│ └────────────────────────────────────┘ │
│                                        │
│ ┌────────────────────────────────────┐ │
│ │ 📷 Visitor Photo                   │ │
│ │ [Take Photo]                       │ │
│ └────────────────────────────────────┘ │
│                                        │
│  [← Back]              [Next →]       │
├────────────────────────────────────────┤
│        [Admin Sign In ⚙️]              │  ← Footer Action
└────────────────────────────────────────┘
```

---

### Badge Layout / 徽章布局

```
┌────────────────────────┐
│   [Client Logo]        │
│                        │
│   MAIN OFFICE          │
│                        │
│   Full Name:           │
│   John Smith           │
│                        │
│   Email:               │
│   john@example.com     │
│                        │
│   Company:             │
│   ABC Corporation      │
│                        │
│   Person Visiting:     │
│   Jane Doe             │
│                        │
│   Photo:               │
│   Photo Uploaded       │  ← Shows this text if photo exists
│                        │
│   ┌──────────────┐     │
│   │  [QR CODE]   │     │  ← Contains visitor ID
│   └──────────────┘     │
│                        │
│   ID: VIS123456        │
└────────────────────────┘
```

---

## 🔄 Data Flow Diagram / 数据流图

```
User Action / 用户操作
    ↓
Form Input / 表单输入
    ↓
Validation / 验证
    ↓
DashboardController / 控制器
    ↓
ApiService / API服务
    ↓
Server / 服务器
    ↓
Response / 响应
    ↓
SecureStorageService / 安全存储
    ↓
BadgeGenerator / 徽章生成
    ↓
PrinterService / 打印服务
    ↓
UI Update / UI更新
```

---

## 📝 Common Snippets / 常用代码片段

### Snippet 1: Standard Page Template / 标准页面模板

```dart
import 'package:flutter/material.dart';
import 'package:worxvisitorapp/widgets/kiosk_body.dart';
import 'package:worxvisitorapp/widgets/kiosk_guard.dart';
import 'package:worxvisitorapp/features/dashboard/controllers/dashboard_controller.dart';

class YourPage extends StatefulWidget {
  const YourPage({super.key});

  @override
  State<YourPage> createState() => _YourPageState();
}

class _YourPageState extends State<YourPage> {
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _initializePage();
  }

  Future<void> _initializePage() async {
    // Load data / 加载数据
    setState(() => _isInitializing = false);
  }

  @override
  Widget build(BuildContext context) {
    final controller = DashboardController.instance;

    if (_isInitializing) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final scaffold = Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: KioskBody(
              siteTitle: controller?.resolveSiteHeading('Your Page') ?? 'Your Page',
              logo1Bytes: controller?.clientLogoDisplayBytes,
              logo1Url: controller?.clientLogoDisplayBytes == null
                  ? 'lib/assets/images/WorxSafety_Logo_NoShadow.svg'
                  : null,
              logo2Url: 'lib/assets/images/Worx_PoweredBy_Logo_Mono.svg',
              menuContent: _buildContent(),
            ),
          ),
        ),
      ),
    );

    return KioskGuard(child: scaffold);
  }

  Widget _buildContent() {
    return Column(
      children: [
        // Your content here / 你的内容在这里
      ],
    );
  }
}
```

---

### Snippet 2: Form with Validation / 带验证的表单

```dart
final _formKey = GlobalKey<FormState>();
final _nameCtrl = TextEditingController();

@override
void dispose() {
  _nameCtrl.dispose();
  super.dispose();
}

Widget _buildForm() {
  return Form(
    key: _formKey,
    child: Column(
      children: [
        KioskField(
          controller: _nameCtrl,
          title: 'Full Name',
          required: true,
          validator: (v) {
            if ((v ?? '').trim().isEmpty) {
              return 'Name is required';
            }
            return null;
          },
        ),

        const SizedBox(height: 20),

        FilledButton(
          onPressed: _onSubmit,
          child: const Text('Submit'),
        ),
      ],
    ),
  );
}

Future<void> _onSubmit() async {
  if (!_formKey.currentState!.validate()) return;

  // Process form / 处理表单
}
```

---

### Snippet 3: API Call with Error Handling / 带错误处理的API调用

```dart
Future<void> _submitData() async {
  setState(() => _submitting = true);

  final scaffoldMessenger = ScaffoldMessenger.of(context);

  try {
    final response = await ApiService.submitSignInLedger(
      token: await SecureStorageService.getAuthToken() ?? '',
      siteId: controller?.currentSite?.id ?? '',
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      questions: {},
      uniqueId: '',
    );

    if (!mounted) return;

    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text('Success: ${response['message']}'),
        backgroundColor: AppTheme.successColor,
      ),
    );
  } catch (e) {
    if (!mounted) return;

    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text('Error: $e'),
        backgroundColor: AppTheme.dangerColor,
      ),
    );
  } finally {
    if (mounted) {
      setState(() => _submitting = false);
    }
  }
}
```

---

## 🎓 Conclusion / 总结

This guide covers all major components and patterns used in the Worx Visitor Management frontend application. Use these templates and patterns to maintain consistency and best practices throughout the codebase.

本指南涵盖了Worx访客管理前端应用中使用的所有主要组件和模式。使用这些模板和模式来保持代码库的一致性和最佳实践。

### Quick Reference / 快速参考

- **Form pages**: Use `KioskGuard` + `KioskBody` + `KioskField`
- **Dialogs**: Use search pattern with filter
- **API calls**: Always handle errors and check `mounted`
- **Images**: Convert to base64, use visitor ID as key
- **Printing**: Track progress with `PrintProgressWidget`
- **State**: Access via `DashboardController.instance`

---

**Last Updated / 最后更新**: 2026-01-08
**Version / 版本**: 1.0.0
