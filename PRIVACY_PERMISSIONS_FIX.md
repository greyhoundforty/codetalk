# Privacy Permissions Fix

## Error Message
```
This app has crashed because it attempted to access privacy-sensitive data without a usage description.
The app's Info.plist must contain an NSMicrophoneUsageDescription key with a string value explaining to the user how the app uses this data.
```

## Status: Info.plist Already Configured! ✅

Good news! Your `Info.plist` already has **both required privacy keys**:

```xml
<key>NSMicrophoneUsageDescription</key>
<string>This app needs microphone access to record audio for transcription.</string>

<key>NSSpeechRecognitionUsageDescription</key>
<string>This app needs speech recognition to transcribe your audio recordings.</string>
```

## Why You're Still Seeing the Error

The issue is that Xcode's build cache has the **old version** of the app without these keys. You need to:
1. Clean the build folder
2. Rebuild the app fresh

## Fix Steps - In Xcode

### Option 1: Clean Build Folder (Recommended)

1. In Xcode, hold **⌘ + Shift + K** (or Product → Clean Build Folder)
2. Wait for "Clean Finished"
3. Press **⌘ + B** to rebuild
4. Press **⌘ + R** to run

### Option 2: Delete Derived Data (Nuclear Option)

If Option 1 doesn't work:

1. **Quit Xcode completely** (⌘ + Q)
2. Open Terminal and run:
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData/ambientcode-*
   ```
3. **Reopen Xcode**
4. **Build & Run** (⌘ + R)

### Option 3: Verify Info.plist is Linked

1. In Xcode, select your **project** (blue icon at top)
2. Select **ambientcode target** (not project)
3. Go to **Build Settings** tab
4. Search for "Info.plist"
5. Under "Packaging", verify **Info.plist File** is set to:
   ```
   ambientcode/Info.plist
   ```
6. If not, click and set it to the correct path
7. Clean and rebuild

## Verify the Fix Worked

When you run the app (⌘ + R), you should see:

1. **Permission dialog** appears automatically asking for microphone access
2. **No crash** - app launches successfully
3. **"Microphone access granted"** prompt if you click Allow

If you see the permission dialog, the fix worked! 🎉

## Permission Dialog Text

The user will see:
- **Microphone**: "This app needs microphone access to record audio for transcription."
- **Speech Recognition**: "This app needs speech recognition to transcribe your audio recordings."

## Troubleshooting

### Still Crashing?

1. **Check Console logs** in Xcode (⌘ + Shift + Y)
2. Look for lines mentioning "Info.plist" or "NSMicrophoneUsageDescription"
3. Verify the actual app bundle has the Info.plist:
   ```bash
   # After building, check the built app
   plutil -p ~/Library/Developer/Xcode/DerivedData/ambientcode-*/Build/Products/Debug/ambientcode.app/Contents/Info.plist | grep -A1 Microphone
   ```

### Permission Already Denied?

If you previously denied permissions:

1. Open **System Settings**
2. Go to **Privacy & Security** → **Microphone**
3. Find **ambientcode** and enable it
4. Go to **Privacy & Security** → **Speech Recognition**
5. Find **ambientcode** and enable it
6. Relaunch the app

### Wrong Info.plist Being Used?

Check if there are multiple Info.plist files:
```bash
find /Users/ryan/claude-projects/swift-voice-capture/ambientcode -name "Info.plist" -type f
```

Should only return:
```
/Users/ryan/claude-projects/swift-voice-capture/ambientcode/ambientcode/Info.plist
```

## What the Keys Do

| Key | Purpose | When Asked |
|-----|---------|------------|
| NSMicrophoneUsageDescription | Microphone access | First time recording |
| NSSpeechRecognitionUsageDescription | Speech recognition | First time transcribing |

Both are required for the voice capture functionality to work.

## Expected Behavior After Fix

1. **First Launch**: Two permission dialogs appear (mic + speech)
2. **Grant Both**: App works fully with recording & transcription
3. **Deny Either**: App shows alert explaining permissions are needed
4. **Future Launches**: No dialogs - permissions remembered

## Quick Fix Summary

```bash
# 1. Clean build in Xcode
⌘ + Shift + K

# 2. Rebuild
⌘ + B

# 3. Run
⌘ + R

# Should launch without crashing! 🎉
```

The Info.plist is correct - you just need a clean rebuild!
