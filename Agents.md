# Agent Rules & Skills

## Custom Command: /harness
When the user types `/harness <command>` or asks to run something securely:
1. Do NOT execute the raw bash command directly.
2. Pass the argument into the local harness skill:
   `python skills/local_harness.py "<command>"`
3. Read the JSON output and report status/exit code to the user.