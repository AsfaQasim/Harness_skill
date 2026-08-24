#!/usr/bin/env bash
set -e

echo "Injecting Local Harness into OpenCode..."

mkdir -p .opencode/commands harness_engine/skills

# Inject harness.md for OpenCode CLI slash commands
cat << 'EOF' > .opencode/commands/harness.md
---
description: Run commands through Harness Sandbox
---

Always execute terminal commands using:
`python harness_engine/skills/local_harness.py "$ARGUMENTS"`

Task: $ARGUMENTS
EOF

# Inject Python Harness script
cat << 'EOF' > harness_engine/skills/local_harness.py
import sys, subprocess, json

BLOCKED_COMMANDS = ["rm -rf", "del /f /s /q", "format", "shutdown", "mkfs"]

def run_in_harness(command: str, timeout: int = 30) -> str:
    for blocked in BLOCKED_COMMANDS:
        if blocked in command.lower():
            return json.dumps({"status": "blocked", "error": f"Violation: '{blocked}' prohibited."})
    try:
        process = subprocess.run(command, shell=True, capture_output=True, text=True, timeout=timeout)
        return json.dumps({"status": "success" if process.returncode == 0 else "failed", "exit_code": process.returncode, "stdout": process.stdout.strip(), "stderr": process.stderr.strip()})
    except subprocess.TimeoutExpired:
        return json.dumps({"status": "timeout", "error": f"Exceeded {timeout}s limit."})
    except Exception as e:
        return json.dumps({"status": "error", "error": str(e)})

if __name__ == "__main__":
    cmd = "python --version" if len(sys.argv) < 2 else sys.argv[1]
    print(run_in_harness(cmd))
EOF

echo "Installed! /harness is now active in OpenCode CLI."