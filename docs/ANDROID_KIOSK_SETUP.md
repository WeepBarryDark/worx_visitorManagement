# Android Kiosk Mode Setup Guide

## Overview
This app includes kiosk guard features to prevent accidental exits. However, Android system-level navigation (back button, home button, recent apps) cannot be completely blocked by the app itself without device-level configuration.

## App-Level Protection (Already Implemented)
The app provides these protections:
- ✓ Blocks back button with warning message
- ✓ Immersive mode to hide navigation bars
- ✓ Prevents screen from sleeping (wakelock)
- ✓ Shows warning messages when exit attempts are detected

## Full Kiosk Mode (Requires Device Configuration)

For complete kiosk functionality on Android devices, you must enable **Screen Pinning** (consumer devices) or **Lock Task Mode** (enterprise devices):

---

## Option 1: Screen Pinning (Consumer Devices)

### Enabling Screen Pinning

1. **Open Settings** on the Android device
2. Go to **Security** → **Advanced** → **Screen pinning**
   - Location may vary: **Settings** → **Lock screen** → **Screen pinning**
   - Or: **Settings** → **Apps** → **Screen pinning**
3. **Turn on Screen pinning**
4. Optional: Enable **"Ask for PIN before unpinning"** for extra security

### Using Screen Pinning

1. Open the Worx Visitor app
2. Navigate to the kiosk page you want to lock
3. Open **Recent Apps** (square button or swipe up gesture)
4. Find the Worx Visitor app card
5. Tap the **app icon** at the top of the card
6. Select **"Pin"** from the menu

The device is now locked to this app!

### Exiting Screen Pinning

**Without PIN:**
- Hold **Back + Overview buttons** together for 2-3 seconds
- Or swipe up and hold if using gesture navigation

**With PIN:**
- Same gesture, then enter your PIN

---

## Option 2: Lock Task Mode (Enterprise/MDM)

For enterprise deployments with Android Enterprise or Device Owner mode:

### Prerequisites
- Device enrolled in Android Enterprise
- App set as Device Owner or Profile Owner
- MDM solution (EMM) configured

### Configuration via MDM

Most MDM solutions (AirWatch, MobileIron, Microsoft Intune, etc.) support Lock Task Mode:

1. Create a kiosk profile in your MDM console
2. Add Worx Visitor app to allowed apps
3. Enable **Lock Task Mode** or **Kiosk Mode**
4. Push configuration to target devices
5. App will automatically enter kiosk mode when launched

### Manual Lock Task Mode (Development/Testing)

For development purposes, you can use ADB:

```bash
# Enable device owner mode (factory reset required)
adb shell dpm set-device-owner com.example.worxvisitorapp/.AdminReceiver

# Whitelist app for lock task mode
adb shell settings put global lock_to_app_enabled 1

# Start lock task mode for specific activity
adb shell am start-lock-task com.example.worxvisitorapp/.MainActivity
```

**Note:** Setting device owner requires factory reset on most devices.

---

## Option 3: Third-Party Kiosk Launchers

Use dedicated kiosk launcher apps from Google Play:

### Recommended Launchers:
1. **Fully Kiosk Browser & App Lockdown** (Popular choice)
   - Free tier available
   - Extensive kiosk features
   - Web dashboard for management

2. **SureLock Kiosk Lockdown** (Enterprise-grade)
   - Professional kiosk solution
   - Remote management
   - Multi-app kiosk support

3. **Hexnode Kiosk Lockdown** (MDM-integrated)
   - Cloud-based management
   - Single or multi-app kiosk
   - Free tier for up to 25 devices

### Setup with Kiosk Launcher:
1. Install kiosk launcher from Play Store
2. Configure launcher to only allow Worx Visitor app
3. Set launcher as default home app
4. Configure exit password/PIN in launcher settings

---

## Comparison: Screen Pinning vs Lock Task Mode vs Launchers

