# Claude Code Configuration

This directory contains custom configuration for Claude Code.

## Commands

Custom slash commands for this project:

### Context Management Commands

| Command | Purpose | Output Size |
|---------|---------|-------------|
| `/project-handoff` | Full comprehensive handoff | 300-500 lines |
| `/handoff` | Quick session snapshot | 150-300 lines |
| `/update-handoff` | Update existing handoff | Updates file |

### Usage

Simply type the command in Claude Code:
```
/project-handoff
```

Claude will create/update `.system-prompt-extraction/NEXT-STEPS.md` with a structured handoff document.

### Starting Fresh with Handoff

In a new Claude Code session:
```
Read .system-prompt-extraction/NEXT-STEPS.md and continue from there
```

## Documentation

See `CONTEXT_COMPACTION_GUIDE.md` in project root for:
- Detailed command explanations
- Workflow examples
- Best practices
- Troubleshooting

## Benefits

- **Saves ~7,300 tokens** (~41% overhead) per conversation
- **Enables smoother handoffs** between sessions
- **Documents project progress** automatically
- **Maintains context** without full conversation history

## File Structure

```
.claude/
├── README.md                    # This file
└── commands/
    ├── project-handoff.md       # Full handoff command
    ├── handoff.md               # Quick snapshot command
    └── update-handoff.md        # Incremental update command
```

## Adding More Commands

To create a new slash command:

1. Create `commands/yourcommand.md`
2. Write the prompt content in markdown
3. Use the command: `/yourcommand`

The markdown content becomes the prompt sent to Claude.

## Resources

- [Claude Code Documentation](https://docs.anthropic.com/claude/docs/claude-code)
- [Custom Commands Guide](https://docs.anthropic.com/claude/docs/custom-commands)
- [Agentic Coding - Context Compaction](https://agenticcoding.substack.com/i/180970862/tip-proactively-compact-your-context)
