#!/bin/bash
# 先生側 メッセージ送信スクリプト
#
# 使い方:
#   bash teacher-send.sh <student-id|all> <topic> <body-file-or-stdin>
#
# 例:
#   bash teacher-send.sh alice debug-help body.md
#   echo "今日の課題は..." | bash teacher-send.sh all today-task -
#
# 動作:
# - クラウド同期フォルダ inbox/<target>/ に <ISO8601>-from-teacher-<topic>.md を Write
# - 数秒で生徒 PC に同期され、生徒の watcher が pane に投入する

set -u

# .env を自動 source（同ディレクトリの親 = PACKAGE_DIR を探す）
PACKAGE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="$PACKAGE_DIR/.env"
if [ -f "$ENV_FILE" ]; then
    # shellcheck disable=SC1090
    set -a
    source "$ENV_FILE"
    set +a
fi

TARGET="${1:-}"
TOPIC="${2:-}"
BODY_SRC="${3:-}"
SYNC_ROOT="${SYNC_ROOT:-$HOME/claude-class-inbox}"

if [ -z "$TARGET" ] || [ -z "$TOPIC" ] || [ -z "$BODY_SRC" ]; then
    echo "Usage: $0 <student-id|all> <topic> <body-file-or-->" >&2
    echo "  例: $0 alice debug-help body.md" >&2
    echo "  例: echo 'today task...' | $0 all today-task -" >&2
    exit 1
fi

INBOX_DIR="$SYNC_ROOT/inbox/$TARGET"
if [ ! -d "$INBOX_DIR" ]; then
    echo "ERROR: inbox dir '$INBOX_DIR' が存在しません。" >&2
    exit 2
fi

TIMESTAMP=$(date -u +%Y-%m-%dT%H%M%SZ)
FILENAME="$INBOX_DIR/${TIMESTAMP}-from-teacher-${TOPIC}.md"

if [ "$BODY_SRC" = "-" ]; then
    BODY=$(cat)
else
    if [ ! -f "$BODY_SRC" ]; then
        echo "ERROR: body file '$BODY_SRC' が見つかりません。" >&2
        exit 2
    fi
    BODY=$(cat "$BODY_SRC")
fi

cat > "$FILENAME" <<EOF
---
from: teacher
to: $TARGET
topic: $TOPIC
timestamp: $TIMESTAMP
---

$BODY
EOF

echo "送信完了: $FILENAME"
