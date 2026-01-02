# Worx Visitor App - Technical Documentation

## Table of Contents
1. [Overview](#overview)
2. [Recent Features](#recent-features)
3. [Kiosk Mode Implementation](#kiosk-mode-implementation)
4. [Device Configuration](#device-configuration)
5. [Architecture Explanation](#architecture-explanation)

---

## Overview

This document explains all the features implemented in the Worx Visitor App, with a focus on kiosk mode functionality, responsive design, and user experience improvements.

**Target Devices:** iOS (iPad) and Android (Tablets)

---

## Recent Features

### 1. Searchable Contact/Visitor Selection

#### What It Does
Allows users to search and select contacts or visitors by typing their name, making the process faster when there are many options.

#### Where It's Used
- **Visitor Sign In** → "Person Visiting" field
- **Visitor Sign Out** → "Select from Signed-In Visitors" dialog

#### How It Works

**Sign In - Person Visiting:**
1. User clicks the "Person Visiting" dropdown-style button
2. A dialog opens with:
   - Search field at the top (first row)
   - Real-time filtered contact list
   - Shows contact count
3. User types to search by name or email
4. Selects contact by clicking
5. Dialog closes and shows selected contact

**Sign Out - Visitor Selection:**
1. User clicks "Select from Signed-In Visitors" button
2. Dialog opens with same search functionality
3. Filters by visitor name, email, or ID
4. User selects visitor to sign out

**Key Code Files:**
- `lib/features/visitor_sign_in/views/visitor_sign_in_page.dart` (lines 950-1090)
- `lib/features/visitor_sign_out/views/visitor_sign_out_page.dart` (lines 710-980)

**Implementation Details:**
```dart
// Contact Selector Dialog (_ContactSelectorDialog)
// - Stateful widget with search controller
// - Real-time filtering using .where() method
// - Responsive design using MediaQuery
// - Auto-focus on desktop, manual on mobile

final filteredContacts = widget.contacts.where((contact) {
  if (_searchQuery.isEmpty) return true;
  final query = _searchQuery.toLowerCase();
  return contact.name.toLowerCase().contains(query) ||
         contact.email.toLowerCase().contains(query);
}).toList();
```

---

### 2. Dynamic Company Name in Site Questions

#### What It Does
Instead of hardcoding "Pink Batteries" in safety questions, the system now uses the actual company name from the client configuration.

#### How It Works

**Priority Order:**
1. Try `trading_name` from client data
2. Fall back to `name` if trading_name is empty
3. Use "the company" as final fallback

**Example Questions:**
- Before: "Be escorted by an authorised **Pink Batteries** representative at all times."
- After: "Be escorted by an authorised **[Your Company]** representative at all times."

**Key Code Files:**
- `lib/features/visitor_sign_in/models/site_question.dart`

**Implementation Details:**
```dart
// Changed from static getter to async method
static Future<List<SiteQuestion>> getDefaultQuestions() async {
  String companyName = 'the company';
  try {
    final clientJson = await SecureStorageService.getClient();
    if (clientJson != null && clientJson.isNotEmpty) {
      final client = jsonDecode(clientJson) as Map<String, dynamic>;
      companyName = client['trading_name']?.toString().trim() ??
                    client['name']?.toString().trim() ??
                    'the company';
    }
  } catch (e) {
    companyName = 'the company';
  }

  return [
    // ... questions using $companyName variable
  ];
}
```

**Where Client Data Comes From:**
- Fetched from API during login/setup
- Stored in `SecureStorageService` (Flutter Secure Storage)
- JSON format: `{ "name": "Company ABC", "trading_name": "ABC Corp" }`

---

### 3. Unified Responsive Breakpoints

#### What It Does
Centralizes all responsive design logic in one place, making the app consistent across different screen sizes.

#### Breakpoint Values

**Screen Size Breakpoints:**
- `md = 600px` → Tablet portrait (mobile/tablet boundary)
- `lg = 1000px` → Tablet landscape / Small desktop
- `xl = 1440px` → Large desktop

**Content Max Widths:**
- `compact = 420px` → Kiosk buttons, simple forms
- `standard = 620px` → Visitor forms
- `wide = 720px` → Dashboard, admin pages
- `max = 1200px` → Full desktop content

#### Key Code Files
- `lib/core/responsive/app_breakpoints.dart`

#### Helper Methods

```dart
// Check screen size
AppBreakpoints.isSmallScreen(width)  // < 600px
AppBreakpoints.isMediumScreen(width) // 600-1000px
AppBreakpoints.isLargeScreen(width)  // >= 1000px

// Get dialog dimensions
AppBreakpoints.getDialogWidth(width)      // 95% on mobile, 500px desktop
AppBreakpoints.getDialogMaxWidth(width)   // 95% on mobile, 600px desktop
AppBreakpoints.getDialogHeight(height)    // 70% of screen height
```

#### Usage Example

**Before (Hardcoded):**
```dart
final isSmallScreen = screenWidth < 600;
final dialogWidth = isSmallScreen ? screenWidth * 0.95 : 500.0;
final dialogHeight = screenHeight * 0.7;
```

**After (Using Breakpoints):**
```dart
final isSmallScreen = AppBreakpoints.isSmallScreen(screenWidth);
final dialogMaxWidth = AppBreakpoints.getDialogMaxWidth(screenWidth);
final dialogHeight = AppBreakpoints.getDialogHeight(screenHeight);
```

#### Why This Matters
- **Consistency:** All dialogs use same responsive logic
- **Maintainability:** Change once, applies everywhere
- **Readability:** Code is self-documenting
- **Scalability:** Easy to add new breakpoints

---

## Kiosk Mode Implementation

### What Is Kiosk Mode?

Kiosk mode turns a tablet into a dedicated visitor sign-in station by:
1. **Keeping the screen awake** (prevents auto-sleep)
2. **Locking the app** (prevents users from exiting or switching apps)

### Component 1: Keep Screen Awake (Wakelock)

#### What It Does
Prevents the device screen from turning off due to inactivity, ensuring the kiosk is always ready for visitors.

#### How It's Implemented

**Technology Used:**
- `wakelock_plus` Flutter package (v1.2.8)
- Cross-platform (iOS & Android)

**Key Code Files:**
- `lib/services/kiosk_mode_service.dart` → Service class
- `lib/features/visitor_kiosk/views/visitor_kiosk_page.dart` → Integration

**Service Architecture:**

```dart
class KioskModeService {
  // Enable wakelock (keep screen awake)
  static Future<void> enableWakelock() async {
    await WakelockPlus.enable();
  }

  // Disable wakelock (allow screen to sleep)
  static Future<void> disableWakelock() async {
    await WakelockPlus.disable();
  }

  // Check if wakelock is active
  static Future<bool> isWakelockEnabled() async {
    return await WakelockPlus.enabled;
  }
}
```

**Integration in Kiosk Page:**

```dart
class _VisitorDashboardState extends State<VisitorDashboard> {
  @override
  void initState() {
    super.initState();
    // Enable wakelock when entering kiosk mode
    KioskModeService.enableWakelock();
  }

  @override
  void dispose() {
    // Disable wakelock when leaving kiosk mode
    KioskModeService.disableWakelock();
    super.dispose();
  }
}
```

#### Why This Design?

**Lifecycle Management:**
- `initState()` → Called when widget is created (page opens)
- `dispose()` → Called when widget is destroyed (page closes)
- This ensures wakelock is active only when needed

**Persistence:**
- Wakelock remains active while navigating to sign-in/sign-out pages
- Only disabled when returning to dashboard or closing app

**Debug Logging:**
- Service prints status messages to console
- Format: `✓ Kiosk Mode: Wakelock enabled - screen will stay awake`

---

### Component 2: App Lock (Device Configuration)

#### What It Does
Prevents users from exiting the app or switching to other apps, creating a true kiosk experience.

#### Implementation Method

**✅ Recommended: Device-Level Configuration**

We use native OS features instead of app-level code because:
- More reliable (cannot be bypassed)
- Simpler to implement
- No special permissions needed in app
- Better security

---

## Device Configuration

### iOS (iPad) - Guided Access

#### What Is Guided Access?
A built-in iOS feature that locks the device to a single app and disables certain screen areas.

#### Setup Steps

**1. Enable Guided Access**
```
Settings → Accessibility → Guided Access → Toggle ON
```

**2. Set Passcode**
```
Guided Access → Passcode Settings → Set Guided Access Passcode
(Choose a 4-6 digit passcode)
```

**3. Configure Accessibility Shortcut**
```
Settings → Accessibility → Accessibility Shortcut → Select "Guided Access"
```

**4. Activate Guided Access**
```
1. Open Worx Visitor App
2. Triple-click the Home button (or Side button on newer iPads)
3. Tap "Options" (bottom left)
4. Configure restrictions:
   ✓ Sleep/Wake Button: OFF
   ✓ Volume Buttons: OFF (optional)
   ✓ Motion: OFF (optional)
   ✓ Touch: ON (required for app interaction)
5. Tap "Done" → Tap "Start"
```

**5. Exit Guided Access (Admin Only)**
```
1. Triple-click Home button (or Side button)
2. Enter passcode
3. Tap "End"
```

#### Best Practices
- Use a secure passcode (not 0000 or 1234)
- Test touch responsiveness before deploying
- Disable hardware buttons to prevent accidental exits
- Keep passcode in secure location for admin access

---

### Android (Tablets) - Screen Pinning / Kiosk Mode

#### Option 1: Screen Pinning (Simple)

**What Is Screen Pinning?**
Locks device to a single app until unpinned.

**Setup Steps**

**1. Enable Screen Pinning**
```
Settings → Security → Advanced → Screen Pinning → Toggle ON
```

**2. Require PIN to Unpin (Recommended)**
```
Settings → Security → Screen Pinning → Ask for PIN before unpinning: ON
```

**3. Pin the App**
```
1. Open Worx Visitor App
2. Tap Recent Apps button (square icon)
3. Swipe up on app card to see icon at top
4. Tap the Pin icon (📌)
5. Tap "Got it"
```

**4. Unpin the App (Admin Only)**
```
1. Press Back + Recent Apps buttons simultaneously
   OR
   Swipe up and hold (on gesture navigation)
2. Enter PIN if required
```

#### Option 2: Kiosk Mode (Advanced)

**What Is Kiosk Mode?**
Full-featured kiosk solution with more control (requires MDM or special setup).

**Common Methods:**
- **Samsung Knox:** Enterprise-grade kiosk mode
- **Android Enterprise:** Managed devices with kiosk configuration
- **Third-party MDM:** Solutions like AirWatch, MobileIron

**Typical Features:**
- Lock to single app permanently
- Disable status bar pull-down
- Hide navigation buttons
- Prevent settings access
- Remote management

**When to Use:**
- Large deployments (10+ devices)
- High-security requirements
- Need remote management
- Corporate/enterprise environment

**Setup:**
*Varies by MDM solution - consult your IT department or MDM documentation*

---

## Architecture Explanation

### How Everything Works Together

```
┌─────────────────────────────────────────────────────────────┐
│                     Device Level (OS)                        │
│  - Guided Access (iOS) or Screen Pinning (Android)          │
│  - Prevents app exit and hardware button usage               │
└──────────────────────────┬──────────────────────────────────┘
                           │
┌──────────────────────────▼──────────────────────────────────┐
│                   Application Level                          │
│                                                               │
│  ┌────────────────────────────────────────────────────┐     │
│  │  KioskModeService (Wakelock Management)            │     │
│  │  - Keeps screen awake during kiosk session         │     │
│  │  - Lifecycle: initState → dispose                  │     │
│  └────────────────────────────────────────────────────┘     │
│                                                               │
│  ┌────────────────────────────────────────────────────┐     │
│  │  AppBreakpoints (Responsive Design)                │     │
│  │  - Unified breakpoint definitions                  │     │
│  │  - Dialog sizing helpers                           │     │
│  │  - Screen size detection                           │     │
│  └────────────────────────────────────────────────────┘     │
│                                                               │
│  ┌────────────────────────────────────────────────────┐     │
│  │  Search Functionality                              │     │
│  │  - Contact selector dialogs                        │     │
│  │  - Real-time filtering                             │     │
│  │  - Responsive layouts                              │     │
│  └────────────────────────────────────────────────────┘     │
│                                                               │
│  ┌────────────────────────────────────────────────────┐     │
│  │  Dynamic Content                                   │     │
│  │  - Company name from client config                 │     │
│  │  - Site questions customization                    │     │
│  └────────────────────────────────────────────────────┘     │
└───────────────────────────────────────────────────────────┘
```

### Data Flow Example: Visitor Sign-In

```
1. User opens app → Kiosk page loads
   ├─ KioskModeService.enableWakelock() called
   └─ Screen stays awake

2. User taps "Visitor Sign In"
   └─ Navigates to Sign In page (wakelock remains active)

3. User fills form → Needs to select "Person Visiting"
   ├─ Clicks dropdown-style button
   ├─ Dialog opens with search field
   ├─ AppBreakpoints determines dialog size
   │  └─ Small screen: 95% width, Large screen: 600px max
   ├─ Contact list loads from SecureStorageService
   └─ SiteQuestion.getDefaultQuestions() fetches company name

4. User searches "John"
   ├─ Search query filters contacts in real-time
   ├─ filteredContacts = contacts.where(name.contains("john"))
   └─ List updates instantly

5. User selects contact → Dialog closes
   └─ Selected contact stored in state

6. User completes form → Submits
   ├─ Site questions show with company name
   │  └─ "Be escorted by [Company Name] representative"
   └─ Badge generated and printed

7. User returns to kiosk page
   └─ Wakelock remains active for next visitor

8. Admin exits kiosk (navigates to dashboard)
   └─ dispose() called → KioskModeService.disableWakelock()
```

### Why This Architecture?

**Separation of Concerns:**
- **KioskModeService:** Hardware behavior (screen sleep)
- **AppBreakpoints:** UI layout logic
- **Dialog widgets:** User interaction
- **Data models:** Business logic

**Lifecycle Management:**
- Wakelock tied to widget lifecycle
- Automatic cleanup on navigation
- No manual management needed

**Testability:**
- Each component can be tested independently
- Services use static methods (easy to mock)
- Clear dependencies

**Maintainability:**
- Single source of truth for each concern
- Changes in one area don't affect others
- Clear code organization

---

## Common Questions

### Q: Why not manage wakelock in each kiosk page?
**A:** Only the main kiosk page manages it because:
- Simpler design (one place to manage)
- Wakelock persists across page navigation
- Prevents accidental disable during workflow
- Cleaner code (less duplication)

### Q: Why use device configuration for app lock instead of code?
**A:** Device-level solutions are:
- More reliable (cannot be bypassed)
- Simpler to implement
- No app permissions needed
- Industry standard for kiosk deployments

### Q: Will wakelock drain battery faster?
**A:** Yes, slightly, but:
- Kiosk devices are typically plugged in
- Battery impact is minimal on modern devices
- Trade-off is necessary for kiosk functionality

### Q: Can users still exit if wakelock is enabled?
**A:** Yes! Wakelock only prevents sleep, not app exit.
- Need Guided Access (iOS) or Screen Pinning (Android)
- This is intentional: admins can still exit for maintenance

### Q: What happens if wakelock fails to enable?
**A:** The app continues to work normally:
- Error is logged to console
- Screen will auto-sleep as per device settings
- User experience slightly degraded but functional

---

## Testing Checklist

### Wakelock Functionality
- [ ] Open kiosk page → Check console for "Wakelock enabled" message
- [ ] Leave device idle for 5+ minutes → Screen should NOT sleep
- [ ] Navigate to sign-in page → Wakelock should remain active
- [ ] Return to dashboard → Check console for "Wakelock disabled" message
- [ ] Leave device idle → Screen should sleep normally

### Search Functionality
- [ ] Open "Person Visiting" → Dialog appears with search field
- [ ] Type in search → Results filter in real-time
- [ ] Search with no matches → Shows "No contacts found" message
- [ ] Select contact → Dialog closes, contact appears in form
- [ ] Clear selection → Can reopen and search again

### Responsive Design
- [ ] Test on iPad (large screen) → Dialog should be 600px max width
- [ ] Test on phone (small screen) → Dialog should be 95% width
- [ ] Rotate device → Layout should adjust smoothly
- [ ] Font sizes should be appropriate for screen size

### Device Lock (Manual Test)
- [ ] **iOS:** Enable Guided Access → App is locked, cannot exit
- [ ] **iOS:** Triple-click → Enter passcode → Can exit
- [ ] **Android:** Pin app → Cannot exit without back+recent
- [ ] **Android:** Unpin → Enter PIN → Can exit

---

## Deployment Recommendations

### For Production Use

**1. Device Setup**
- Configure Guided Access / Screen Pinning on all kiosk devices
- Use unique passcodes per device (or per location)
- Document passcodes in secure location

**2. Power Management**
- Keep kiosk devices plugged in at all times
- Use quality charging cables and power adapters
- Consider surge protectors

**3. Physical Security**
- Mount tablets in secure stands or enclosures
- Position in well-lit, supervised areas
- Consider anti-theft cables if needed

**4. Monitoring**
- Check kiosk functionality daily
- Monitor for software updates
- Keep admin passcode accessible to authorized staff

**5. User Training**
- Train staff on basic troubleshooting
- Provide quick-reference guide near kiosk
- Document how to exit kiosk mode (for emergencies)

---

## Troubleshooting

### Screen Still Turns Off

**Possible Causes:**
1. Wakelock failed to enable
2. Device battery saver mode active
3. Device management policy overriding

**Solutions:**
- Check console logs for error messages
- Disable battery saver mode
- Ensure app has necessary permissions
- Verify device is plugged in

### Can't Exit Guided Access

**Solution:**
- Triple-click Home/Side button
- Enter the correct passcode
- If passcode forgotten: Restart device (will exit Guided Access)
- Set up new passcode after restart

### Search Not Working

**Possible Causes:**
1. Contact list not loaded
2. Network connectivity issues

**Solutions:**
- Return to dashboard and refresh
- Check internet connection
- Clear app cache and reload

### Dialog Overflow Error

**Fix:**
This was resolved in recent update by:
- Changing `Expanded` to `Flexible`
- Adding `IntrinsicHeight` wrapper
- Setting explicit height constraints for empty states

---

## Future Enhancements

Potential features for future development:

**1. Advanced Kiosk Settings**
- Toggle wakelock on/off from dashboard
- Configure auto-refresh intervals
- Customizable inactivity timeout

**2. Analytics**
- Track how long screen stays awake
- Monitor search usage patterns
- Visitor flow analytics

**3. Offline Mode**
- Better offline support for search
- Local caching of contact list
- Sync when connection restored

**4. Multi-Language Support**
- Search in multiple languages
- Dynamic translation loading

---

---

## Paper Type Configuration

### Overview

The app now supports multiple Brother label paper types to prevent printing failures caused by incorrect paper configuration.

### Supported Paper Types

Based on Brother QL-820NWB and QL-720NW specifications. Each paper size supports both **Black/White** and **Red/Black** color variants:

| Paper Type | Label Name Index | Color | Dimensions | Type | Best For |
|------------|------------------|-------|------------|------|----------|
| **62mm Continuous (B/W)** | 17 | Black/White | 62mm width | Continuous | Visitor badges (default) |
| **62mm Continuous (R/B)** | 17 | Red/Black | 62mm width | Continuous | Visitor badges with color |
| **62mm x 100mm (B/W)** | 4 | Black/White | 62mm x 100mm | Pre-cut | Standard labels |
| **62mm x 100mm (R/B)** | 4 | Red/Black | 62mm x 100mm | Pre-cut | Standard labels with color |
| **29mm x 90mm (B/W)** | 5 | Black/White | 29mm x 90mm | Pre-cut | Address labels |
| **29mm x 90mm (R/B)** | 5 | Red/Black | 29mm x 90mm | Pre-cut | Address labels with color |
| **62mm x 29mm (B/W)** | 8 | Black/White | 62mm x 29mm | Pre-cut | Small labels |
| **62mm x 29mm (R/B)** | 8 | Red/Black | 62mm x 29mm | Pre-cut | Small labels with color |
| **29mm Continuous (B/W)** | 15 | Black/White | 29mm width | Continuous | Narrow badges |
| **29mm Continuous (R/B)** | 15 | Red/Black | 29mm width | Continuous | Narrow badges with color |

**Note:** The same `labelNameIndex` is used for both color variants. The `isSpecialTape` field determines whether Black/White (false) or Red/Black (true) tape is used.

### How It Works

**1. Admin Configuration (Dashboard)**

```
Dashboard → Printer Status Card → Paper Type Section
```

- Admin selects paper type from dropdown
- Selection is automatically saved to secure storage
- Saved selection loads automatically on next visit
- Visual confirmation shows current paper dimensions

**2. Automatic Application**

When printing visitor badges:
```
1. System loads saved paper type from storage
2. If no saved type → uses default (62mm continuous)
3. PrinterService applies labelNameIndex to printer
4. Badge prints with correct paper settings
```

### Architecture

**Data Flow:**

```
┌─────────────────────────────────────────────────────────┐
│   Dashboard UI (PrintStatusCard)                        │
│   - Dropdown selector                                   │
│   - Load saved selection on init                        │
│   - Save on selection change                            │
└────────────────┬────────────────────────────────────────┘
                 │
                 │ Save/Load
                 ▼
┌─────────────────────────────────────────────────────────┐
│   SecureStorageService                                  │
│   - savePaperType(labelNameIndex)                       │
│   - getPaperType() → int?                               │
│   - Key: 'printer_paper_type'                           │
└────────────────┬────────────────────────────────────────┘
                 │
                 │ Read during print
                 ▼
┌─────────────────────────────────────────────────────────┐
│   PrinterService                                        │
│   - _printMobile(image)                                 │
│   - Loads saved paper type                              │
│   - Sets printerInfo.labelNameIndex                     │
│   - Applies to Brother SDK                              │
└─────────────────────────────────────────────────────────┘
```

**Key Files:**

1. **`lib/core/models/paper_type.dart`**
   - Defines PaperType model
   - Lists supported paper types
   - Provides helper methods

2. **`lib/services/secure_storage_service.dart`**
   - Saves/loads paper type selection
   - Methods: savePaperType(), getPaperType(), clearPaperType()

3. **`lib/services/printer_service.dart`**
   - Applies paper type during printing
   - Line 750-761: Load saved type, apply to printerInfo

4. **`lib/widgets/dashboard_custom_widgets.dart`**
   - PrintStatusCard UI (lines 424-544)
   - Paper type dropdown selector
   - Auto-load and auto-save functionality

### Implementation Details

**PaperType Model:**

```dart
class PaperType {
  final int labelNameIndex;      // Brother printer paper ID
  final String name;              // Display name
  final String description;       // User-friendly description
  final String dimensions;        // Paper size
  final bool isContinuous;        // Continuous vs pre-cut

  static const List<PaperType> supportedTypes = [
    // 5 supported paper types
  ];
}
```

**Storage Mechanism:**

```dart
// Save paper type
await SecureStorageService.savePaperType(17);  // 62mm continuous

// Load paper type
final index = await SecureStorageService.getPaperType();  // Returns 17

// Clear paper type
await SecureStorageService.clearPaperType();
```

**Print Integration:**

```dart
// In PrinterService._printMobile()
final savedPaperType = await SecureStorageService.getPaperType();
final labelNameIndex = savedPaperType ?? 17;  // Default to 62mm continuous

printerInfo.labelNameIndex = labelNameIndex;  // Apply to printer
```

### User Guide

**Initial Setup:**

1. Open Admin Dashboard
2. Scroll to "Printer Status" card
3. Locate "Paper Type" section
4. Select paper type matching installed roll/labels
5. Selection saves automatically

**Changing Paper Type:**

1. Install new paper in printer
2. Go to Dashboard → Paper Type
3. Select new paper type
4. System saves immediately
5. Next print will use new setting

**Verification:**

After selecting paper type:
- Green success message appears
- "Current" info box updates with dimensions
- Setting persists across app restarts

### Troubleshooting

**Print Fails with "Paper Error"**

**Cause:** Selected paper type doesn't match installed paper

**Solution:**
1. Check actual paper installed in printer
2. Go to Dashboard → Paper Type
3. Select matching paper type
4. Try printing again

**Paper Type Resets to Default**

**Cause:** Storage was cleared or corrupted

**Solution:**
1. Re-select correct paper type
2. Verify save success message appears
3. Check console for storage errors

**Don't Know Which Paper Type to Select**

**Solution:**
1. Check paper roll/label packaging
2. Look for dimensions (e.g., "62mm")
3. Check if continuous (roll) or pre-cut (individual labels)
4. Match to closest option in dropdown
5. Test print - if fails, try another type

### Technical Notes

**Why Label Name Index?**

Brother printers use an internal index system to identify paper types. The `labelNameIndex` parameter tells the printer SDK which paper configuration to use. Incorrect index causes print failures.

**Default Behavior:**

- If no paper type saved → Uses labelNameIndex 17 (62mm continuous)
- This matches the most common visitor badge paper
- Safe fallback for initial setup

**Storage Location:**

Saved to device's secure storage using Flutter Secure Storage:
- iOS: Keychain
- Android: EncryptedSharedPreferences
- Survives app updates and restarts

**Performance:**

- Paper type loads once on Dashboard init
- Minimal overhead during printing
- No network calls required

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0.2 | 2025-01 | - **Added paper type configuration**<br>- Multiple paper type support<br>- Auto-save/load paper settings<br>- Dashboard UI for paper selection |
| 1.0.1 | 2025-01 | - Added wakelock functionality<br>- Implemented searchable dialogs<br>- Dynamic company name in questions<br>- Unified responsive breakpoints |

---

## Support

For questions or issues:
1. Check console logs for error messages
2. Review this documentation
3. Contact development team with:
   - Device type and OS version
   - Steps to reproduce issue
   - Screenshots if applicable
   - Console error messages

---

**End of Documentation**
