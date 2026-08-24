#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

console.log("🚀 Injecting Local Harness Engine & OpenCode Commands...");

// Paths setup
const opencodeDir = path.join(process.cwd(), '.opencode', 'commands');
const skillsDir = path.join(process.cwd(), 'harness_engine', 'skills');

// Create directories recursively
fs.mkdirSync(opencodeDir, { recursive: true });
fs.mkdirSync(skillsDir, { recursive: true });

// 1. Python Local Harness Engine Logic
const pythonHarnessCode = `import sys, subprocess, json

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
`;

// 2. OpenCode Slash Command Markdown Injection
const opencodeCommandMarkdown = `---
description: Run commands through Harness Sandbox
---

Always execute terminal commands using:
\`python harness_engine/skills/local_harness.py "$ARGUMENTS"\`

Task: $ARGUMENTS
`;

// Write files directly into target project
fs.writeFileSync(path.join(skillsDir, 'local_harness.py'), pythonHarnessCode);
fs.writeFileSync(path.join(opencodeDir, 'harness.md'), opencodeCommandMarkdown);

console.log("Auto-injection complete!");
console.log("You can now restart OpenCode CLI and use /harness instantly.");