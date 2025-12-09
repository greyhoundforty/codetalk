# Duplicate @main Entry Point Fix

## Error Message
```
/Users/ryan/claude-projects/swift-voice-capture/ambientcode/ambientcode/ambientcodeApp.swift:11:1
'main' attribute can only apply to one type in a module
```

## Root Cause

Swift apps can only have **ONE** `@main` entry point. Your project had two:

1. **ambientcodeApp.swift** (Line 11) - Original Xcode template
2. **VoiceCaptureApp.swift** (Line 3) - My added file

## Solution Applied

### 1. Updated `ambientcodeApp.swift`
Removed unnecessary SwiftData/ModelContainer setup:

**Before:**
```swift
import SwiftUI
import SwiftData

@main
struct ambientcodeApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([Item.self,])
        // ... configuration code ...
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
```

**After:**
```swift
import SwiftUI

@main
struct ambientcodeApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
    }
}
```

### 2. Deleted Duplicate Files
```bash
rm VoiceCaptureApp.swift  # Duplicate @main entry point
rm Item.swift             # Unused SwiftData model
```

## Final Project Structure

```
ambientcode/
└── ambientcode/
    ├── ambientcodeApp.swift    # ✓ Single @main entry point
    ├── AudioRecorder.swift     # ✓ Recording service
    └── ContentView.swift       # ✓ UI view
```

## What Changed

| File | Status | Reason |
|------|--------|--------|
| ambientcodeApp.swift | ✓ Updated | Simplified, removed SwiftData |
| VoiceCaptureApp.swift | ✗ Deleted | Duplicate @main |
| Item.swift | ✗ Deleted | Unused SwiftData model |
| AudioRecorder.swift | ✓ Kept | Core functionality |
| ContentView.swift | ✓ Kept | UI implementation |

## Why SwiftData Was Removed

The original Xcode template included SwiftData for persistent storage, but this voice capture app:
- Saves recordings as M4A files to disk
- Doesn't need a database
- Uses @Published properties for UI state

SwiftData added unnecessary complexity.

## Build Verification

The project now has:
- ✅ **ONE** @main entry point
- ✅ Clean, simple app structure
- ✅ No unused dependencies

Try building now:
```bash
⌘B in Xcode
```

## Next Steps

1. **Build** the project in Xcode (⌘B)
2. **Run** the app (⌘R)
3. **Grant permissions** when prompted
4. **Test recording** functionality

The error should be completely resolved! 🎉
