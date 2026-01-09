# Complete Kiosk Mode Guide

## 概述 / Overview

本指南涵盖在Android和iOS设备上设置完整kiosk模式的所有信息。
This guide covers everything you need to set up complete kiosk mode on Android and iOS devices.

---

## 重要说明 / Important Notice

⚠️ **应用层限制 / App-Level Limitations**

Flutter应用**无法完全阻止**系统级操作:
- Android: 主页键、最近应用键
- iOS: 主屏幕手势、控制中心

Flutter apps **CANNOT completely block** system-level operations:
- Android: Home button, Recent apps button
- iOS: Home gesture, Control Center

✅ **应用已提供的保护 / App-Level Protection Already Implemented:**
- 返回键拦截 + 警告 / Back button interception + warnings
- 边缘手势检测 / Edge gesture detection
- 沉浸式模式 / Immersive mode
- 防休眠 / Screen wakelock
- 生命周期管理 / Lifecycle management

✅ **完整锁定需要 / Full Lockdown Requires:**
- **Android**: 屏幕固定 或 锁定任务模式 / Screen Pinning OR Lock Task Mode
- **iOS**: 引导式访问 / Guided Access

---

## 快速开始 / Quick Start

### Android 设备 / Android Devices

**消费级设备 (最简单) / Consumer Devices (Easiest):**
```
1. 设置 → 安全 → 屏幕固定
   Settings → Security → Screen pinning

2. 启用"取消固定前需要输入PIN"
   Enable "Ask for PIN before unpinning"

3. 在应用中: 最近应用 → 点击应用图标 → 固定
   In app: Recent apps → Tap app icon → Pin
```

**企业设备 / Enterprise Devices:**
```
使用MDM推送锁定任务模式配置
Use MDM to push Lock Task Mode configuration
```

📖 详细指南 / Detailed Guide:
- [Android配置指南 (中文)](./ANDROID_KIOSK_SETUP_CN.md)
- [Android Setup Guide (English)](./ANDROID_KIOSK_SETUP.md)

---

### iOS/iPadOS 设备 / iOS/iPadOS Devices

**所有设备 (统一方法) / All Devices (Universal Method):**
```
1. 设置 → 辅助功能 → 引导式访问
   Settings → Accessibility → Guided Access

2. 启用并设置密码
   Enable and set passcode

3. 在应用中: 三次按侧边按钮 → 开始
   In app: Triple-click side button → Start
```

📖 详细指南 / Detailed Guide:
- [iOS配置指南 (中文)](./IOS_KIOSK_SETUP_CN.md)
- [iOS Setup Guide (English)](./IOS_KIOSK_SETUP.md)

---

## 功能对比 / Feature Comparison

| 功能<br>Feature | 仅应用保护<br>App Only | Android屏幕固定<br>Screen Pinning | Android锁定任务<br>Lock Task | iOS引导式访问<br>Guided Access |
|----------------|-------------------|------------------------------|---------------------------|----------------------------|
| 阻止返回键<br>Block Back Button | ⚠️ 警告<br>Warning | ✅ 完全阻止<br>Fully Blocked | ✅ 完全阻止<br>Fully Blocked | ✅ 完全阻止<br>Fully Blocked |
| 阻止主页键<br>Block Home Button | ❌ 无法阻止<br>Cannot Block | ✅ 完全阻止<br>Fully Blocked | ✅ 完全阻止<br>Fully Blocked | ✅ 完全阻止<br>Fully Blocked |
| 阻止手势导航<br>Block Gestures | ⚠️ 检测+警告<br>Detect+Warn | ✅ 完全阻止<br>Fully Blocked | ✅ 完全阻止<br>Fully Blocked | ✅ 完全阻止<br>Fully Blocked |
| 设置复杂度<br>Setup Complexity | ✅ 无需设置<br>No Setup | 🟡 简单<br>Easy | 🔴 复杂<br>Complex | 🟡 简单<br>Easy |
| 需要密码<br>Requires Password | ✅ 应用内<br>In-App | 🟡 可选<br>Optional | ✅ 是<br>Yes | ✅ 是<br>Yes |
| 远程管理<br>Remote Management | ❌ 不支持<br>No | ❌ 不支持<br>No | ✅ 通过MDM<br>Via MDM | ✅ 通过MDM<br>Via MDM |

