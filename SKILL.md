---
name: harness
description: Subprocess-based safety sandbox harness skill for OpenCode CLI
---

# Local Harness Engine

This skill executes shell commands securely inside a restricted local Python subprocess with command blocking and execution timeouts.

## System Prompt Instructions
When running terminal commands or code snippets through harness, always run:
`python skills/local_harness.py "$ARGUMENTS"`

## See Also
- [AGENTS.md](AGENTS.md) - Agent rules and skills documentation