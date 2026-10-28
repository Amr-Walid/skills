#!/usr/bin/env bash
# Install skills by flattening skills/<category>/<skill> into an agent's skills folder.
#
# Usage:
#   ./install.sh                         # all skills -> ~/.claude/skills (copy)
#   ./install.sh --agent codex           # -> ~/.codex/skills
#   ./install.sh --agent project         # -> ./.claude/skills of the current dir
#   ./install.sh --target /path/to/dir   # any folder
#   ./install.sh --only core,dotnet,database   # selected categories
#   ./install.sh --link                  # symlink instead of copy (git pull updates everything)
#   ./install.sh --list                  # list categories and counts
set -Eeuo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$REPO_DIR/skills"
TARGET="$HOME/.claude/skills"
ONLY=""
MODE="copy"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --agent)
      case "${2:-}" in
        claude)  TARGET="$HOME/.claude/skills" ;;
        codex)   TARGET="$HOME/.codex/skills" ;;
        gemini)  TARGET="$HOME/.gemini/skills" ;;
        project) TARGET="$PWD/.claude/skills" ;;
        *) echo "Unknown agent: ${2:-} (claude|codex|gemini|project)"; exit 1 ;;
      esac; shift 2 ;;
    --target) TARGET="$2"; shift 2 ;;
    --only)   ONLY="$2"; shift 2 ;;
    --link)   MODE="link"; shift ;;
    --list)
      for c in "$SRC"/*/; do printf '%-14s %s skills\n' "$(basename "$c")" "$(find "$c" -mindepth 2 -maxdepth 2 -name SKILL.md | wc -l)"; done
      exit 0 ;;
    -h|--help) sed -n '2,13p' "$0"; exit 0 ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

mkdir -p "$TARGET"
count=0
for dir in "$SRC"/*/*/; do
  [[ -f "$dir/SKILL.md" ]] || continue
  cat="$(basename "$(dirname "$dir")")"
  name="$(basename "$dir")"
  if [[ -n "$ONLY" && ",$ONLY," != *",$cat,"* ]]; then continue; fi
  dest="$TARGET/$name"
  rm -rf "$dest"
  if [[ "$MODE" == "link" ]]; then ln -s "${dir%/}" "$dest"; else cp -R "${dir%/}" "$dest"; fi
  count=$((count + 1))
done
echo "Installed $count skills ($MODE) into $TARGET"
