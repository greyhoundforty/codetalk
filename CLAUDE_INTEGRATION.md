# Claude Integration Guide

Complete guide for using Voice Capture with Claude Desktop and Claude Code.

## New Features Added

### 1. Auto-Save Transcriptions ✅
Every recording automatically saves TWO files:
- **Audio**: `recording_YYYY-MM-DDTHH-MM-SS.m4a`
- **Transcription**: `recording_YYYY-MM-DDTHH-MM-SS.txt`

**Location**: `~/Documents/Recordings/`

**Transcription Format**:
```
Recording: recording_2025-12-09T15-30-45.m4a
Transcribed: 2025-12-09T15:30:48Z

[Your transcribed text here]
```

### 2. "Send to Claude" Button 🎉
One-click workflow to prepare transcription for Claude:
- Copies text to clipboard
- Saves to `~/Documents/claude-prompts/prompt_TIMESTAMP.txt`
- Shows confirmation dialog

## Quick Workflow

### For Claude Desktop

1. **Record** your voice input (Spacebar or click button)
2. **Stop** recording (Spacebar or click button)
3. **Click "Send to Claude"** (green button)
4. **Switch to Claude Desktop** (⌘ + Tab)
5. **Paste** (⌘ + V) into message box
6. Press Enter to send!

**Time**: ~5 seconds from thought to Claude prompt 🚀

### For Claude Code

#### Option 1: Quick Paste (Recommended)
1. Record and transcribe in Voice Capture
2. Click "Send to Claude"
3. Switch to terminal with Claude Code
4. Paste (⌘ + V) and press Enter

#### Option 2: File Monitoring
Set up Claude Code to watch the prompts directory:

```bash
# Create a watcher script
cat > ~/bin/watch-voice-prompts.sh << 'EOF'
#!/bin/bash
PROMPT_DIR="$HOME/Documents/claude-prompts"

# Get the latest prompt file
LATEST=$(ls -t "$PROMPT_DIR"/prompt_*.txt 2>/dev/null | head -1)

if [ -f "$LATEST" ]; then
    echo "Latest voice prompt:"
    cat "$LATEST"
fi
EOF

chmod +x ~/bin/watch-voice-prompts.sh

# Use in Claude Code
~/bin/watch-voice-prompts.sh
```

#### Option 3: Auto-Submit (Advanced)
Create an AppleScript to auto-send to Claude Code:

```applescript
-- Save as ~/Library/Scripts/SendToClaudeCode.scpt
tell application "Terminal"
    activate
    do script "cat ~/Documents/claude-prompts/prompt_*.txt | tail -1 | pbcopy && echo 'Prompt ready - paste in Claude Code'"
end tell
```

## File Structure

```
~/Documents/
├── Recordings/                      # Audio + transcriptions
│   ├── recording_2025-12-09T15-30-45.m4a
│   ├── recording_2025-12-09T15-30-45.txt
│   ├── recording_2025-12-09T15-32-10.m4a
│   └── recording_2025-12-09T15-32-10.txt
│
└── claude-prompts/                  # Claude-ready prompts
    ├── prompt_2025-12-09T15-30-48.txt
    └── prompt_2025-12-09T15-32-13.txt
```

## Use Cases

### 1. Quick Bug Report
**Scenario**: You notice a bug while coding

```
1. Press Spacebar in Voice Capture
2. Say: "There's a bug in the user login form where pressing
   enter twice submits the form multiple times"
3. Press Spacebar to stop
4. Click "Send to Claude"
5. Paste into Claude Code
```

**Result**: Detailed bug description sent to Claude in seconds

### 2. Code Review Request
**Scenario**: You want Claude to review code

```
1. Record: "Review the authentication middleware in auth.js for
   security issues, specifically check for SQL injection and
   proper password hashing"
2. Send to Claude
3. Paste in Claude Code
```

### 3. Feature Planning
**Scenario**: Brainstorm a new feature

```
1. Record: "I need to add a dark mode toggle to the settings page.
   It should persist across sessions and apply globally.
   Show me the best approach using React context"
2. Send to Claude
3. Paste and get implementation plan
```

### 4. Documentation Request
**Scenario**: Need docs for complex code

```
1. Record: "Add comprehensive JSDoc comments to the
   calculateMetrics function explaining the algorithm and parameters"
2. Send to Claude
3. Claude generates documentation
```

## Button Reference

| Button | Action | When Available |
|--------|--------|---------------|
| **Start Recording** | Begin voice capture | When not recording |
| **Stop Recording** | End capture & transcribe | While recording |
| **Copy** | Copy transcription only | After transcription |
| **Send to Claude** | Copy + save to prompts dir | After transcription |
| **Clear** | Clear transcription display | After transcription |
| **Open in Finder** | Show audio file location | After recording |

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| **Spacebar** | Toggle recording on/off |
| **⌘ + C** | Copy selected text |
| **⌘ + Tab** | Switch to Claude Desktop |
| **⌘ + V** | Paste into Claude |

