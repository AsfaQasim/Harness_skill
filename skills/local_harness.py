import sys
import subprocess
import json
import shlex

# Whitelisted dangerous keywords to block
BLOCKED_COMMANDS = ["rm -rf", "del /f /s /q", "format", "shutdown", "mkfs"]

def run_in_harness(command: str, timeout: int = 30) -> str:
    """
    Local Harness Skill: Executes commands inside a monitored subprocess
    with strict timeout, command whitelisting, and output capture.
    """
    # 1. Security Inspection Guard
    for blocked in BLOCKED_COMMANDS:
        if blocked in command.lower():
            return json.dumps({
                "status": "blocked",
                "error": f"Harness Security Violation: '{blocked}' command is strictly prohibited."
            })

    try:
        # 2. Execution under Harness Supervision
        process = subprocess.run(
            command,
            shell=True,
            capture_output=True,
            text=True,
            timeout=timeout
        )

        # 3. Structure & Sanitize Execution Telemetry
        return json.dumps({
            "status": "success" if process.returncode == 0 else "failed",
            "exit_code": process.returncode,
            "stdout": process.stdout.strip(),
            "stderr": process.stderr.strip()
        })

    except subprocess.TimeoutExpired:
        return json.dumps({
            "status": "timeout",
            "error": f"Execution halted by Harness: Exceeded {timeout} seconds limit."
        })
    except Exception as e:
        return json.dumps({
            "status": "error",
            "error": str(e)
        })

if __name__ == "__main__":
    # Self-test harness wrapper
    test_cmd = "python --version" if len(sys.argv) < 2 else sys.argv[1]
    print(run_in_harness(test_cmd))