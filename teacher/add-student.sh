#!/bin/bash
# 新規 student inbox folder を teacher 側に作成
#
# 使い方:
#   bash add-student.sh <student-id>
#
# 例:
#   bash add-student.sh alice
#   bash add-student.sh kawai
#
# 動作:
# - $SYNC_ROOT/inbox/student-<id>/ を mkdir
# - Syncthing が数秒で生徒側にも同期する
#
# 設計意図:
# 生徒の student-id を事前にハードコードせず、生徒が決まったタイミングで
# 動的に folder を作る。新しい生徒が増えるたびにこの 1 行を実行する。

set -u

PACKAGE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="$PACKAGE_DIR/.env"
if [ -f "$ENV_FILE" ]; then
    # shellcheck disable=SC1090
    set -a
    source "$ENV_FILE"
    set +a
fi

SYNC_ROOT="${SYNC_ROOT:-$HOME/claude-class-inbox}"
STUDENT_ID="${1:-}"

if [ -z "$STUDENT_ID" ]; then
    echo "Usage: $0 <student-id>" >&2
    echo "  例: $0 alice" >&2
    exit 1
fi

# ID の正規化チェック（小文字英数とハイフンのみ）
if ! [[ "$STUDENT_ID" =~ ^[a-z0-9-]+$ ]]; then
    echo "ERROR: student-id は小文字英数とハイフンのみ。指定: '$STUDENT_ID'" >&2
    exit 2
fi

INBOX_DIR="$SYNC_ROOT/inbox/student-$STUDENT_ID"

if [ -d "$INBOX_DIR" ]; then
    echo "[INFO] 既に存在: $INBOX_DIR"
else
    mkdir -p "$INBOX_DIR"
    echo "作成完了: $INBOX_DIR"
fi

echo ""
echo "Syncthing が数秒で生徒側に同期します。"
echo "生徒側で確認: ls /mnt/c/task/class/inbox/inbox/student-$STUDENT_ID/"
