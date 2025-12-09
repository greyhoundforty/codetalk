# Compact Context - Create Handoff Document

You are helping create a proactive context compaction handoff document. This document will allow future Claude Code sessions to continue work efficiently without needing the full conversation history.

## Your Task

Create a comprehensive handoff document at `.system-prompt-extraction/NEXT-STEPS.md` with the following structure:

### 1. Goal Statement
Clearly state what we're trying to accomplish in this project. Be specific about:
- The main objective
- Success criteria
- Why this work matters

### 2. Progress Summary

#### What Has Been Completed
- List all completed features/tasks
- Include file paths and line numbers where relevant
- Note any key decisions made

#### What Worked
- Document successful approaches
- Include patterns or techniques that were effective
- Note any particularly good solutions

#### What Failed
- Document failed approaches and why
- Include lessons learned
- Note what to avoid in the future

#### Current State
- Describe the current state of the codebase
- List any pending changes or work-in-progress
- Identify any temporary solutions or technical debt

### 3. Current Blockers or Challenges
- List any blocking issues
- Note dependencies or prerequisites
- Identify areas needing clarification or decisions

### 4. Actionable Next Steps
Provide specific, concrete tasks for the next agent:
- [ ] Task 1 with clear acceptance criteria
- [ ] Task 2 with file paths if relevant
- [ ] Task 3 with any context needed

Make each task:
- Specific and actionable
- Include relevant file paths
- Note any dependencies
- Estimate complexity if helpful

### 5. Technical Context
- Key files and their purposes
- Important functions or classes
- Architecture decisions
- Dependencies or integrations

### 6. Important Notes
- Any quirks or gotchas
- Configuration requirements
- Testing approaches
- Documentation locations

## Instructions

1. Create the `.system-prompt-extraction/` directory if it doesn't exist
2. Write the `NEXT-STEPS.md` file with all sections filled out
3. Be thorough but concise - include only essential context
4. Use markdown formatting for readability
5. Include code snippets or examples where helpful

After creating the file, confirm:
- File path where it was saved
- Summary of what was captured
- Suggestion for how to use it in next session

This handoff document will preserve ~7,300 tokens (~41% of static overhead) and enable smoother continuity between conversation instances.
