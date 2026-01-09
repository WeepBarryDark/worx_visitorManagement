# iOS/iPadOS Kiosk Mode Setup Guide

## Overview
This app includes kiosk guard features to prevent accidental exits. However, iOS/iPadOS system-level gestures (like swiping up from the bottom to exit) cannot be completely blocked by the app itself.

## App-Level Protection (Already Implemented)
The app provides these protections:
- ✓ Blocks back navigation button
- ✓ Detects edge swipe gestures and shows warnings
- ✓ Prevents screen from sleeping (wakelock)
- ✓ Shows warning messages when exit gestures are detected

## Full Kiosk Mode (Requires Device Configuration)

For complete kiosk functionality on iOS/iPadOS devices, you must enable **Guided Access**:

### Enabling Guided Access

1. **Open Settings** on the iPad/iPhone
2. Go to **Accessibility** → **Guided Access**
3. **Turn on Guided Access**
4. Set a **Passcode** (you'll need this to exit Guided Access)
5. Optional: Enable **Accessibility Shortcut** for quick access

### Using Guided Access

1. Open the Worx Visitor app
2. Navigate to the kiosk page you want to lock
3. **Triple-click the Side Button** (or Home button on older devices)
4. The Guided Access overlay appears
5. Configure options:
   - Circle areas to disable touch input (optional)
   - Disable hardware buttons if needed
6. Tap **Start** in the top-right corner

The device is now locked to this app and page!

### Exiting Guided Access

1. **Triple-click the Side Button** (or Home button)
2. Enter your Guided Access passcode
3. Tap **End** in the top-left corner

## Alternative: Mobile Device Management (MDM)

For enterprise deployments, consider using an MDM solution like:
- Apple Business Manager
- Jamf
- Microsoft Intune
- Cisco Meraki

MDM allows you to:
- Remotely enable Single App Mode
- Configure kiosk settings across multiple devices
- Restrict device features centrally
- Schedule automatic updates

## Important Notes

⚠️ **The app cannot force Guided Access** - it must be enabled manually or via MDM

⚠️ **Guided Access passcode is critical** - store it securely or you may need to factory reset the device

✓ **Admin Sign In** - Staff can exit the kiosk using the "Admin Sign In" option in the app

## Testing Kiosk Mode

1. Enable Guided Access as described above
2. Launch the app and navigate to Visitor Kiosk
3. Activate Guided Access (triple-click)
4. Try to:
   - Swipe up from bottom (should be blocked)
   - Swipe from edges (should be blocked)
   - Use hardware buttons (should be blocked if configured)

## Troubleshooting

**Q: User can still exit the app**
- A: Ensure Guided Access is enabled and active (check for orange bar at top of screen)

**Q: Forgot Guided Access passcode**
- A: You'll need to reset the device or contact your IT administrator

**Q: App shows warnings but user can still exit**
- A: This is expected without Guided Access. The warnings are informational only.

**Q: Need to update the app while in Guided Access**
- A: Exit Guided Access first, update the app, then re-enable Guided Access