---

## 推荐设置 / Recommended Setup

### 场景1: 临时演示 / Scenario 1: Temporary Demo
```
✅ 使用: 仅应用保护
   Use: App protection only

说明: 无需额外配置，但用户可以退出
Note: No extra setup, but users can exit
```

### 场景2: 单台设备永久部署 / Scenario 2: Single Device Permanent
```
✅ Android: 屏幕固定 + PIN
   Android: Screen Pinning + PIN

✅ iOS: 引导式访问 + 密码
   iOS: Guided Access + Passcode
```

### 场景3: 多台设备 (< 10台) / Scenario 3: Multiple Devices (< 10)
```
✅ Android: Kiosk启动器 (如Fully Kiosk)
   Android: Kiosk Launcher (e.g., Fully Kiosk)

✅ iOS: 引导式访问 + 辅助功能快捷键
   iOS: Guided Access + Accessibility Shortcut
```

### 场景4: 企业大规模部署 / Scenario 4: Enterprise Large-Scale
```
✅ Android: 锁定任务模式 + MDM
   Android: Lock Task Mode + MDM

✅ iOS: 引导式访问 + Apple Business Manager + MDM
   iOS: Guided Access + Apple Business Manager + MDM
```

---

## 测试清单 / Testing Checklist

在部署前测试以下所有项目:
Test all items before deployment:

### 应用层保护测试 / App-Level Protection Test
- [ ] 按返回键 → 显示警告 / Press back button → Shows warning
- [ ] 从边缘滑动 → 显示警告 / Swipe from edge → Shows warning
- [ ] 屏幕保持唤醒 / Screen stays awake
- [ ] 沉浸式模式正常 / Immersive mode works

### 系统级保护测试 / System-Level Protection Test
- [ ] 主页键被阻止 / Home button blocked
- [ ] 最近应用被阻止 / Recent apps blocked
- [ ] 通知栏被阻止 / Notification shade blocked
- [ ] 控制中心被阻止(iOS) / Control Center blocked (iOS)
- [ ] 快捷设置被阻止(Android) / Quick settings blocked (Android)

### 退出机制测试 / Exit Mechanism Test
- [ ] 管理员登录功能正常 / Admin sign-in works
- [ ] 管理员密码验证正确 / Admin password validates
- [ ] 退出后返回仪表板 / Returns to dashboard after exit
- [ ] 系统级解锁功能正常 / System-level unlock works
  - Android: PIN解除固定 / PIN unpinning
  - iOS: 密码退出引导式访问 / Passcode exit Guided Access

---

## 常见问题 / FAQ

### Q1: 为什么不能阻止所有退出方式？ / Why can't the app block all exit methods?

**A:** iOS和Android出于安全原因限制应用权限。完全锁定需要系统级配置。
**A:** iOS and Android limit app permissions for security. Full lockdown requires system-level configuration.

### Q2: 用户忘记管理员密码怎么办？ / What if admin password is forgotten?

**Android屏幕固定:** 使用系统PIN解除
**Android Screen Pinning:** Use system PIN to unpin

**iOS引导式访问:** 使用引导式访问密码退出
**iOS Guided Access:** Use Guided Access passcode to exit

**应用密码:** 联系IT管理员重置
**App Password:** Contact IT admin to reset

### Q3: 设备重启后还在kiosk模式吗？ / Does device stay in kiosk after reboot?

**屏幕固定/引导式访问:** ❌ 需要重新启用
**Screen Pinning/Guided Access:** ❌ Need to re-enable

**锁定任务模式(MDM):** ✅ 自动恢复
**Lock Task Mode (MDM):** ✅ Auto-restores