| Feature | Screen Pinning | Lock Task Mode | Kiosk Launcher |
|---------|---------------|----------------|----------------|
| Setup complexity | Easy | Medium-Hard | Easy-Medium |
| Device management | Manual per device | Centralized (MDM) | App-based |
| Security level | Medium | High | Medium-High |
| Cost | Free | MDM license cost | Free-Paid |
| Best for | Single device | Enterprise fleet | Small deployment |
| Factory reset needed | No | Usually yes | No |
| Remote management | No | Yes (via MDM) | Yes (premium) |

---

## Android Version Compatibility

- **Android 5.0+**: Screen Pinning supported
- **Android 5.0+**: Lock Task Mode supported
- **Android 9.0+**: Enhanced kiosk features
- **Android 10+**: Gesture navigation compatibility

---

## Testing Kiosk Mode

### Screen Pinning Test:
1. Enable Screen Pinning in Settings
2. Launch Worx Visitor app → navigate to kiosk
3. Pin the app via Recent Apps
4. Try to:
   - Press back button (should show warning, then unpin if no PIN)
   - Press home button (should be blocked)
   - Use recent apps (should be blocked)

### Expected Behavior:
✓ Navigation buttons hidden or disabled
✓ Status bar pull-down disabled
✓ Can't switch apps
✓ Back button shows warning (app-level protection still active)

---

## Troubleshooting

**Q: User can still exit with back button**
- A: If Screen Pinning is active, first back will show warning, second back will unpin (if no PIN set)
- Solution: Enable "Ask for PIN before unpinning" in Screen Pinning settings

**Q: Can't find Screen Pinning in Settings**
- A: Location varies by manufacturer. Try searching for "pin" in Settings search bar

**Q: Need to update app while in kiosk mode**
- A: Exit kiosk mode first, update app, then re-enter kiosk mode

**Q: Device restarts and exits kiosk mode**
- A: This is expected with Screen Pinning. For persistent kiosk, use Lock Task Mode or kiosk launcher

**Q: Bottom navigation bar still visible**
- A: App uses immersive sticky mode. Swipe from edge will show bars temporarily, but they auto-hide

**Q: User can access Settings via notification shade**
- A: Screen Pinning should block this. If not, ensure it's properly enabled and device is on recent Android version

---

## Security Best Practices

1. **Enable PIN for unpinning** - Prevents unauthorized exits
2. **Disable notification access** - Prevents user from accessing Settings via notifications
3. **Use MDM for enterprise** - Centralized management and security policies
4. **Regular security updates** - Keep Android OS and app updated
5. **Physical security** - Secure device with mount or enclosure if in public area
6. **Network restrictions** - Use firewall/MDM to restrict network access to only required services

---

## Admin Sign In (In-App Exit)

Staff can exit kiosk mode using the app's built-in "Admin Sign In" feature:
1. Tap "Admin Sign In" button in kiosk interface
2. Enter admin password
3. App navigates to dashboard (exits kiosk)

This works regardless of Screen Pinning/Lock Task Mode status.

---

## Recommended Setup for Production

### Small Business (1-5 devices):
→ Use **Screen Pinning** with PIN + Kiosk Launcher

### Medium Business (5-50 devices):
→ Use **Fully Kiosk Browser** or similar launcher with cloud management

### Enterprise (50+ devices):
→ Use **Lock Task Mode** via MDM (Intune, AirWatch, etc.)

---

## Summary

| Requirement | Solution |
|-------------|----------|
| Quick test/demo | Screen Pinning (no PIN) |
| Single kiosk device | Screen Pinning with PIN |
| Multiple devices | Kiosk Launcher app |
| Enterprise deployment | Lock Task Mode via MDM |
| Maximum security | Lock Task Mode + MDM + Physical security |

⚠️ **Important**: The app cannot force system-level kiosk mode. Device configuration is required for full lockdown.