## Pro Tips

### 1. Speaking for Better Transcription
- Speak clearly and at moderate pace
- Pause briefly between sentences
- Say punctuation: "comma", "period", "new paragraph"
- Spell technical terms: "React R-E-A-C-T"

### 2. Structuring Prompts
Good voice prompts are:
- **Specific**: "Fix the login bug" → "Fix the bug where login form submits twice"
- **Contextual**: Include file names and locations
- **Action-oriented**: Use verbs like "create", "fix", "explain", "review"

### 3. Workflow Optimization
- Keep Voice Capture in menu bar for quick access
- Use Spacebar for hands-free operation
- Record immediately when you think of something
- Review transcription before sending

### 4. Multiple Recordings
- Each "Send to Claude" creates a new prompt file
- Previous recordings remain available
- Review transcriptions in `~/Documents/Recordings/`
- Prompt files are timestamped for easy tracking

## Advanced Integration

### Custom Prompt Template

Create a template for consistent formatting:

```bash
# ~/.config/voice-capture/template.txt
Context: [Project Name]
Type: [Bug/Feature/Question]

Prompt:
{TRANSCRIPTION}

Please provide:
1. Analysis
2. Solution
3. Code examples
```

### Automated Workflow with Hammerspoon

```lua
-- Send latest voice prompt to Claude Code
hs.hotkey.bind({"cmd", "alt"}, "V", function()
    local latest = hs.execute("ls -t ~/Documents/claude-prompts/prompt_*.txt | head -1")
    local content = hs.execute("cat " .. latest)
    hs.pasteboard.setContents(content)
    hs.alert.show("Voice prompt copied!")
end)
```

### Integration with VS Code

Add to VS Code `tasks.json`:

```json
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "Load Latest Voice Prompt",
      "type": "shell",
      "command": "cat $(ls -t ~/Documents/claude-prompts/prompt_*.txt | head -1)",
      "presentation": {
        "reveal": "always",
        "panel": "new"
      }
    }
  ]
}
```

## Troubleshooting

### Transcription Not Saving
**Check**: Look for .txt file next to .m4a file in `~/Documents/Recordings/`
**Fix**: Ensure folder has write permissions

### "Send to Claude" Button Not Working
**Check**: Console logs in Xcode (⌘ + Shift + Y)
**Fix**: Verify `~/Documents/claude-prompts/` directory exists and is writable

### Clipboard Not Updating
**Check**: Try manual copy with "Copy" button
**Fix**: Grant clipboard access in System Settings → Privacy & Security

### Prompt Files Accumulating
**Solution**: Periodic cleanup
```bash
# Delete prompts older than 7 days
find ~/Documents/claude-prompts -name "prompt_*.txt" -mtime +7 -delete
```

## Data Management

### Backup Important Prompts
```bash
# Create archive of prompts
tar -czf ~/Backups/voice-prompts-$(date +%Y%m%d).tar.gz ~/Documents/claude-prompts/
```

### Search Past Transcriptions
```bash
# Find transcriptions containing specific text
grep -r "authentication" ~/Documents/Recordings/*.txt

# List recent transcriptions
ls -lt ~/Documents/Recordings/*.txt | head -10
```

### Export to Different Format
```bash
# Convert all transcriptions to single markdown file
cat ~/Documents/Recordings/*.txt > ~/Documents/all-transcriptions.md
```

## Security & Privacy

- **Local Processing**: All audio stays on your Mac
- **No Cloud Upload**: Transcriptions use macOS Speech Recognition
- **File Permissions**: Standard user permissions on saved files
- **Clipboard**: Cleared when you copy something else
- **Deletion**: Simply delete files from Finder

## Performance

- **Recording**: ~1-2MB per minute (M4A, 44.1kHz)
- **Transcription**: Real-time, no delay
- **File Save**: < 100ms
- **Send to Claude**: < 500ms

## Coming Soon

Potential future features:
- [ ] Hotkey for global recording trigger
- [ ] Menu bar quick actions
- [ ] Direct Claude API integration
- [ ] Conversation history
- [ ] Multi-language support
- [ ] Custom prompt templates
- [ ] Voice commands for app control

---

## Quick Reference Card

```
┌─────────────────────────────────────────────┐
│  Voice Capture → Claude Workflow            │
├─────────────────────────────────────────────┤
│  1. [Space]     Start recording             │
│  2. Speak       Your prompt                 │
│  3. [Space]     Stop recording              │
│  4. Click       "Send to Claude"            │
│  5. [⌘+Tab]     Switch to Claude            │
│  6. [⌘+V]       Paste & send                │
└─────────────────────────────────────────────┘

Files saved to:
  Audio:          ~/Documents/Recordings/*.m4a
  Transcription:  ~/Documents/Recordings/*.txt
  Claude Prompts: ~/Documents/claude-prompts/*.txt
```

Happy voice coding! 🎤 + 🤖 = 🚀
