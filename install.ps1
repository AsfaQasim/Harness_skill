# Local Harness Skill Installer (Windows PowerShell)

Write-Host "Installing Local Harness Skill..." -ForegroundColor Cyan

# 1. Create directories
if (!(Test-Path "skills")) { New-Item -ItemType Directory -Path "skills" | Out-Null }
if (!(Test-Path ".opencode/prompts")) { New-Item -ItemType Directory -Path ".opencode/prompts" -Force | Out-Null }

# 2. Create Local Harness Engine
$harnessPy = @'
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
'@

Set-Content -Path "skills/local_harness.py" -Value $harnessPy -Encoding UTF8

# 3. Create OpenCode Command Template
$harnessJson = @'
{
  "name": "harness",
  "description": "Execute commands under Local Harness Engine supervision",
  "template": "System Mode: Harness Engine Active.\nAlways run commands via `python skills/local_harness.py \"<command>\"`.\n\nTask: $ARGUMENTS"
}
'@

Set-Content -Path ".opencode/prompts/harness.json" -Value $harnessJson -Encoding UTF8

Write-Host "Local Harness Installed Successfully!" -ForegroundColor Green
Write-Host "Usage in OpenCode: /harness <your-command>"
