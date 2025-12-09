# Context Compaction Slash Commands

Custom Claude Code commands for proactive context management and efficient agent handoffs.

## Overview

These slash commands implement the **proactive context compaction strategy** from [Agentic Coding](https://agenticcoding.substack.com/i/180970862/tip-proactively-compact-your-context), saving ~7,300 tokens (~41% of static overhead) per conversation.

Instead of relying on automatic context compaction, you manually create handoff documents that allow new Claude Code instances to continue work without full conversation history.

## Commands Available

### 1. `/project-handoff` - Full Context Compaction

**Purpose**: Create comprehensive handoff document for major milestones or long sessions

**When to use**:
- End of work session
- After completing major features
- Before context gets too large
- When switching focus areas

**What it creates**:
```
.system-prompt-extraction/
└── NEXT-STEPS.md     # Comprehensive handoff document
```

**Content includes**:
1. Goal statement
2. Progress summary (completed/worked/failed)
3. Current blockers
4. Actionable next steps (with checkboxes)
5. Technical context
6. Important notes

**Usage**:
```bash
/project-handoff
```

**Example output**: 300-500 line comprehensive handoff document

---

### 2. `/handoff` - Quick Session Snapshot

**Purpose**: Fast, lightweight handoff for short sessions

**When to use**:
- Quick sessions (< 30 minutes)
- Minor updates or bug fixes
- When you need to continue soon
- Frequent context refreshes

**What it creates**:
```
.system-prompt-extraction/
└── NEXT-STEPS.md     # Concise snapshot
```

**Content includes**:
1. Current session summary
2. Top 3-5 immediate next steps
3. Essential context only
4. Quick reference block

**Usage**:
```bash
/handoff
```

**Example output**: 150-300 line concise handoff document

---

### 3. `/update-handoff` - Incremental Update

**Purpose**: Update existing handoff document with current progress

**When to use**:
- After completing tasks from NEXT-STEPS.md
- Mid-session progress checkpoints
- When adding new tasks
- To refresh current state

**What it does**:
- Reads existing NEXT-STEPS.md
- Marks completed tasks as done
- Adds new progress
- Updates current state
- Revises next steps
- Adds session log entry

**Usage**:
```bash
/update-handoff
```

**Result**: NEXT-STEPS.md updated with session progress

---

## Complete Workflow

### Scenario 1: Starting a New Project

```bash
# Session 1: Initial work
# ... do some coding ...

# Before ending session
/project-handoff

# Output: .system-prompt-extraction/NEXT-STEPS.md created
```

```bash
# Session 2: Continue work
# Start fresh Claude Code conversation

"Read .system-prompt-extraction/NEXT-STEPS.md and continue from there"

# ... work on tasks from handoff ...

# Update progress
/update-handoff

# Continue working...
```

---

### Scenario 2: Long Development Session

```bash
# Hour 1-2: Building features
# ... lots of work ...

# Checkpoint 1
/handoff

# Hour 3-4: Continue
# ... more work ...

# Checkpoint 2
/update-handoff

# End of day
/project-handoff   # Full comprehensive handoff
```

---

### Scenario 3: Quick Bug Fix

```bash
# Find and fix bug
# ... 15 minutes of work ...

# Quick handoff before leaving
/handoff

# Next day - new conversation
"Read .system-prompt-extraction/NEXT-STEPS.md"
# Continue immediately with context
```

---

## File Structure

```
your-project/
├── .claude/
│   └── commands/
│       ├── compact.md          # Full compaction command
│       ├── handoff.md          # Quick snapshot command
│       └── update-handoff.md   # Incremental update command
│
└── .system-prompt-extraction/
    └── NEXT-STEPS.md           # Your handoff document
```

## Handoff Document Structure

### Full Compact Format (`/project-handoff`)

```markdown
# Project Handoff - [Project Name]

**Last Updated**: 2025-12-09 16:30
**Status**: In Progress

## 1. Goal Statement
[What we're trying to accomplish]

## 2. Progress Summary

### What Has Been Completed
- [x] Feature 1 (src/feature.swift:45)
- [x] Feature 2 (src/module.swift:120)

### What Worked
- Approach X was effective for Y
- Pattern Z solved problem W

### What Failed
- Attempted solution A - failed because B
- Lesson learned: avoid C

### Current State
- Codebase has X functional features
- Pending: Y needs completion
- Technical debt: Z requires refactoring

## 3. Current Blockers
- [ ] Waiting on API documentation
- [ ] Need clarification on feature requirements

## 4. Actionable Next Steps
- [ ] Implement feature X (est: 1-2 hours)
      Files: src/main.swift, src/helper.swift
      Context: Builds on completed feature Y
- [ ] Add tests for module Z
      Files: tests/module_test.swift
- [ ] Refactor component W for performance
      Context: Current implementation is O(n²)

## 5. Technical Context
- **Key Files**:
  - src/main.swift - Entry point
  - src/core.swift - Core logic
- **Architecture**: MVC pattern with Services layer
- **Dependencies**: AVFoundation, Speech, SwiftUI

## 6. Important Notes
- Using macOS 13.0+ APIs (not iOS compatible)
- Permissions must be in INFOPLIST_KEY format
- Test coverage currently at 75%

## Session Log
- 2025-12-09 16:30 - Implemented sidebar and learning system
- 2025-12-09 14:15 - Fixed NSPasteboard import issue
```

### Quick Handoff Format (`/handoff`)

```markdown
# Quick Handoff - [Project Name]

**Date**: 2025-12-09 16:30
**Status**: In Progress

## Current Session
- Fixed sidebar navigation bug
- Added recording deletion feature
- Updated documentation

## Immediate Next Steps
1. Test sidebar with 100+ recordings (perf check)
2. Add keyboard shortcut for sidebar toggle
3. Implement search in recording list

## Context
- **Blocker**: None currently
- **Key Files**: ContentView.swift (sidebar), RecordingsManager.swift
- **Pattern**: Using NavigationSplitView for layout

## Quick Reference
```
Project: Voice Capture macOS App
Framework: SwiftUI + AVFoundation
Next: Performance testing
```

---

## Best Practices

### When to Compact

✅ **Do create handoff when**:
- Context feels bloated (long conversation history)
- Switching between different features/areas
- End of work session
- Before asking for major refactoring
- After completing significant milestones

❌ **Don't create handoff**:
- In the middle of debugging
- During active problem-solving
- Every 5 minutes (too frequent)
- When context is still highly relevant

### What to Include

✅ **Essential**:
- Concrete next steps with file paths
- Current blockers and their context
- Key architectural decisions
- What failed and why (lessons learned)

❌ **Skip**:
- Full code listings (just reference file paths)
- Detailed conversation history
- Obvious information from code
- Speculative future features

### Writing Effective Next Steps

**Good** ✅:
```markdown
- [ ] Add error handling to saveTranscription() method
      File: AudioRecorder.swift:220
      Context: Currently doesn't handle file write failures
      Test: Try saving with read-only directory
```

**Bad** ❌:
```markdown
- [ ] Make the app better
- [ ] Fix bugs
- [ ] Add features
```

---

## Starting Fresh with Handoff

### In New Claude Code Session

**Option 1: Direct reference**
```
Read .system-prompt-extraction/NEXT-STEPS.md and continue from there
```

**Option 2: With context**
```
I'm continuing work on [project]. Read .system-prompt-extraction/NEXT-STEPS.md
for context. Let's start with the first actionable next step.
```

**Option 3: Specific focus**
```
Read .system-prompt-extraction/NEXT-STEPS.md. I want to focus on the
sidebar performance optimization mentioned in next steps.
```

---

## Benefits

### Token Savings
- **Saves**: ~7,300 tokens (~41% of static overhead)
- **Equivalent to**: ~5-6 pages of conversation history
- **Enables**: Longer conversations without compaction

### Efficiency
- **Faster**: New agents start immediately with context
- **Clearer**: Structured context vs scattered conversation
- **Maintained**: Documented project history

### Continuity
- **Smooth handoffs** between sessions
- **No context loss** from automatic compaction
- **Better results** with focused context

---

## Advanced Usage

### Multiple Handoff Documents

For complex projects, create specialized handoffs:

```
.system-prompt-extraction/
├── NEXT-STEPS.md           # Main handoff
├── ARCHITECTURE.md         # System design decisions
├── TESTING-STRATEGY.md     # Test approach and coverage
└── KNOWN-ISSUES.md         # Bugs and workarounds
```

Reference multiple files:
```
Read all files in .system-prompt-extraction/ for full context
```

### Team Handoffs

Use for team collaboration:
```markdown
## Handoff to [Team Member]

**What you need to know**:
- [Context specific to them]

**Your tasks**:
- [Tasks assigned to them]

**I'll handle**:
- [Tasks you're keeping]
```

### Version Control

Commit handoff documents:
```bash
git add .system-prompt-extraction/NEXT-STEPS.md
git commit -m "Update handoff: completed sidebar, next is performance"
```

Benefits:
- Track project progress over time
- Review what worked/failed historically
- Share context with team

---

## Troubleshooting

### Command Not Found

**Issue**: `/compact` shows "unknown command"

**Fix**:
1. Verify file exists: `ls .claude/commands/compact.md`
2. Check file extension is `.md`
3. Restart Claude Code
4. Try full path: `/.claude/commands/compact.md`

### Handoff Too Long

**Issue**: NEXT-STEPS.md is 1000+ lines

**Fix**:
- Use `/handoff` instead of `/compact` for shorter version
- Remove outdated content
- Archive old session logs
- Split into multiple specialized files

### Missing Context

**Issue**: New agent doesn't have enough context

**Fix**:
- Run `/compact` for more comprehensive handoff
- Add "Technical Context" section with more details
- Include code snippets for complex logic
- Reference additional documentation

---

## Quick Reference Card

```
╔═══════════════════════════════════════════════════════╗
║  CONTEXT COMPACTION COMMANDS                          ║
╠═══════════════════════════════════════════════════════╣
║  /project-handoff → Full comprehensive handoff        ║
║  /handoff         → Quick session snapshot            ║
║  /update-handoff  → Update existing document          ║
╠═══════════════════════════════════════════════════════╣
║  Output: .system-prompt-extraction/NEXT-STEPS.md     ║
║  Saves: ~7,300 tokens per conversation               ║
╠═══════════════════════════════════════════════════════╣
║  Next Session:                                        ║
║  "Read .system-prompt-extraction/NEXT-STEPS.md"      ║
╚═══════════════════════════════════════════════════════╝
```

---

## Example Session Flow

```bash
# Morning - Start work
$ claude

> Read .system-prompt-extraction/NEXT-STEPS.md
> Let's implement the sidebar toggle feature

# ... work for 2 hours ...
# Checkpoint
> /update-handoff

# ... work for 2 more hours ...
# Major milestone reached
> /project-handoff

# Afternoon - New conversation
$ claude

> Read .system-prompt-extraction/NEXT-STEPS.md
> Continue with performance optimization tasks

# ... work ...
# End of day snapshot
> /handoff

# Tomorrow - Fresh start
$ claude

> Read .system-prompt-extraction/NEXT-STEPS.md and
> summarize what's left to do
```

---

## Resources

- **Original Article**: [Agentic Coding - Proactive Context Compaction](https://agenticcoding.substack.com/i/180970862/tip-proactively-compact-your-context)
- **Claude Code Docs**: [Custom Slash Commands](https://docs.anthropic.com/claude/docs/claude-code)
- **This Project**: See `.claude/commands/` for command definitions

---

## Summary

**Three commands for efficient context management**:
1. `/project-handoff` - Comprehensive handoff (300-500 lines)
2. `/handoff` - Quick snapshot (150-300 lines)
3. `/update-handoff` - Incremental updates

**Key benefits**:
- 41% token savings per conversation
- Smoother agent handoffs
- Documented project history
- Longer effective conversations

**Best workflow**:
- End sessions with `/project-handoff` or `/handoff`
- Start new sessions with handoff document
- Update progress with `/update-handoff`
- Iterate and improve

Start compacting your context proactively! 🚀
