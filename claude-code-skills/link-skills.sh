#!/bin/zsh
# 把本 repo 的 claude-code-skills/ 下每个 skill 软链进 ~/.claude/skills/
# 新设备：git pull 后跑一次 `bash link-skills.sh`，重开 Claude Code 生效。
set -uo pipefail
SRC="$(cd "$(dirname "$0")" && pwd)"
DEST="$HOME/.claude/skills"
mkdir -p "$DEST"
for d in "$SRC"/*/; do
  name="$(basename "$d")"
  [ -f "$d/SKILL.md" ] || continue          # 只链真正的 skill 目录
  ln -sfn "${d%/}" "$DEST/$name"
  echo "linked: $name -> $DEST/$name"
done
echo "done. 重开 Claude Code 即生效。"
