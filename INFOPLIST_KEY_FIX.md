# Info.plist Privacy Keys Fix - The Real Solution

## The Problem

Even though `Info.plist` had the correct privacy keys, the app still crashed with:
```
This app has crashed because it attempted to access privacy-sensitive data without a usage description.
Thread 2: abort with payload or reason
```

## Root Cause Discovered

The Xcode project had:
```
GENERATE_INFOPLIST_FILE = YES
```

This means Xcode **auto-generates** the Info.plist at build time and **ignores** the Info.plist file in your source directory!

## The Solution

For modern Xcode projects with auto-generated Info.plist, you must add privacy keys as **build settings** in the project configuration using the `INFOPLIST_KEY_` prefix.

### What Was Added

Modified `ambientcode.xcodeproj/project.pbxproj` to add these keys to both Debug and Release configurations:

```
INFOPLIST_KEY_NSMicrophoneUsageDescription = "This app needs microphone access to record audio for transcription.";
INFOPLIST_KEY_NSSpeechRecognitionUsageDescription = "This app needs speech recognition to transcribe your audio recordings.";
```

### Location in Project File

**Debug Configuration** (Line 410-412):
```
INFOPLIST_KEY_NSHumanReadableCopyright = "";
INFOPLIST_KEY_NSMicrophoneUsageDescription = "This app needs microphone access to record audio for transcription.";
INFOPLIST_KEY_NSSpeechRecognitionUsageDescription = "This app needs speech recognition to transcribe your audio recordings.";
```

**Release Configuration** (Line 456-458):
```
INFOPLIST_KEY_NSHumanReadableCopyright = "";
INFOPLIST_KEY_NSMicrophoneUsageDescription = "This app needs microphone access to record audio for transcription.";
INFOPLIST_KEY_NSSpeechRecognitionUsageDescription = "This app needs speech recognition to transcribe your audio recordings.";
```

## How to Verify the Fix in Xcode

1. **Close Xcode if it's open** (important!)
2. **Reopen the project** in Xcode
3. Select your **project** (blue icon) in navigator
4. Select **ambientcode target**
5. Go to **Build Settings** tab
6. Search for "usage"
7. You should see:
   - **Microphone Usage Description**: "This app needs microphone access to record audio for transcription."
   - **Speech Recognition Usage Description**: "This app needs speech recognition to transcribe your audio recordings."

## Build & Run

1. **Clean Build Folder**: ⌘ + Shift + K
2. **Build**: ⌘ + B
3. **Run**: ⌘ + R

## Expected Behavior

✅ App launches successfully (no crash!)
✅ Permission dialog appears: "ambientcode would like to access the microphone"
✅ Second dialog appears: "ambientcode would like to access Speech Recognition"
✅ Click "OK" on both
✅ App shows "Ready" status and you can start recording!

## Why This Happens

Modern Xcode (15+) projects use **auto-generated Info.plist** by default. This is controlled by:
- `GENERATE_INFOPLIST_FILE = YES` in build settings
- Privacy keys must be added as `INFOPLIST_KEY_*` build settings
- The Info.plist file in your source is **not used** at build time

## Alternative Approach (Not Recommended)

You could disable auto-generation:
1. Set `GENERATE_INFOPLIST_FILE = NO`
2. Set `INFOPLIST_FILE = ambientcode/Info.plist`

But the modern approach (using `INFOPLIST_KEY_*`) is preferred by Apple.

## Verification Command

After building, check the built app's Info.plist:

```bash
# Find the built app
find ~/Library/Developer/Xcode/DerivedData/ambientcode-*/Build/Products/Debug -name "ambientcode.app" -type d

# Check its Info.plist for privacy keys
plutil -p $(find ~/Library/Developer/Xcode/DerivedData/ambientcode-*/Build/Products/Debug -name "ambientcode.app" -type d | head -1)/Contents/Info.plist | grep -E "(Microphone|Speech)"
```

Should output:
```
"NSMicrophoneUsageDescription" => "This app needs microphone access to record audio for transcription."
"NSSpeechRecognitionUsageDescription" => "This app needs speech recognition to transcribe your audio recordings."
```

## Key Takeaway

🔑 **Modern Xcode projects**: Add privacy keys as `INFOPLIST_KEY_*` build settings, not in Info.plist file!

## What Was Changed

| File | Change |
|------|--------|
| project.pbxproj | Added 2 privacy keys to Debug config (line 411-412) |
| project.pbxproj | Added 2 privacy keys to Release config (line 457-458) |

The fix is now in place - just reopen Xcode and build! 🎉
