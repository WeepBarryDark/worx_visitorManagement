# Flutter Basic Components Guide
# Flutter 基础组件指南

## 📚 Table of Contents / 目录

1. [Layout Components / 布局组件](#layout-components)
2. [Basic Widgets / 基础组件](#basic-widgets)
3. [Input Components / 输入组件](#input-components)
4. [Button Components / 按钮组件](#button-components)
5. [Display Components / 显示组件](#display-components)
6. [Navigation Components / 导航组件](#navigation-components)
7. [Dialog Components / 对话框组件](#dialog-components)
8. [List Components / 列表组件](#list-components)
9. [Image & Media / 图片和媒体](#image-media)
10. [Gesture & Interaction / 手势和交互](#gesture-interaction)

---

## 📐 Layout Components / 布局组件

### 1. Container

**Purpose / 用途**: A box model container that can contain decoration, padding, margin, and constraints.
**用途**: 一个盒子模型容器，可以包含装饰、内边距、外边距和约束。

**Common Use Cases / 常用场景**:
- Creating colored boxes / 创建彩色盒子
- Adding padding and margin / 添加内边距和外边距
- Applying decorations (border, shadow, gradient) / 应用装饰（边框、阴影、渐变）
- Setting size constraints / 设置尺寸约束

**Basic Example / 基础示例**:
```dart
// Simple container with color / 简单的彩色容器
Container(
  width: 100,
  height: 100,
  color: Colors.blue,
  child: Text('Hello'),
)

// Container with decoration / 带装饰的容器
Container(
  width: 200,
  height: 100,
  padding: const EdgeInsets.all(16),        // Inner spacing / 内边距
  margin: const EdgeInsets.all(8),          // Outer spacing / 外边距
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12), // Rounded corners / 圆角
    border: Border.all(                      // Border / 边框
      color: Colors.blue,
      width: 2,
    ),
    boxShadow: [                             // Shadow / 阴影
      BoxShadow(
        color: Colors.grey.withOpacity(0.5),
        spreadRadius: 2,
        blurRadius: 5,
        offset: const Offset(0, 3),
      ),
    ],
  ),
  child: Text('Container with decoration'),
)

// Gradient background / 渐变背景
Container(
  width: double.infinity,
  height: 200,
  decoration: BoxDecoration(
    gradient: LinearGradient(
      colors: [Colors.blue, Colors.purple],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ),
  child: Center(child: Text('Gradient', style: TextStyle(color: Colors.white))),
)
```

**Visual Example / 视觉示例**:
```
┌─────────────────────────┐
│  margin (外边距)          │
│  ┌───────────────────┐  │
│  │ border (边框)       │  │
│  │ ┌───────────────┐ │  │
│  │ │ padding        │ │  │
│  │ │ ┌───────────┐ │ │  │
│  │ │ │  Content  │ │ │  │
│  │ │ │  内容     │ │ │  │
│  │ │ └───────────┘ │ │  │
│  │ └───────────────┘ │  │
│  └───────────────────┘  │
└─────────────────────────┘
```

---

### 2. Column

**Purpose / 用途**: Arranges children vertically (top to bottom).
**用途**: 垂直排列子组件（从上到下）。

**Common Use Cases / 常用场景**:
- Form layouts / 表单布局
- Vertical lists / 垂直列表
- Stacking content / 堆叠内容

**Example / 示例**:
```dart
Column(
  mainAxisAlignment: MainAxisAlignment.start,     // Vertical alignment / 垂直对齐
  crossAxisAlignment: CrossAxisAlignment.center,  // Horizontal alignment / 水平对齐
  children: [
    Text('First item'),
    SizedBox(height: 10),      // Spacing / 间距
    Text('Second item'),
    SizedBox(height: 10),
    Text('Third item'),
  ],
)

// Column with different alignments / 不同对齐方式的Column
Column(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,  // Equal spacing / 等间距
  crossAxisAlignment: CrossAxisAlignment.stretch,     // Full width / 全宽
  children: [
    Container(height: 50, color: Colors.red),
    Container(height: 50, color: Colors.green),
    Container(height: 50, color: Colors.blue),
  ],
)
```

**MainAxisAlignment Options / 主轴对齐选项**:
```
start           center          end             spaceBetween    spaceAround     spaceEvenly
┌─────┐        ┌─────┐        ┌─────┐         ┌─────┐         ┌─────┐         ┌─────┐
│  □  │        │     │        │     │         │  □  │         │     │         │     │
│  □  │        │  □  │        │     │         │     │         │  □  │         │  □  │
│  □  │        │  □  │        │     │         │     │         │     │         │     │
│     │        │  □  │        │  □  │         │  □  │         │  □  │         │  □  │
│     │        │     │        │  □  │         │     │         │     │         │     │
│     │        │     │        │  □  │         │  □  │         │  □  │         │  □  │
└─────┘        └─────┘        └─────┘         └─────┘         └─────┘         └─────┘
```

---

### 3. Row

**Purpose / 用途**: Arranges children horizontally (left to right).
**用途**: 水平排列子组件（从左到右）。

**Common Use Cases / 常用场景**:
- Button groups / 按钮组
- Horizontal menus / 水平菜单
- Icon-text combinations / 图标文字组合

**Example / 示例**:
```dart
Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  crossAxisAlignment: CrossAxisAlignment.center,
  children: [
    Icon(Icons.home),
    Text('Home'),
    Icon(Icons.arrow_forward),
  ],
)

// Row with flexible children / 带弹性子组件的Row
Row(
  children: [
    Expanded(
      flex: 2,          // Takes 2/3 of space / 占据2/3空间
      child: Container(height: 50, color: Colors.red),
    ),
    Expanded(
      flex: 1,          // Takes 1/3 of space / 占据1/3空间
      child: Container(height: 50, color: Colors.blue),
    ),
  ],
)
```

---

### 4. Stack

**Purpose / 用途**: Overlays children on top of each other.
**用途**: 将子组件叠加在一起。

**Common Use Cases / 常用场景**:
- Overlays / 覆盖层
- Badges on icons / 图标徽章
- Background with foreground / 背景和前景

**Example / 示例**:
```dart
Stack(
  children: [
    // Background image / 背景图片
    Container(
      width: 200,
      height: 200,
      color: Colors.grey,
    ),
    // Text overlay / 文字覆盖层
    Positioned(
      bottom: 10,
      right: 10,
      child: Text(
        'Overlay Text',
        style: TextStyle(color: Colors.white, fontSize: 20),
      ),
    ),
  ],
)

// Badge example / 徽章示例
Stack(
  children: [
    Icon(Icons.notifications, size: 40),
    Positioned(
      right: 0,
      top: 0,
      child: Container(
        padding: EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.red,
          shape: BoxShape.circle,
        ),
        child: Text('5', style: TextStyle(color: Colors.white, fontSize: 12)),
      ),
    ),
  ],
)
```

**Visual Example / 视觉示例**:
```
Stack layers (from bottom to top):
堆叠层（从底到顶）:

┌─────────────────────┐
│                     │  Layer 3 / 第3层
│   ┌──────────────┐  │
│   │              │  │  Layer 2 / 第2层
│   │  ┌────────┐  │  │
│   │  │ Layer1 │  │  │  Layer 1 / 第1层
│   │  └────────┘  │  │
│   └──────────────┘  │
└─────────────────────┘
```

---

### 5. Padding

**Purpose / 用途**: Adds space around a widget.
**用途**: 在组件周围添加空间。

**Example / 示例**:
```dart
// Uniform padding / 统一内边距
Padding(
  padding: const EdgeInsets.all(16),
  child: Text('Padded text'),
)

// Different padding on each side / 每边不同的内边距
Padding(
  padding: const EdgeInsets.symmetric(
    horizontal: 20,  // Left and right / 左右
    vertical: 10,    // Top and bottom / 上下
  ),
  child: Text('Asymmetric padding'),
)

// Custom padding for each side / 每边自定义内边距
Padding(
  padding: const EdgeInsets.only(
    left: 10,
    top: 20,
    right: 30,
    bottom: 40,
  ),
  child: Text('Custom padding'),
)

// Using EdgeInsets.fromLTRB / 使用fromLTRB
Padding(
  padding: const EdgeInsets.fromLTRB(10, 20, 30, 40),  // left, top, right, bottom
  child: Text('LTRB padding'),
)
```

---

### 6. Center

**Purpose / 用途**: Centers its child within itself.
**用途**: 将子组件在自身内居中。

**Example / 示例**:
```dart
Center(
  child: Text('Centered Text'),
)

// Center with size / 带尺寸的居中
Center(
  child: Container(
    width: 100,
    height: 100,
    color: Colors.blue,
    child: Center(
      child: Text('Centered', style: TextStyle(color: Colors.white)),
    ),
  ),
)
```

---

### 7. Align

**Purpose / 用途**: Aligns its child within itself.
**用途**: 在自身内对齐子组件。

**Example / 示例**:
```dart
// Top left / 左上
Align(
  alignment: Alignment.topLeft,
  child: Text('Top Left'),
)

// Bottom right / 右下
Align(
  alignment: Alignment.bottomRight,
  child: Text('Bottom Right'),
)

// Custom alignment / 自定义对齐
Align(
  alignment: Alignment(0.5, 0.5),  // x, y (-1 to 1) / x, y (-1到1)
  child: Text('Custom position'),
)
```

**Alignment Positions / 对齐位置**:
```
topLeft      topCenter      topRight
    ●────────────●────────────●
    │                         │
centerLeft   center      centerRight
    ●────────────●────────────●
    │                         │
bottomLeft   bottomCenter   bottomRight
    ●────────────●────────────●
```

---

### 8. SizedBox

**Purpose / 用途**: A box with a specified size.
**用途**: 具有指定尺寸的盒子。

**Common Use Cases / 常用场景**:
- Fixed spacing between widgets / 组件间固定间距
- Empty placeholders / 空占位符
- Constraining child size / 约束子组件尺寸

**Example / 示例**:
```dart
// Fixed size box / 固定尺寸盒子
SizedBox(
  width: 100,
  height: 50,
  child: Container(color: Colors.blue),
)

// Spacing between widgets / 组件间距
Column(
  children: [
    Text('First'),
    SizedBox(height: 20),     // Vertical spacing / 垂直间距
    Text('Second'),
  ],
)

// Empty space / 空白空间
SizedBox(width: 50)  // Creates 50px horizontal space / 创建50px水平空间

// Full width / 全宽
SizedBox(
  width: double.infinity,
  child: ElevatedButton(
    onPressed: () {},
    child: Text('Full Width Button'),
  ),
)
```

---

### 9. ConstrainedBox

**Purpose / 用途**: Imposes size constraints on its child.
**用途**: 对子组件施加尺寸约束。

**Example / 示例**:
```dart
// Minimum size / 最小尺寸
ConstrainedBox(
  constraints: BoxConstraints(
    minWidth: 100,
    minHeight: 50,
  ),
  child: Container(color: Colors.blue),
)

// Maximum size / 最大尺寸
ConstrainedBox(
  constraints: BoxConstraints(
    maxWidth: 300,
    maxHeight: 200,
  ),
  child: Image.network('url'),
)

// Both min and max / 同时设置最小和最大
ConstrainedBox(
  constraints: BoxConstraints(
    minWidth: 100,
    maxWidth: 300,
    minHeight: 50,
    maxHeight: 200,
  ),
  child: Container(color: Colors.green),
)
```

---

### 10. Expanded & Flexible

**Purpose / 用途**: Makes a child fill available space in Row/Column.
**用途**: 使子组件填充Row/Column中的可用空间。

**Example / 示例**:
```dart
// Expanded - takes all available space / 占据所有可用空间
Row(
  children: [
    Container(width: 50, height: 50, color: Colors.red),
    Expanded(
      child: Container(height: 50, color: Colors.blue),  // Fills remaining space / 填充剩余空间
    ),
    Container(width: 50, height: 50, color: Colors.green),
  ],
)

// Multiple Expanded with flex / 多个Expanded带flex
Row(
  children: [
    Expanded(
      flex: 2,  // Takes 2/5 of space / 占据2/5空间
      child: Container(height: 50, color: Colors.red),
    ),
    Expanded(
      flex: 3,  // Takes 3/5 of space / 占据3/5空间
      child: Container(height: 50, color: Colors.blue),
    ),
  ],
)

// Flexible - can shrink / 可以收缩
Row(
  children: [
    Flexible(
      flex: 1,
      fit: FlexFit.loose,  // Can be smaller than flex space / 可以小于flex空间
      child: Container(height: 50, color: Colors.red, child: Text('Flexible')),
    ),
    Container(width: 100, height: 50, color: Colors.blue),
  ],
)
```

---

## 🎨 Basic Widgets / 基础组件

### 11. Text

**Purpose / 用途**: Displays a string of text.
**用途**: 显示文本字符串。

**Example / 示例**:
```dart
// Simple text / 简单文本
Text('Hello, World!')

// Styled text / 样式文本
Text(
  'Styled Text',
  style: TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: Colors.blue,
    letterSpacing: 2,
    decoration: TextDecoration.underline,
    fontStyle: FontStyle.italic,
  ),
)

// Text alignment / 文本对齐
Text(
  'Center aligned text',
  textAlign: TextAlign.center,
)

// Max lines with overflow / 最大行数和溢出
Text(
  'This is a very long text that might overflow',
  maxLines: 2,
  overflow: TextOverflow.ellipsis,  // Shows ... when overflow / 溢出时显示...
)

// Rich text / 富文本
Text.rich(
  TextSpan(
    text: 'Hello ',
    style: TextStyle(fontSize: 16),
    children: [
      TextSpan(
        text: 'World',
        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
      ),
      TextSpan(text: '!'),
    ],
  ),
)
```

**Common TextStyle Properties / 常用TextStyle属性**:
```dart
TextStyle(
  fontSize: 16,                          // Font size / 字体大小
  fontWeight: FontWeight.bold,           // bold, w100-w900 / 粗体
  fontStyle: FontStyle.italic,           // italic / 斜体
  color: Colors.blue,                    // Text color / 文字颜色
  backgroundColor: Colors.yellow,        // Background color / 背景色
  letterSpacing: 2,                      // Space between letters / 字母间距
  wordSpacing: 4,                        // Space between words / 单词间距
  height: 1.5,                           // Line height multiplier / 行高倍数
  decoration: TextDecoration.underline,  // underline, lineThrough / 下划线、删除线
  decorationColor: Colors.red,           // Decoration color / 装饰线颜色
  decorationStyle: TextDecorationStyle.dashed,  // Decoration style / 装饰线样式
)
```

---

### 12. Icon

**Purpose / 用途**: Displays an icon from the Material Icons font.
**用途**: 显示Material Icons字体中的图标。

**Example / 示例**:
```dart
// Simple icon / 简单图标
Icon(Icons.home)

// Styled icon / 样式图标
Icon(
  Icons.favorite,
  color: Colors.red,
  size: 40,
)

// Icon with text / 图标和文字
Row(
  children: [
    Icon(Icons.phone, size: 20),
    SizedBox(width: 8),
    Text('+61 412 345 678'),
  ],
)
```

**Common Icons / 常用图标**:
```dart
Icons.home           // 主页
Icons.person         // 用户
Icons.settings       // 设置
Icons.search         // 搜索
Icons.add            // 添加
Icons.delete         // 删除
Icons.edit           // 编辑
Icons.check          // 勾选
Icons.close          // 关闭
Icons.arrow_back     // 返回箭头
Icons.arrow_forward  // 前进箭头
Icons.menu           // 菜单
Icons.more_vert      // 更多（竖）
Icons.email          // 邮件
Icons.phone          // 电话
Icons.camera         // 相机
Icons.photo          // 照片
Icons.location_on    // 位置
Icons.notification   // 通知
Icons.print          // 打印
```

---

### 13. Image

**Purpose / 用途**: Displays images from various sources.
**用途**: 显示来自各种来源的图片。

**Example / 示例**:
```dart
// From asset / 从资源文件
Image.asset('assets/images/logo.png')

// From network / 从网络
Image.network('https://example.com/image.jpg')

// From memory / 从内存
Image.memory(uint8ListBytes)

// From file / 从文件
Image.file(File('path/to/file'))

// With fit / 带适配模式
Image.network(
  'https://example.com/image.jpg',
  fit: BoxFit.cover,     // cover, contain, fill, fitWidth, fitHeight
  width: 200,
  height: 200,
)

// With loading placeholder / 带加载占位符
Image.network(
  'https://example.com/image.jpg',
  loadingBuilder: (context, child, loadingProgress) {
    if (loadingProgress == null) return child;
    return Center(
      child: CircularProgressIndicator(
        value: loadingProgress.expectedTotalBytes != null
            ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
            : null,
      ),
    );
  },
)

// With error handling / 带错误处理
Image.network(
  'https://example.com/image.jpg',
  errorBuilder: (context, error, stackTrace) {
    return Icon(Icons.error, color: Colors.red);
  },
)
```

**BoxFit Options / BoxFit选项**:
```
fill      contain    cover     fitWidth  fitHeight  none      scaleDown
┌────┐    ┌────┐    ┌────┐    ┌────┐    ┌────┐    ┌────┐    ┌────┐
│████│    │ ██ │    │████│    │████│    │ ██ │    │ ██ │    │ ██ │
│████│    │ ██ │    │████│    │    │    │████│    │ ██ │    │ ██ │
└────┘    └────┘    └────┘    └────┘    └────┘    └────┘    └────┘
Distort   Keep      Crop      Full W    Full H    Original  Smaller
拉伸      保持比例   裁剪      全宽      全高      原始      缩小
```

---

### 14. Divider

**Purpose / 用途**: A horizontal line used to separate content.
**用途**: 用于分隔内容的水平线。

**Example / 示例**:
```dart
// Simple divider / 简单分隔线
Divider()

// Styled divider / 样式分隔线
Divider(
  color: Colors.grey,
  thickness: 2,      // Line thickness / 线条粗细
  indent: 20,        // Left indent / 左缩进
  endIndent: 20,     // Right indent / 右缩进
  height: 30,        // Total height including spacing / 总高度包括间距
)

// Vertical divider / 垂直分隔线
Row(
  children: [
    Text('Left'),
    VerticalDivider(
      width: 30,
      thickness: 2,
      color: Colors.grey,
    ),
    Text('Right'),
  ],
)
```

---

### 15. Spacer

**Purpose / 用途**: Creates flexible empty space in Row/Column.
**用途**: 在Row/Column中创建弹性空白空间。

**Example / 示例**:
```dart
Row(
  children: [
    Text('Left'),
    Spacer(),          // Pushes items apart / 将项目推开
    Text('Right'),
  ],
)

// With flex / 带flex
Row(
  children: [
    Text('Start'),
    Spacer(flex: 2),   // Takes 2x space / 占据2倍空间
    Text('Middle'),
    Spacer(flex: 1),   // Takes 1x space / 占据1倍空间
    Text('End'),
  ],
)
```

---

## 📝 Input Components / 输入组件

### 16. TextField

**Purpose / 用途**: A material design text input field.
**用途**: Material Design文本输入框。

**Example / 示例**:
```dart
// Simple text field / 简单文本框
TextField(
  decoration: InputDecoration(
    labelText: 'Name',
    hintText: 'Enter your name',
  ),
)

// With controller / 带控制器
final _controller = TextEditingController();

TextField(
  controller: _controller,
  onChanged: (value) {
    print('Current value: $value');
  },
)

// Styled text field / 样式文本框
TextField(
  decoration: InputDecoration(
    labelText: 'Email',
    hintText: 'Enter email',
    prefixIcon: Icon(Icons.email),           // Left icon / 左侧图标
    suffixIcon: Icon(Icons.check),           // Right icon / 右侧图标
    border: OutlineInputBorder(              // Outline border / 轮廓边框
      borderRadius: BorderRadius.circular(8),
    ),
    filled: true,                            // Fill background / 填充背景
    fillColor: Colors.grey[200],
  ),
  keyboardType: TextInputType.emailAddress,  // Email keyboard / 邮箱键盘
)

// Password field / 密码框
TextField(
  obscureText: true,                         // Hide text / 隐藏文字
  decoration: InputDecoration(
    labelText: 'Password',
    prefixIcon: Icon(Icons.lock),
    suffixIcon: IconButton(
      icon: Icon(Icons.visibility),
      onPressed: () {
        // Toggle password visibility / 切换密码可见性
      },
    ),
  ),
)

// Multi-line text field / 多行文本框
TextField(
  maxLines: 5,
  decoration: InputDecoration(
    labelText: 'Comments',
    border: OutlineInputBorder(),
    alignLabelWithHint: true,
  ),
)

// Read-only field / 只读字段
TextField(
  readOnly: true,
  controller: _idController,
  decoration: InputDecoration(
    labelText: 'Visitor ID',
    filled: true,
    fillColor: Colors.grey[100],
  ),
)
```

**InputDecoration Properties / InputDecoration属性**:
```dart
InputDecoration(
  labelText: 'Label',              // Floating label / 浮动标签
  hintText: 'Hint text',           // Placeholder / 占位符
  helperText: 'Helper text',       // Help text below / 下方帮助文字
  errorText: 'Error message',      // Error message / 错误消息
  prefixIcon: Icon(Icons.person),  // Icon on left / 左侧图标
  suffixIcon: Icon(Icons.clear),   // Icon on right / 右侧图标
  prefix: Text('\$'),              // Text prefix / 文本前缀
  suffix: Text('.00'),             // Text suffix / 文本后缀
  border: OutlineInputBorder(),    // Border style / 边框样式
  enabledBorder: ...,              // Border when enabled / 启用时边框
  focusedBorder: ...,              // Border when focused / 聚焦时边框
  errorBorder: ...,                // Border when error / 错误时边框
  filled: true,                    // Fill background / 填充背景
  fillColor: Colors.grey[200],     // Background color / 背景颜色
)
```

**Keyboard Types / 键盘类型**:
```dart
TextInputType.text           // Default / 默认
TextInputType.number         // Number pad / 数字键盘
TextInputType.phone          // Phone number / 电话号码
TextInputType.emailAddress   // Email / 邮箱
TextInputType.url            // URL
TextInputType.multiline      // Multi-line / 多行
TextInputType.datetime       // Date/time / 日期时间
```

---

### 17. TextFormField

**Purpose / 用途**: TextField with built-in Form validation.
**用途**: 带内置表单验证的TextField。

**Example / 示例**:
```dart
Form(
  key: _formKey,
  child: Column(
    children: [
      // Email field with validation / 带验证的邮箱字段
      TextFormField(
        decoration: InputDecoration(
          labelText: 'Email',
          prefixIcon: Icon(Icons.email),
        ),
        keyboardType: TextInputType.emailAddress,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Email is required';
          }
          if (!value.contains('@')) {
            return 'Enter a valid email';
          }
          return null;  // Valid / 有效
        },
      ),

      // Password field with validation / 带验证的密码字段
      TextFormField(
        obscureText: true,
        decoration: InputDecoration(
          labelText: 'Password',
          prefixIcon: Icon(Icons.lock),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Password is required';
          }
          if (value.length < 6) {
            return 'Password must be at least 6 characters';
          }
          return null;
        },
      ),

      // Submit button / 提交按钮
      ElevatedButton(
        onPressed: () {
          if (_formKey.currentState!.validate()) {
            // Form is valid / 表单有效
            print('Form is valid');
          }
        },
        child: Text('Submit'),
      ),
    ],
  ),
)
```

---

### 18. Checkbox

**Purpose / 用途**: A material design checkbox.
**用途**: Material Design复选框。

**Example / 示例**:
```dart
// Simple checkbox / 简单复选框
bool _isChecked = false;

Checkbox(
  value: _isChecked,
  onChanged: (bool? value) {
    setState(() {
      _isChecked = value ?? false;
    });
  },
)

// Checkbox with label / 带标签的复选框
CheckboxListTile(
  title: Text('I agree to terms and conditions'),
  value: _isChecked,
  onChanged: (bool? value) {
    setState(() {
      _isChecked = value ?? false;
    });
  },
  controlAffinity: ListTileControlAffinity.leading,  // Checkbox on left / 复选框在左侧
)

// Tristate checkbox / 三态复选框
Checkbox(
  value: _checkboxValue,      // true, false, or null / true、false或null
  tristate: true,
  onChanged: (bool? value) {
    setState(() {
      _checkboxValue = value;
    });
  },
)
```

---

### 19. Radio

**Purpose / 用途**: A material design radio button (single selection).
**用途**: Material Design单选按钮（单选）。

**Example / 示例**:
```dart
enum Gender { male, female, other }
Gender? _selectedGender;

Column(
  children: [
    // Radio buttons / 单选按钮
    RadioListTile<Gender>(
      title: Text('Male'),
      value: Gender.male,
      groupValue: _selectedGender,
      onChanged: (Gender? value) {
        setState(() {
          _selectedGender = value;
        });
      },
    ),
    RadioListTile<Gender>(
      title: Text('Female'),
      value: Gender.female,
      groupValue: _selectedGender,
      onChanged: (Gender? value) {
        setState(() {
          _selectedGender = value;
        });
      },
    ),
    RadioListTile<Gender>(
      title: Text('Other'),
      value: Gender.other,
      groupValue: _selectedGender,
      onChanged: (Gender? value) {
        setState(() {
          _selectedGender = value;
        });
      },
    ),
  ],
)

// Simple radio / 简单单选
Radio<int>(
  value: 1,
  groupValue: _selectedValue,
  onChanged: (int? value) {
    setState(() {
      _selectedValue = value;
    });
  },
)
```

---

### 20. Switch

**Purpose / 用途**: A material design switch (toggle).
**用途**: Material Design开关（切换）。

**Example / 示例**:
```dart
bool _isSwitched = false;

// Simple switch / 简单开关
Switch(
  value: _isSwitched,
  onChanged: (bool value) {
    setState(() {
      _isSwitched = value;
    });
  },
)

// Switch with label / 带标签的开关
SwitchListTile(
  title: Text('Enable notifications'),
  subtitle: Text('Receive push notifications'),
  value: _isSwitched,
  onChanged: (bool value) {
    setState(() {
      _isSwitched = value;
    });
  },
  secondary: Icon(Icons.notifications),  // Leading icon / 前导图标
)
```

---

### 21. Slider

**Purpose / 用途**: A material design slider for selecting a value.
**用途**: Material Design滑块，用于选择数值。

**Example / 示例**:
```dart
double _currentValue = 20;

Slider(
  value: _currentValue,
  min: 0,
  max: 100,
  divisions: 10,               // Number of discrete divisions / 离散分段数量
  label: _currentValue.round().toString(),  // Show value label / 显示数值标签
  onChanged: (double value) {
    setState(() {
      _currentValue = value;
    });
  },
)

// Range slider / 范围滑块
RangeValues _currentRangeValues = const RangeValues(20, 60);

RangeSlider(
  values: _currentRangeValues,
  min: 0,
  max: 100,
  divisions: 10,
  labels: RangeLabels(
    _currentRangeValues.start.round().toString(),
    _currentRangeValues.end.round().toString(),
  ),
  onChanged: (RangeValues values) {
    setState(() {
      _currentRangeValues = values;
    });
  },
)
```

---

### 22. DropdownButton

**Purpose / 用途**: A material design button for selecting from a list.
**用途**: Material Design下拉选择按钮。

**Example / 示例**:
```dart
String? _selectedValue;

DropdownButton<String>(
  value: _selectedValue,
  hint: Text('Select an option'),
  items: <String>['Option 1', 'Option 2', 'Option 3']
      .map<DropdownMenuItem<String>>((String value) {
    return DropdownMenuItem<String>(
      value: value,
      child: Text(value),
    );
  }).toList(),
  onChanged: (String? newValue) {
    setState(() {
      _selectedValue = newValue;
    });
  },
)

// Dropdown with FormField / 带FormField的下拉框
DropdownButtonFormField<String>(
  value: _selectedValue,
  decoration: InputDecoration(
    labelText: 'Select option',
    border: OutlineInputBorder(),
  ),
  items: ['Option 1', 'Option 2', 'Option 3']
      .map((value) => DropdownMenuItem(
            value: value,
            child: Text(value),
          ))
      .toList(),
  onChanged: (value) {
    setState(() {
      _selectedValue = value;
    });
  },
  validator: (value) {
    if (value == null) {
      return 'Please select an option';
    }
    return null;
  },
)
```

---

## 🔘 Button Components / 按钮组件

### 23. ElevatedButton (FilledButton)

**Purpose / 用途**: A material design raised button.
**用途**: Material Design凸起按钮。

**Example / 示例**:
```dart
// Simple button / 简单按钮
ElevatedButton(
  onPressed: () {
    print('Button pressed');
  },
  child: Text('Click Me'),
)

// Styled button / 样式按钮
ElevatedButton(
  onPressed: () {},
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.blue,           // Background color / 背景色
    foregroundColor: Colors.white,          // Text color / 文字颜色
    padding: EdgeInsets.symmetric(
      horizontal: 32,
      vertical: 16,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
    elevation: 5,                           // Shadow elevation / 阴影高度
  ),
  child: Text('Styled Button'),
)

// Button with icon / 带图标的按钮
ElevatedButton.icon(
  onPressed: () {},
  icon: Icon(Icons.add),
  label: Text('Add Item'),
)

// Disabled button / 禁用按钮
ElevatedButton(
  onPressed: null,  // null disables the button / null禁用按钮
  child: Text('Disabled'),
)

// Full width button / 全宽按钮
SizedBox(
  width: double.infinity,
  child: ElevatedButton(
    onPressed: () {},
    child: Text('Full Width Button'),
  ),
)
```

---

### 24. TextButton

**Purpose / 用途**: A material design flat button.
**用途**: Material Design扁平按钮。

**Example / 示例**:
```dart
// Simple text button / 简单文本按钮
TextButton(
  onPressed: () {},
  child: Text('Text Button'),
)

// Styled text button / 样式文本按钮
TextButton(
  onPressed: () {},
  style: TextButton.styleFrom(
    foregroundColor: Colors.blue,
    padding: EdgeInsets.all(16),
  ),
  child: Text('Styled Text Button'),
)

// Text button with icon / 带图标的文本按钮
TextButton.icon(
  onPressed: () {},
  icon: Icon(Icons.download),
  label: Text('Download'),
)
```

---

### 25. OutlinedButton

**Purpose / 用途**: A material design outlined button.
**用途**: Material Design轮廓按钮。

**Example / 示例**:
```dart
// Simple outlined button / 简单轮廓按钮
OutlinedButton(
  onPressed: () {},
  child: Text('Outlined Button'),
)

// Styled outlined button / 样式轮廓按钮
OutlinedButton(
  onPressed: () {},
  style: OutlinedButton.styleFrom(
    foregroundColor: Colors.blue,
    side: BorderSide(color: Colors.blue, width: 2),  // Border / 边框
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
  ),
  child: Text('Styled Outlined'),
)

// Outlined button with icon / 带图标的轮廓按钮
OutlinedButton.icon(
  onPressed: () {},
  icon: Icon(Icons.logout),
  label: Text('Log Out'),
)
```

---

### 26. IconButton

**Purpose / 用途**: A material design icon button.
**用途**: Material Design图标按钮。

**Example / 示例**:
```dart
// Simple icon button / 简单图标按钮
IconButton(
  icon: Icon(Icons.favorite),
  onPressed: () {
    print('Icon button pressed');
  },
)

// Styled icon button / 样式图标按钮
IconButton(
  icon: Icon(Icons.delete),
  color: Colors.red,
  iconSize: 30,
  tooltip: 'Delete',          // Tooltip on hover / 悬停时提示
  onPressed: () {},
)

// Icon button with background / 带背景的图标按钮
Container(
  decoration: BoxDecoration(
    color: Colors.blue,
    shape: BoxShape.circle,
  ),
  child: IconButton(
    icon: Icon(Icons.add, color: Colors.white),
    onPressed: () {},
  ),
)
```

---

### 27. FloatingActionButton

**Purpose / 用途**: A circular floating action button.
**用途**: 圆形浮动操作按钮。

**Example / 示例**:
```dart
// Simple FAB / 简单FAB
FloatingActionButton(
  onPressed: () {},
  child: Icon(Icons.add),
)

// Extended FAB / 扩展FAB
FloatingActionButton.extended(
  onPressed: () {},
  icon: Icon(Icons.add),
  label: Text('Create'),
)

// Small FAB / 小FAB
FloatingActionButton.small(
  onPressed: () {},
  child: Icon(Icons.edit),
)

// Custom styled FAB / 自定义样式FAB
FloatingActionButton(
  onPressed: () {},
  backgroundColor: Colors.green,
  foregroundColor: Colors.white,
  elevation: 8,
  child: Icon(Icons.check),
)
```

---

## 📱 Display Components / 显示组件

### 28. Card

**Purpose / 用途**: A material design card with elevation and rounded corners.
**用途**: 带阴影和圆角的Material Design卡片。

**Example / 示例**:
```dart
// Simple card / 简单卡片
Card(
  child: Padding(
    padding: EdgeInsets.all(16),
    child: Text('Card content'),
  ),
)

// Styled card / 样式卡片
Card(
  elevation: 4,                              // Shadow depth / 阴影深度
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
  ),
  margin: EdgeInsets.all(8),
  color: Colors.white,
  child: Column(
    children: [
      ListTile(
        leading: Icon(Icons.person),
        title: Text('John Smith'),
        subtitle: Text('john@example.com'),
      ),
      Divider(),
      Padding(
        padding: EdgeInsets.all(16),
        child: Text('Card description goes here'),
      ),
    ],
  ),
)

// Clickable card / 可点击卡片
Card(
  child: InkWell(
    onTap: () {
      print('Card tapped');
    },
    child: Padding(
      padding: EdgeInsets.all(16),
      child: Text('Tap me'),
    ),
  ),
)
```

---

### 29. ListTile

**Purpose / 用途**: A single fixed-height row with leading/trailing widgets.
**用途**: 固定高度的单行，带前导/尾随组件。

**Example / 示例**:
```dart
// Simple list tile / 简单列表项
ListTile(
  title: Text('Title'),
  subtitle: Text('Subtitle'),
)

// List tile with icons / 带图标的列表项
ListTile(
  leading: CircleAvatar(                    // Leading widget / 前导组件
    child: Icon(Icons.person),
  ),
  title: Text('John Smith'),
  subtitle: Text('john@example.com'),
  trailing: Icon(Icons.arrow_forward_ios),  // Trailing widget / 尾随组件
  onTap: () {
    print('Tile tapped');
  },
)

// Three-line list tile / 三行列表项
ListTile(
  leading: Icon(Icons.email),
  title: Text('Email notification'),
  subtitle: Text(
    'You have a new message from John Smith about the upcoming meeting',
    maxLines: 2,
    overflow: TextOverflow.ellipsis,
  ),
  isThreeLine: true,
  trailing: Text('2m ago'),
)
```

---

### 30. Chip

**Purpose / 用途**: A material design chip (label with optional delete).
**用途**: Material Design标签（可选删除）。

**Example / 示例**:
```dart
// Simple chip / 简单标签
Chip(
  label: Text('Tag'),
)

// Chip with avatar / 带头像的标签
Chip(
  avatar: CircleAvatar(
    child: Text('A'),
  ),
  label: Text('Avatar Chip'),
)

// Chip with delete / 带删除的标签
Chip(
  label: Text('Deletable'),
  onDeleted: () {
    print('Chip deleted');
  },
)

// Action chip / 操作标签
ActionChip(
  avatar: Icon(Icons.add, size: 18),
  label: Text('Add'),
  onPressed: () {
    print('Action chip pressed');
  },
)

// Filter chip / 筛选标签
FilterChip(
  label: Text('Filter'),
  selected: _isSelected,
  onSelected: (bool value) {
    setState(() {
      _isSelected = value;
    });
  },
)

// Choice chips / 选择标签
Wrap(
  spacing: 8,
  children: ['Option 1', 'Option 2', 'Option 3'].map((option) {
    return ChoiceChip(
      label: Text(option),
      selected: _selectedOption == option,
      onSelected: (bool selected) {
        setState(() {
          _selectedOption = selected ? option : null;
        });
      },
    );
  }).toList(),
)
```

---

### 31. CircularProgressIndicator

**Purpose / 用途**: A circular progress indicator.
**用途**: 圆形进度指示器。

**Example / 示例**:
```dart
// Indeterminate progress / 不确定进度
CircularProgressIndicator()

// Determinate progress / 确定进度
CircularProgressIndicator(
  value: 0.7,  // 0.0 to 1.0 / 0.0到1.0
)

// Styled progress / 样式进度
CircularProgressIndicator(
  value: 0.5,
  backgroundColor: Colors.grey[300],
  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
  strokeWidth: 6,
)

// Small progress / 小进度
SizedBox(
  width: 20,
  height: 20,
  child: CircularProgressIndicator(strokeWidth: 2),
)
```

---

### 32. LinearProgressIndicator

**Purpose / 用途**: A linear progress indicator.
**用途**: 线性进度指示器。

**Example / 示例**:
```dart
// Indeterminate progress / 不确定进度
LinearProgressIndicator()

// Determinate progress / 确定进度
LinearProgressIndicator(
  value: 0.7,  // 0.0 to 1.0
)

// Styled progress / 样式进度
LinearProgressIndicator(
  value: 0.5,
  backgroundColor: Colors.grey[300],
  valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
  minHeight: 8,
)
```

---

### 33. CircleAvatar

**Purpose / 用途**: A circle that represents a user.
**用途**: 代表用户的圆形头像。

**Example / 示例**:
```dart
// Avatar with initials / 带首字母的头像
CircleAvatar(
  child: Text('JS'),
)

// Colored avatar / 彩色头像
CircleAvatar(
  backgroundColor: Colors.blue,
  foregroundColor: Colors.white,
  child: Text('JS'),
)

// Avatar with image / 带图片的头像
CircleAvatar(
  backgroundImage: NetworkImage('https://example.com/avatar.jpg'),
)

// Sized avatar / 指定尺寸的头像
CircleAvatar(
  radius: 30,
  backgroundColor: Colors.green,
  child: Icon(Icons.person, size: 30, color: Colors.white),
)
```

---

### 34. Badge

**Purpose / 用途**: A small label indicating a count or status.
**用途**: 指示计数或状态的小标签。

**Example / 示例**:
```dart
// Simple badge / 简单徽章
Badge(
  label: Text('3'),
  child: Icon(Icons.notifications),
)

// Styled badge / 样式徽章
Badge(
  label: Text('99+'),
  backgroundColor: Colors.red,
  textColor: Colors.white,
  child: Icon(Icons.email, size: 30),
)

// Badge without label (dot) / 无标签徽章（点）
Badge(
  child: Icon(Icons.message),
)
```

---

## 🧭 Navigation Components / 导航组件

### 35. AppBar

**Purpose / 用途**: A material design app bar (top bar).
**用途**: Material Design应用栏（顶部栏）。

**Example / 示例**:
```dart
Scaffold(
  appBar: AppBar(
    title: Text('Page Title'),
  ),
)

// Styled app bar / 样式应用栏
AppBar(
  title: Text('Title'),
  backgroundColor: Colors.blue,
  foregroundColor: Colors.white,
  leading: IconButton(                      // Left button / 左侧按钮
    icon: Icon(Icons.menu),
    onPressed: () {},
  ),
  actions: [                                // Right buttons / 右侧按钮
    IconButton(
      icon: Icon(Icons.search),
      onPressed: () {},
    ),
    IconButton(
      icon: Icon(Icons.more_vert),
      onPressed: () {},
    ),
  ],
  elevation: 4,                             // Shadow / 阴影
  centerTitle: true,                        // Center title / 居中标题
)

// App bar with bottom tabs / 带底部标签的应用栏
AppBar(
  title: Text('Tabs'),
  bottom: TabBar(
    tabs: [
      Tab(icon: Icon(Icons.home), text: 'Home'),
      Tab(icon: Icon(Icons.search), text: 'Search'),
      Tab(icon: Icon(Icons.person), text: 'Profile'),
    ],
  ),
)
```

---

### 36. BottomNavigationBar

**Purpose / 用途**: A material design bottom navigation bar.
**用途**: Material Design底部导航栏。

**Example / 示例**:
```dart
int _selectedIndex = 0;

Scaffold(
  bottomNavigationBar: BottomNavigationBar(
    currentIndex: _selectedIndex,
    onTap: (int index) {
      setState(() {
        _selectedIndex = index;
      });
    },
    items: [
      BottomNavigationBarItem(
        icon: Icon(Icons.home),
        label: 'Home',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.search),
        label: 'Search',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.person),
        label: 'Profile',
      ),
    ],
  ),
)

// Styled bottom nav / 样式底部导航
BottomNavigationBar(
  currentIndex: _selectedIndex,
  onTap: (index) {
    setState(() => _selectedIndex = index);
  },
  type: BottomNavigationBarType.fixed,      // fixed or shifting / 固定或移动
  selectedItemColor: Colors.blue,           // Selected color / 选中颜色
  unselectedItemColor: Colors.grey,         // Unselected color / 未选中颜色
  backgroundColor: Colors.white,
  elevation: 8,
  items: [...],
)
```

---

### 37. Drawer

**Purpose / 用途**: A material design side drawer menu.
**用途**: Material Design侧边抽屉菜单。

**Example / 示例**:
```dart
Scaffold(
  appBar: AppBar(
    title: Text('Drawer Example'),
  ),
  drawer: Drawer(
    child: ListView(
      padding: EdgeInsets.zero,
      children: [
        // Drawer header / 抽屉头部
        DrawerHeader(
          decoration: BoxDecoration(
            color: Colors.blue,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 30,
                child: Icon(Icons.person, size: 30),
              ),
              SizedBox(height: 10),
              Text(
                'John Smith',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
              Text(
                'john@example.com',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
        // Menu items / 菜单项
        ListTile(
          leading: Icon(Icons.home),
          title: Text('Home'),
          onTap: () {
            Navigator.pop(context);  // Close drawer / 关闭抽屉
          },
        ),
        ListTile(
          leading: Icon(Icons.settings),
          title: Text('Settings'),
          onTap: () {
            Navigator.pop(context);
          },
        ),
        Divider(),
        ListTile(
          leading: Icon(Icons.logout),
          title: Text('Logout'),
          onTap: () {},
        ),
      ],
    ),
  ),
)
```

---

### 38. TabBar & TabBarView

**Purpose / 用途**: Material design tabs for switching between views.
**用途**: Material Design标签，用于切换视图。

**Example / 示例**:
```dart
class _MyPageState extends State<MyPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tabs'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(icon: Icon(Icons.home), text: 'Home'),
            Tab(icon: Icon(Icons.search), text: 'Search'),
            Tab(icon: Icon(Icons.person), text: 'Profile'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          Center(child: Text('Home Tab')),
          Center(child: Text('Search Tab')),
          Center(child: Text('Profile Tab')),
        ],
      ),
    );
  }
}
```

---

## 💬 Dialog Components / 对话框组件

### 39. AlertDialog

**Purpose / 用途**: A material design alert dialog.
**用途**: Material Design警告对话框。

**Example / 示例**:
```dart
// Show alert dialog / 显示警告对话框
void _showAlertDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Alert'),
        content: Text('This is an alert message'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Do something
            },
            child: Text('OK'),
          ),
        ],
      );
    },
  );
}

// Confirmation dialog / 确认对话框
Future<bool?> _showConfirmDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Confirm'),
      content: Text('Are you sure you want to delete this item?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text('Delete'),
          style: TextButton.styleFrom(foregroundColor: Colors.red),
        ),
      ],
    ),
  );
}

// Usage / 使用
final confirmed = await _showConfirmDialog(context);
if (confirmed == true) {
  // Delete item
}
```

---

### 40. SimpleDialog

**Purpose / 用途**: A simple dialog with a list of options.
**用途**: 带选项列表的简单对话框。

**Example / 示例**:
```dart
Future<String?> _showSimpleDialog(BuildContext context) {
  return showDialog<String>(
    context: context,
    builder: (BuildContext context) {
      return SimpleDialog(
        title: Text('Select an option'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'Option 1'),
            child: Text('Option 1'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'Option 2'),
            child: Text('Option 2'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'Option 3'),
            child: Text('Option 3'),
          ),
        ],
      );
    },
  );
}
```

---

### 41. BottomSheet

**Purpose / 用途**: A material design bottom sheet.
**用途**: Material Design底部表单。

**Example / 示例**:
```dart
// Modal bottom sheet / 模态底部表单
void _showModalBottomSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    builder: (BuildContext context) {
      return Container(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.share),
              title: Text('Share'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.link),
              title: Text('Copy link'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.edit),
              title: Text('Edit'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      );
    },
  );
}

// Persistent bottom sheet / 持久底部表单
void _showPersistentBottomSheet(BuildContext context) {
  Scaffold.of(context).showBottomSheet(
    (BuildContext context) {
      return Container(
        height: 200,
        color: Colors.grey[200],
        child: Center(
          child: Text('Persistent Bottom Sheet'),
        ),
      );
    },
  );
}
```

---

### 42. SnackBar

**Purpose / 用途**: A brief message at the bottom of the screen.
**用途**: 屏幕底部的简短消息。

**Example / 示例**:
```dart
// Simple snackbar / 简单提示条
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text('Message sent'),
  ),
)

// Snackbar with action / 带操作的提示条
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text('Item deleted'),
    action: SnackBarAction(
      label: 'Undo',
      onPressed: () {
        // Undo action
      },
    ),
    duration: Duration(seconds: 3),
  ),
)

// Styled snackbar / 样式提示条
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text('Error occurred'),
    backgroundColor: Colors.red,
    behavior: SnackBarBehavior.floating,    // floating or fixed / 浮动或固定
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
    ),
    margin: EdgeInsets.all(16),
  ),
)
```

---

## 📋 List Components / 列表组件

### 43. ListView

**Purpose / 用途**: A scrollable list of widgets.
**用途**: 可滚动的组件列表。

**Example / 示例**:
```dart
// Simple ListView / 简单列表
ListView(
  children: [
    ListTile(title: Text('Item 1')),
    ListTile(title: Text('Item 2')),
    ListTile(title: Text('Item 3')),
  ],
)

// ListView.builder (efficient for large lists) / ListView.builder（大列表高效）
ListView.builder(
  itemCount: 100,
  itemBuilder: (context, index) {
    return ListTile(
      title: Text('Item $index'),
    );
  },
)

// ListView.separated (with dividers) / ListView.separated（带分隔线）
ListView.separated(
  itemCount: 20,
  itemBuilder: (context, index) {
    return ListTile(
      title: Text('Item $index'),
    );
  },
  separatorBuilder: (context, index) {
    return Divider();
  },
)

// Horizontal ListView / 水平列表
ListView(
  scrollDirection: Axis.horizontal,
  children: [
    Container(width: 100, color: Colors.red),
    Container(width: 100, color: Colors.green),
    Container(width: 100, color: Colors.blue),
  ],
)
```

---

### 44. GridView

**Purpose / 用途**: A scrollable grid of widgets.
**用途**: 可滚动的组件网格。

**Example / 示例**:
```dart
// Grid with fixed columns / 固定列数的网格
GridView.count(
  crossAxisCount: 3,              // Number of columns / 列数
  crossAxisSpacing: 10,           // Horizontal spacing / 水平间距
  mainAxisSpacing: 10,            // Vertical spacing / 垂直间距
  children: List.generate(20, (index) {
    return Container(
      color: Colors.blue,
      child: Center(child: Text('$index')),
    );
  }),
)

// Grid with max tile width / 最大瓦片宽度的网格
GridView.extent(
  maxCrossAxisExtent: 150,        // Max tile width / 最大瓦片宽度
  children: List.generate(20, (index) {
    return Card(
      child: Center(child: Text('Item $index')),
    );
  }),
)

// Grid builder / 网格构建器
GridView.builder(
  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 2,
    childAspectRatio: 1.5,        // Width/height ratio / 宽高比
  ),
  itemCount: 50,
  itemBuilder: (context, index) {
    return Card(
      child: Center(child: Text('Item $index')),
    );
  },
)
```

---

### 45. SingleChildScrollView

**Purpose / 用途**: A scrollable box for a single child.
**用途**: 单个子组件的可滚动盒子。

**Example / 示例**:
```dart
// Vertical scroll / 垂直滚动
SingleChildScrollView(
  child: Column(
    children: [
      Container(height: 500, color: Colors.red),
      Container(height: 500, color: Colors.green),
      Container(height: 500, color: Colors.blue),
    ],
  ),
)

// Horizontal scroll / 水平滚动
SingleChildScrollView(
  scrollDirection: Axis.horizontal,
  child: Row(
    children: [
      Container(width: 300, color: Colors.red),
      Container(width: 300, color: Colors.green),
      Container(width: 300, color: Colors.blue),
    ],
  ),
)

// With padding / 带内边距
SingleChildScrollView(
  padding: EdgeInsets.all(16),
  child: Column(
    children: [...],
  ),
)
```

---

## 🖼️ Image & Media / 图片和媒体

### 46. Asset Images

**Purpose / 用途**: Loading images from app assets.
**用途**: 从应用资源加载图片。

**Setup in pubspec.yaml / 在pubspec.yaml中设置**:
```yaml
flutter:
  assets:
    - assets/images/
    - assets/icons/
```

**Example / 示例**:
```dart
// Load image from assets / 从资源加载图片
Image.asset('assets/images/logo.png')

// Sized image / 指定尺寸
Image.asset(
  'assets/images/banner.jpg',
  width: 300,
  height: 200,
  fit: BoxFit.cover,
)
```

---

### 47. Network Images

**Purpose / 用途**: Loading images from URLs.
**用途**: 从URL加载图片。

**Example / 示例**:
```dart
// Basic network image / 基础网络图片
Image.network('https://example.com/image.jpg')

// With loading and error handling / 带加载和错误处理
Image.network(
  'https://example.com/image.jpg',
  loadingBuilder: (context, child, loadingProgress) {
    if (loadingProgress == null) return child;
    return Center(
      child: CircularProgressIndicator(
        value: loadingProgress.expectedTotalBytes != null
            ? loadingProgress.cumulativeBytesLoaded /
                loadingProgress.expectedTotalBytes!
            : null,
      ),
    );
  },
  errorBuilder: (context, error, stackTrace) {
    return Center(
      child: Icon(Icons.error, color: Colors.red, size: 50),
    );
  },
)

// Cached network image (requires package) / 缓存网络图片（需要包）
// Add to pubspec.yaml: cached_network_image: ^3.3.0
CachedNetworkImage(
  imageUrl: 'https://example.com/image.jpg',
  placeholder: (context, url) => CircularProgressIndicator(),
  errorWidget: (context, url, error) => Icon(Icons.error),
)
```

---

## 👆 Gesture & Interaction / 手势和交互

### 48. GestureDetector

**Purpose / 用途**: Detects gestures on any widget.
**用途**: 检测任何组件上的手势。

**Example / 示例**:
```dart
// Tap / 点击
GestureDetector(
  onTap: () {
    print('Tapped');
  },
  child: Container(
    padding: EdgeInsets.all(16),
    color: Colors.blue,
    child: Text('Tap me'),
  ),
)

// Double tap / 双击
GestureDetector(
  onDoubleTap: () {
    print('Double tapped');
  },
  child: Container(...),
)

// Long press / 长按
GestureDetector(
  onLongPress: () {
    print('Long pressed');
  },
  child: Container(...),
)

// Multiple gestures / 多个手势
GestureDetector(
  onTap: () => print('Tap'),
  onDoubleTap: () => print('Double tap'),
  onLongPress: () => print('Long press'),
  onPanUpdate: (details) {
    print('Pan: ${details.delta}');
  },
  child: Container(
    width: 200,
    height: 200,
    color: Colors.blue,
    child: Center(child: Text('Gesture Area')),
  ),
)
```

---

### 49. InkWell

**Purpose / 用途**: A rectangular area that responds to touch with ripple effect.
**用途**: 带波纹效果响应触摸的矩形区域。

**Example / 示例**:
```dart
// InkWell with ripple / 带波纹的InkWell
InkWell(
  onTap: () {
    print('Tapped with ripple');
  },
  child: Padding(
    padding: EdgeInsets.all(16),
    child: Text('Tap for ripple effect'),
  ),
)

// Custom ripple color / 自定义波纹颜色
InkWell(
  onTap: () {},
  splashColor: Colors.blue.withOpacity(0.3),
  highlightColor: Colors.blue.withOpacity(0.1),
  child: Container(
    padding: EdgeInsets.all(16),
    child: Text('Custom ripple'),
  ),
)

// Circular InkWell / 圆形InkWell
Ink(
  decoration: ShapeDecoration(
    color: Colors.blue,
    shape: CircleBorder(),
  ),
  child: InkWell(
    onTap: () {},
    customBorder: CircleBorder(),
    child: Padding(
      padding: EdgeInsets.all(16),
      child: Icon(Icons.add, color: Colors.white),
    ),
  ),
)
```

---

### 50. Dismissible

**Purpose / 用途**: A widget that can be dismissed by dragging.
**用途**: 可通过拖动消除的组件。

**Example / 示例**:
```dart
// Swipe to dismiss / 滑动删除
Dismissible(
  key: Key('item_$index'),
  onDismissed: (direction) {
    setState(() {
      items.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Item dismissed')),
    );
  },
  background: Container(
    color: Colors.red,
    alignment: Alignment.centerLeft,
    padding: EdgeInsets.only(left: 20),
    child: Icon(Icons.delete, color: Colors.white),
  ),
  child: ListTile(
    title: Text('Swipe to delete'),
  ),
)

// Swipe with confirmation / 滑动带确认
Dismissible(
  key: Key('item_$index'),
  confirmDismiss: (direction) async {
    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm'),
        content: Text('Delete this item?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete'),
          ),
        ],
      ),
    );
  },
  background: Container(color: Colors.red),
  child: ListTile(title: Text('Item')),
)
```

---

## 🎓 Summary / 总结

This guide covers the fundamental Flutter components used in everyday app development. Each component has been explained with:

本指南涵盖了日常应用开发中使用的基础Flutter组件。每个组件都包含了：

- **Purpose / 用途** - What the component is for
- **Common Use Cases / 常用场景** - When to use it
- **Code Examples / 代码示例** - How to implement it
- **Visual Diagrams / 视觉图表** - How it looks (where applicable)

### Quick Component Reference / 组件快速参考

**Layout / 布局**: Container, Column, Row, Stack, Padding, Center, Align, SizedBox, Expanded, Flexible

**Basic / 基础**: Text, Icon, Image, Divider, Spacer

**Input / 输入**: TextField, TextFormField, Checkbox, Radio, Switch, Slider, DropdownButton

**Buttons / 按钮**: ElevatedButton, TextButton, OutlinedButton, IconButton, FloatingActionButton

**Display / 显示**: Card, ListTile, Chip, CircularProgressIndicator, LinearProgressIndicator, CircleAvatar, Badge

**Navigation / 导航**: AppBar, BottomNavigationBar, Drawer, TabBar

**Dialogs / 对话框**: AlertDialog, SimpleDialog, BottomSheet, SnackBar

**Lists / 列表**: ListView, GridView, SingleChildScrollView

**Gestures / 手势**: GestureDetector, InkWell, Dismissible

---

**For More Information / 更多信息**:
- Official Flutter Documentation: https://flutter.dev/docs
- Flutter Widget Catalog: https://flutter.dev/docs/development/ui/widgets

**Last Updated / 最后更新**: 2026-01-08
**Version / 版本**: 1.0.0
