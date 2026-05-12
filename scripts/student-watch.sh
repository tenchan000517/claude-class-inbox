#!/bin/bash
# 生徒側 watcher 起動スクリプト
#
# 使い方:
#   STUDENT_ID=alice CLAUDE_SESSION=my-claude bash student-watch.sh
#
# 前提:
# 1. クラウド同期サービス (Dropbox / Syncthing / Google Drive) で先生と
#    ~/claude-class-inbox/ 配下を同期している
# 2. tmux で claude code を起動している (session 名は CLAUDE_SESSION 環境変数で指定)
# 3. 自分の student-id (alice / bob / ...) を STUDENT_ID 環境変数で指定
#
# 動作:
# - inbox/<self-id>/ と inbox/all/ の両方を監視
# - 新着 .md を検知したら tmux pane に内容を投入
# - 生徒は次の turn でメッセージを読む

set -u

STUDENT_ID="${STUDENT_ID:-}"
CLAUDE_SESSION="${CLAUDE_SESSION:-claude}"
SYNC_ROOT="${SYNC_ROOT:-$HOME/claude-class-inbox}"

if [ -z "$STUDENT_ID" ]; then
    echo "ERROR: STUDENT_ID 環境変数を指定してください (例: STUDENT_ID=alice)" >&2
    exit 1
fi

if ! tmux has-session -t "$CLAUDE_SESSION" 2>/dev/null; then
    echo "ERROR: tmux session '$CLAUDE_SESSION' が見つかりません。" >&2
    echo "  先に tmux new -s $CLAUDE_SESSION で claude code を起動してください。" >&2
    exit 1
fi

SELF_INBOX="$SYNC_ROOT/inbox/$STUDENT_ID"
ALL_INBOX="$SYNC_ROOT/inbox/all"

mkdir -p "$SELF_INBOX" "$ALL_INBOX"

SELF_MARKER="/tmp/claude-class-marker-$STUDENT_ID-self"
ALL_MARKER="/tmp/claude-class-marker-$STUDENT_ID-all"
touch "$SELF_MARKER" "$ALL_MARKER"

TARGET="$CLAUDE_SESSION:0.0"

echo "=== claude-class-inbox 生徒側 watcher 起動 ==="
echo "  student-id: $STUDENT_ID"
echo "  tmux:       $TARGET"
echo "  自分 inbox: $SELF_INBOX"
echo "  共通 inbox: $ALL_INBOX"
echo ""
echo "Ctrl-C で停止"
echo ""

trap 'echo "停止しました。"; exit 0' SIGTERM SIGINT

dispatch_new_files() {
    local inbox="$1"
    local marker="$2"
    local label="$3"
    local new_files
    new_files=$(find "$inbox" -maxdepth 1 -name '*.md' -newer "$marker" 2>/dev/null)
    [ -z "$new_files" ] && return 0
    while IFS= read -r f; do
        [ -z "$f" ] && continue
        local basename
        basename=$(basename "$f")
        echo "[$(date +%T)] NEW ($label): $basename"
        if ! tmux list-panes -t "$TARGET" &>/dev/null; then
            echo "  WARN: tmux pane が消えました・送信スキップ"
            continue
        fi
        local prompt="新着メッセージ ($label) を読んで対応してください: $f"
        tmux send-keys -t "$TARGET" -- "$prompt"
        sleep 0.5
        tmux send-keys -t "$TARGET" C-m
        echo "  -> 送信完了"
    done <<< "$new_files"
}

while true; do
    dispatch_new_files "$SELF_INBOX" "$SELF_MARKER" "自分宛"
    touch "$SELF_MARKER"
    dispatch_new_files "$ALL_INBOX" "$ALL_MARKER" "全員"
    touch "$ALL_MARKER"
    sleep 5
done
