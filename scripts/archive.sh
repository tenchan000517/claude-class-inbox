#!/bin/bash
# class-inbox archive コマンド（生徒用）
#
# 使い方:
#   bash archive.sh                  # 自分宛 inbox を local archive に download（クラウドは触らない）
#   bash archive.sh --clean          # 自分宛 download + 自分宛クラウドを削除（自分にしか影響しない）
#   bash archive.sh --include-all    # 自分宛 + 全員宛も local に download（read-only コピー・クラウドは触らない）
#
# 環境:
#   .env から STUDENT_ID / SYNC_ROOT を読む
#   ARCHIVE_DIR 環境変数で local archive 先を変更可能（default: ~/class-inbox-archive）
#
# 安全性:
# - 自分宛 inbox（inbox/<student-id>/）以外をクラウドから削除する操作は本スクリプトに無い
# - 全員宛 inbox（inbox/all/）のクラウド削除は teacher/cleanup.sh で先生のみが実施する

set -eu

PACKAGE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="$PACKAGE_DIR/.env"

if [ ! -f "$ENV_FILE" ]; then
    echo "ERROR: $ENV_FILE が存在しません。SETUP を先に実施してください。" >&2
    exit 1
fi

# shellcheck disable=SC1090
set -a
source "$ENV_FILE"
set +a

: "${STUDENT_ID:?STUDENT_ID 未設定}"
: "${SYNC_ROOT:?SYNC_ROOT 未設定}"

ARCHIVE_DIR="${ARCHIVE_DIR:-$HOME/class-inbox-archive}"

INCLUDE_ALL=false
DO_CLEAN=false
for arg in "$@"; do
    case "$arg" in
        --include-all) INCLUDE_ALL=true ;;
        --clean)       DO_CLEAN=true ;;
        *) echo "Unknown option: $arg" >&2; exit 1 ;;
    esac
done

TIMESTAMP=$(date +%Y%m%d-%H%M%S)
TARGET="$ARCHIVE_DIR/$STUDENT_ID-$TIMESTAMP"
mkdir -p "$TARGET"

archive_dir() {
    local src="$1"
    local dst_name="$2"
    local clean="$3"

    if [ ! -d "$src" ]; then
        echo "  skip: $src （存在しない）"
        return 0
    fi
    local count
    count=$(find "$src" -maxdepth 1 -name '*.md' 2>/dev/null | wc -l)
    if [ "$count" -eq 0 ]; then
        echo "  skip: $src （ファイル 0 件）"
        return 0
    fi

    mkdir -p "$TARGET/$dst_name"
    cp "$src"/*.md "$TARGET/$dst_name/"
    echo "  archived $count files: $src -> $TARGET/$dst_name/"

    if [ "$clean" = "true" ]; then
        rm -f "$src"/*.md
        echo "  cleaned cloud: $src"
    fi
}

echo "=== class-inbox archive (生徒用) ==="
echo "  student-id: $STUDENT_ID"
echo "  archive to: $TARGET"
echo "  clean own:  $DO_CLEAN"
echo ""

# 自分宛（--clean OK・自分にしか影響しない）
archive_dir "$SYNC_ROOT/inbox/$STUDENT_ID" "self" "$DO_CLEAN"

# 全員宛（--include-all で download のみ・クラウドは絶対に触らない）
if [ "$INCLUDE_ALL" = "true" ]; then
    archive_dir "$SYNC_ROOT/inbox/all" "all-readonly-copy" "false"
fi

echo ""
echo "=== 完了 ==="
echo "local archive: $TARGET"
ls -la "$TARGET" 2>/dev/null | tail -n +2
echo ""
echo "※ 全員宛 inbox（inbox/all/）のクラウド削除は先生のみが実施します。"
