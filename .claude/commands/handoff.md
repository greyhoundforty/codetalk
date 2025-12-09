# Create Session Handoff - Quick Context Snapshot

Create a quick handoff snapshot for continuing work in a new Claude Code session.

## Task

Generate a concise handoff document at `.system-prompt-extraction/NEXT-STEPS.md` covering:

### Current Session Summary
- What was accomplished in THIS session
- Key files modified (with paths)
- Important decisions made

### Immediate Next Steps
Top 3-5 concrete tasks to continue:
1. [Specific actionable task]
2. [Specific actionable task]
3. [Specific actionable task]

### Context Essentials
Only the critical context needed:
- Current blocker (if any)
- Key file locations
- Important patterns or approaches

### Quick Reference
```
Project: [Name]
Last Updated: [Timestamp]
Status: [In Progress/Blocked/Ready for Testing]
```

## Format

Keep it short and actionable - aim for 150-300 lines max. Focus on:
- What's needed to continue work immediately
- Critical context that's not obvious from code
- Specific next actions with clear criteria

After creating:
1. Confirm file location
2. Suggest: "In next session, tell Claude: 'Read .system-prompt-extraction/NEXT-STEPS.md and continue from there'"