**Kiosk启动器:** ✅ 自动启动
**Kiosk Launcher:** ✅ Auto-launches

### Q4: 可以远程退出kiosk模式吗？ / Can I exit kiosk mode remotely?

**使用MDM:** ✅ 是的
**With MDM:** ✅ Yes

**不使用MDM:** ❌ 需要物理访问设备
**Without MDM:** ❌ Requires physical access to device

### Q5: 如何更新锁定模式下的应用？ / How to update app in locked mode?

1. 退出kiosk模式 / Exit kiosk mode
2. 更新应用 / Update app
3. 重新启用kiosk模式 / Re-enable kiosk mode

**或使用MDM自动更新(企业)** / **Or use MDM auto-update (Enterprise)**

---

## 安全建议 / Security Recommendations

🔒 **基础安全 / Basic Security:**
- ✓ 设置管理员密码 / Set admin password
- ✓ 启用PIN/密码保护 / Enable PIN/passcode protection
- ✓ 定期更新应用 / Regularly update app

🔒 **中级安全 / Medium Security:**
- ✓ 禁用通知访问 / Disable notification access
- ✓ 使用kiosk启动器 / Use kiosk launcher
- ✓ 网络访问控制 / Network access control

🔒 **高级安全 / Advanced Security:**
- ✓ 使用MDM集中管理 / Use MDM for centralized management
- ✓ 启用远程锁定/擦除 / Enable remote lock/wipe
- ✓ 物理安全(支架/外壳) / Physical security (mount/enclosure)
- ✓ 网络隔离 / Network isolation

---

## 支持与文档 / Support & Documentation

📖 **详细文档 / Detailed Docs:**
- [Android Kiosk Setup (CN)](./ANDROID_KIOSK_SETUP_CN.md)
- [Android Kiosk Setup (EN)](./ANDROID_KIOSK_SETUP.md)
- [iOS Kiosk Setup (CN)](./IOS_KIOSK_SETUP_CN.md)
- [iOS Kiosk Setup (EN)](./IOS_KIOSK_SETUP.md)
- [Original Kiosk Mode Documentation](../KIOSK_MODE_DOCUMENTATION.md)

🛠️ **技术实现 / Technical Implementation:**
- `lib/widgets/kiosk_guard.dart` - Kiosk保护组件 / Kiosk guard component
- `lib/services/kiosk_mode_service.dart` - Kiosk服务 / Kiosk service

📧 **技术支持 / Technical Support:**
- 应用问题: 联系开发团队 / App issues: Contact dev team
- 设备配置: 联系IT管理员 / Device config: Contact IT admin
- MDM问题: 联系MDM供应商 / MDM issues: Contact MDM vendor

---

## 版本历史 / Version History

**v1.0** (2026-01-09)
- ✓ 应用层kiosk保护 / App-level kiosk protection
- ✓ PopScope返回键拦截 / PopScope back button interception
- ✓ 手势检测和警告 / Gesture detection and warnings
- ✓ 沉浸式模式 / Immersive mode
- ✓ 完整配置文档 / Complete setup documentation

---

## 总结 / Summary

| 需要 / Need | 解决方案 / Solution |
|------------|-------------------|
| 🎯 快速测试 / Quick Test | 仅应用保护 / App protection only |
| 🎯 单设备 / Single Device | 屏幕固定+PIN / 引导式访问+密码<br>Screen Pinning+PIN / Guided Access+Passcode |
| 🎯 多设备 / Multiple Devices | Kiosk启动器 / Kiosk Launcher |
| 🎯 企业 / Enterprise | MDM + 锁定任务 / 引导式访问<br>MDM + Lock Task / Guided Access |

⚠️ **关键点 / Key Point:** 应用无法强制系统级kiosk，需要设备配置。
⚠️ **Key Point:** Apps cannot force system-level kiosk. Device configuration required.

✅ **最佳实践 / Best Practice:** 应用保护 + 系统锁定 = 完整安全
✅ **Best Practice:** App Protection + System Lockdown = Complete Security
