#!/usr/bin/env bash
# Run Claude Code in full YOLO mode (skip all permission prompts)
exec claude --dangerously-skip-permissions "$@"
