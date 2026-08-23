#!/usr/bin/env bash
set -e

echo "🚀 Installing Local Harness Skill for OpenCode..."

# 1. Directories setup
mkdir -p harness_engine/skills .opencode/commands

# 2. Local Harness Engine File Create
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

# 3. OpenCode Command Template Setup
cat << 'EOF' > .opencode/commands/harness.json
{
  "name": "harness",
  "description": "Execute commands under Local Harness Engine supervision",
  "template": "System Mode: Harness Engine Active.\nAlways run commands via `python harness_engine/skills/local_harness.py \"<command>\"`.\n\nTask: $ARGUMENTS"
}
EOF

echo "Local Harness Installed Successfully!"
echo "Usage in OpenCode: /harness <your-command>"