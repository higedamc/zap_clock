# ZapClock Screenshots

Place screenshots to be used for publication on ZapStore in this directory.

## Required Screenshots

Take screenshots of the following screens:

1. **01_alarm_list.png** - Alarm list screen
   - State with several alarms set
   - Visible ON/OFF toggles

2. **02_alarm_edit.png** - Alarm edit screen
   - State with Lightning settings (NWC, address, amount) entered
   - Or basic alarm setup screen

3. **03_alarm_ring.png** - Alarm ringing screen
   - State with "Pay to Stop Alarm" button displayed
   - Lightning information (amount, recipient) displayed

4. **04_settings.png** - Settings screen
   - State with NWC connection settings displayed
   - Default settings entered

## Screenshot Capture Tips

### Recommended Resolution
- **1080x2400px** (9:19.5) - Modern smartphone standard
- Or **1080x1920px** (9:16) - Traditional 16:9 ratio

### Device
- Android emulator (Pixel 5, Pixel 6, etc.)
- If capturing on actual device, crop to clean image without bezels

### Capture Methods

#### Method 1: Flutter Integrated Screenshot Feature
```bash
# Launch app
fvm flutter run

# Press 's' key with screen displayed
# Screenshot saved as flutter_01.png
```

#### Method 2: Screenshot via adb
```bash
# Launch app on emulator/device
fvm flutter run

# Capture screenshot in separate terminal
adb shell screencap -p /sdcard/screenshot.png
adb pull /sdcard/screenshot.png ./screenshots/01_alarm_list.png
```

#### Method 3: Android Studio
- Click camera icon next to "Logcat" tab in Android Studio
- Capture and save screenshot

### Notes

- Don't display personal information (actual NWC connection strings, etc.)
- Use dummy or sample data
- Good to capture versions with both light and dark backgrounds
- Save images in PNG format

## After Capture

After capturing screenshots, save with the following filenames:

```
screenshots/
├── 01_alarm_list.png
├── 02_alarm_edit.png
├── 03_alarm_ring.png
└── 04_settings.png
```

These files are referenced in `zapstore.yaml`.
