#!/bin/bash
# class-inbox skill を ~/.claude/skills/ に登録
#
# 前提:
# - 同ディレクトリの .env に STUDENT_ID / CLAUDE_SESSION / SYNC_ROOT が記録済
# - skill-template.md がテンプレ
#
# 動作:
# - placeholder を実値で埋めて ~/.claude/skills/class-inbox/SKILL.md に Write

set -eu

PACKAGE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="$PACKAGE_DIR/.env"
TEMPLATE="$PACKAGE_DIR/scripts/skill-template.md"
SKILL_DIR="$HOME/.claude/skills/class-inbox"
SKILL_FILE="$SKILL_DIR/SKILL.md"

if [ ! -f "$ENV_FILE" ]; then
    echo "ERROR: $ENV_FILE が存在しません。SETUP.md Step 4 を先に実施してください。" >&2
    exit 1
fi

if [ ! -f "$TEMPLATE" ]; then
    echo "ERROR: $TEMPLATE が存在しません。" >&2
    exit 2
fi

# .env から値を読む
# shellcheck disable=SC1090
set -a
source "$ENV_FILE"
set +a

: "${STUDENT_ID:?STUDENT_ID が .env で未設定}"
: "${CLAUDE_SESSION:?CLAUDE_SESSION が .env で未設定}"
: "${SYNC_ROOT:?SYNC_ROOT が .env で未設定}"

mkdir -p "$SKILL_DIR"

# template の placeholder を実値で置換
sed \
    -e "s|__PACKAGE_DIR__|$PACKAGE_DIR|g" \
    -e "s|__STUDENT_ID__|$STUDENT_ID|g" \
    -e "s|__SYNC_ROOT__|$SYNC_ROOT|g" \
    -e "s|__CLAUDE_SESSION__|$CLAUDE_SESSION|g" \
    "$TEMPLATE" > "$SKILL_FILE"

# teacher 用 inbox も作る（生徒 → 先生の返信先）
mkdir -p "$SYNC_ROOT/inbox/teacher"

echo "=== class-inbox skill 登録完了 ==="
echo "  skill:    $SKILL_FILE"
echo "  package:  $PACKAGE_DIR"
echo "  student:  $STUDENT_ID"
echo ""
echo "以降、Claude Code で「クラスメッセージ確認」「/class-inbox」等で起動できます。"
