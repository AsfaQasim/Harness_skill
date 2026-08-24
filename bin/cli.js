#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

console.log("Installing Local Harness Skill for OpenCode...");

// Folders create karein target project me
const opencodePromptsDir = path.join(process.cwd(), '.opencode', 'prompts');
const skillsDir = path.join(process.cwd(), 'skills');

fs.mkdirSync(opencodePromptsDir, { recursive: true });
fs.mkdirSync(skillsDir, { recursive: true });

// 1. Write Python Local Harness Script
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

// 2. Write OpenCode Command Configuration
const commandConfig = JSON.stringify({
  name: "harness",
  description: "Execute commands under Local Harness Engine supervision",
  template: "System Mode: Harness Engine Active.\nAlways run commands via `python skills/local_harness.py \"<command>\"`.\n\nTask: $ARGUMENTS"
}, null, 2);

fs.writeFileSync(path.join(skillsDir, 'local_harness.py'), pythonHarnessCode);
fs.writeFileSync(path.join(opencodePromptsDir, 'harness.json'), commandConfig);

console.log("✅ AsfaHarness installed successfully into your workspace!");
console.log("💡 You can now use '/harness <command>' inside OpenCode CLI.");