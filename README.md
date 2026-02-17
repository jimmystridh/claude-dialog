# claude-dialog

A native macOS dialog for [Claude Code](https://docs.anthropic.com/en/docs/claude-code)'s `AskUserQuestion` tool. Instead of answering questions inline in the terminal, a floating SwiftUI panel appears — with radio buttons, checkboxes, free-text input, and full keyboard navigation.

<img width="460" alt="claude-dialog screenshot" src="https://img.shields.io/badge/macOS-14%2B-blue?style=flat-square&logo=apple"> <!-- replace with actual screenshot -->

## How it works

Claude Code has a [hooks system](https://docs.anthropic.com/en/docs/claude-code/hooks) that lets you intercept tool calls. `claude-dialog` is a `PreToolUse` hook that:

1. Receives the `AskUserQuestion` JSON on **stdin**
2. Displays a native floating panel with all questions
3. Captures your selections (single-select, multi-select, free-text "Other")
4. Outputs a **deny** hook response to **stdout** with your answers embedded

The `deny` response suppresses the terminal widget entirely — you only see the native dialog. Claude receives your answers via the hook's `permissionDecisionReason` and proceeds without re-asking.

## Features

- **Single-select** questions with radio buttons
- **Multi-select** questions with checkboxes
- **"Other"** option on every question with a free-text field
- **Full keyboard navigation**: arrow keys to move, space to toggle, Return to confirm, Escape to cancel
- **Floating panel** that appears above all windows, including full-screen apps
- **No dock icon** — runs as an accessory process
- **Session context** — shows the working directory in the header
- **Frosted glass** background with automatic dark/light mode
- **Cancel = fallthrough** — if you cancel or close the dialog, the normal terminal prompt appears instead

## Requirements

- macOS 14 (Sonoma) or later
- Swift 6.0+ toolchain (included with Xcode 16+)
- Claude Code with hooks support

## Build

```bash
git clone <this-repo>
cd claude-dialog
swift build -c release
```

The binary lands at `.build/release/claude-dialog` (~350 KB).

For convenience, you can copy it somewhere on your PATH:

```bash
cp .build/release/claude-dialog /usr/local/bin/claude-dialog
```

## Integration

### Global (all Claude Code sessions)

Edit `~/.claude/settings.json` and add a `PreToolUse` hook for `AskUserQuestion`:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "AskUserQuestion",
        "hooks": [
          {
            "type": "command",
            "command": "/absolute/path/to/claude-dialog",
            "timeout": 120
          }
        ]
      }
    ]
  }
}
```

Replace `/absolute/path/to/claude-dialog` with either:
- The build output path: `/path/to/claude-dialog/.build/release/claude-dialog`
- Or wherever you copied the binary: `/usr/local/bin/claude-dialog`

> **Timeout**: The `timeout` value (in seconds) controls how long Claude Code waits for the hook before falling through. Set this high enough that you have time to read and answer — `120` is a safe default. The dialog itself has no countdown; it waits indefinitely for your input.

### Per-project

To scope this to a single project, add the same hook config to `.claude/settings.json` in the project root instead:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "AskUserQuestion",
        "hooks": [
          {
            "type": "command",
            "command": "/absolute/path/to/claude-dialog",
            "timeout": 120
          }
        ]
      }
    ]
  }
}
```

This file should be committed to the repo if you want the whole team to use it, or added to `.gitignore` if it's a personal preference.

### Merging with existing hooks

If you already have `PreToolUse` hooks, just add the `AskUserQuestion` matcher entry to the existing array. Matchers are checked in order and the first match wins:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "AskUserQuestion",
        "hooks": [
          {
            "type": "command",
            "command": "/absolute/path/to/claude-dialog",
            "timeout": 120
          }
        ]
      },
      {
        "matcher": "*",
        "hooks": [
          {
            "type": "command",
            "command": "your-other-hook"
          }
        ]
      }
    ]
  }
}
```

## Keyboard shortcuts

| Key | Action |
|-----|--------|
| `↑` `↓` | Move focus between options (crosses question boundaries) |
| `Space` | Toggle the focused option |
| `Return` | Confirm (submit all answers) |
| `Escape` | Cancel (falls through to terminal prompt) |

When the "Other" text field is active, arrow keys exit the field and resume option navigation. All other keys type into the field normally.

## How cancellation works

If you **cancel** the dialog (Escape, close button) or the hook **times out**, `claude-dialog` exits with code 0 and produces no stdout output. Claude Code treats this as "hook had nothing to say" and falls through to the normal terminal question widget — so you never lose the ability to answer.

## Architecture

```
stdin (JSON) → decode → NSApp (accessory) → NSPanel + SwiftUI → stdout (JSON) → exit
```

| File | Purpose |
|------|---------|
| `main.swift` | Entry point: stdin → app lifecycle → stdout |
| `Models.swift` | Codable structs for hook I/O + internal state |
| `DialogCoordinator.swift` | Observable state, keyboard handling, submit/cancel logic |
| `DialogWindow.swift` | NSPanel factory: floating, frosted glass, no dock icon |
| `DialogView.swift` | Root SwiftUI layout: header, questions, action bar |
| `QuestionView.swift` | Radio/checkbox options, "Other" text field, focus ring |
| `OutputFormatter.swift` | Builds the `permissionDecisionReason` string |

## Hook I/O format

**Input** (subset of what Claude Code sends on stdin):

```json
{
  "cwd": "/Users/you/project",
  "tool_name": "AskUserQuestion",
  "tool_input": {
    "questions": [
      {
        "question": "Which database should we use?",
        "header": "Database",
        "multiSelect": false,
        "options": [
          { "label": "PostgreSQL", "description": "Relational, great JSON support" },
          { "label": "SQLite", "description": "Embedded, zero-config" }
        ]
      }
    ]
  }
}
```

**Output** (written to stdout on confirm):

```json
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "User answered via native macOS dialog. [Database] Which database should we use? -> PostgreSQL. Do NOT re-ask these questions. Treat this as the user's final answer and proceed accordingly."
  }
}
```

## License

MIT
