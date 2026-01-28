# AGENTS.md

## Commit messages
- Use Conventional Commits: type(scope optional): short imperative
- Allowed types: feat, fix, docs, chore, refactor, test, perf, ci, build
- Examples:
  - feat: standardize mail checks in backup and sync
  - fix: log effective borg maintenance flags
  - docs: explain borg maintenance flags

## Shell script conventions (.sh)
- Strict mode: `set -euo pipefail`
- Structure: section headers for CONFIG, HELPERS, FLAGS/MODE, WORKER, LAUNCHER
- Logging: `info/warn/err` with `[YYYY-MM-DD HH:MM:SS±ZZZZ] [LEVEL] message`
- Launcher/worker split: `--run` for worker, launcher starts `screen` + logging
- Logging pipeline: `ts | tee -a` inside `screen`
- Guard checks early: dependencies (`screen`, `ts`, `mail`), locks, cooldown/running checks
- Exit codes: listed and commented at top; shared `20` for "mail missing"
- Mail reports: status header + metadata + tail of logfile
- Config: constants at top in UPPER_CASE; runtime values lower-case
- Test style: prefer `[[ ... ]]` over `[ ... ]` for conditionals
- Vars: always use `${VAR}` (braced) for interpolation
- Quotes: prefer single quotes only for true literals; never wrap `$var`, `$(cmd)`, or `"$@"` in single quotes
- Avoid blanket quote sweeps; change quotes only when you can prove no expansion or escape is required
- Reads: use `read -r` to avoid backslash mangling
- Exports: split command substitution from export, e.g. `VAR="$(cmd)"; export VAR`

## PowerShell script conventions (.ps1)
- Include requirements at top when needed: `# Requires -Version 7.0`, `# Requires -RunAsAdministrator` (must be first non-comment lines to be enforced)
- Prefer default error behavior: `$ErrorActionPreference = "Stop"`
- Admin check: use WindowsPrincipal; either exit with message or self-elevate via `Start-Process -Verb RunAs`
- Script-relative paths: prefer `$PSScriptRoot`/`$PSCommandPath`
- Optional UI helpers: `Show-Header/Show-OK/Show-Error` with `Write-Host` colors
- Dependencies: guard with `Get-Command ... -EA 0` or `Test-Path` before use
- Parallel work: `ForEach-Object -Parallel` with `-ThrottleLimit` (PS7+ only)

## Batch script conventions (.bat/.cmd)
- `@echo off` and `setlocal enabledelayedexpansion` when needed
- Start in script directory: `cd /d "%~dp0"`
- Admin: `net session` check, or self-elevate via PowerShell `Start-Process -Verb RunAs`
- Variables: always use `set "VAR=..."` to avoid stray spaces
- Args: parse with `%~1` and `if /i`, include usage via `%~n0`
- Flow: use `call :label` helpers and `goto :EOF` for returns
- Quiet/slow ops: use `>nul 2>&1` and `timeout /t` as needed
- Optional logging: write headers/date/time/user to a log file for long-running scripts
