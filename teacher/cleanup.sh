#!/bin/bash
# class-inbox クラウドクリーンアップ（先生用・破壊的）
#
# 使い方:
#   bash cleanup.sh --dry-run                    # 何が消えるか preview のみ
#   bash cleanup.sh --target all                 # inbox/all/ をクリーン
#   bash cleanup.sh --target student <id>        # 特定生徒の inbox をクリーン
#   bash cleanup.sh --target teacher             # inbox/teacher/ をクリーン
#   bash cleanup.sh --target everything          # 全部クリーン（学期末）
#
# 全ての操作で：
# 1. ローカル archive を必ず取る（消えるファイルを download）
# 2. その後にクラウド上を削除
#
# 環境:
#   .env から SYNC_ROOT を読む
#   TEACHER_ARCHIVE_DIR で archive 先指定（default: ~/class-inbox-teacher-archive）

set -eu

PACKAGE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="$PACKAGE_DIR/.env"

if [ ! -f "$ENV_FILE" ]; then
    echo "ERROR: $ENV_FILE が存在しません。" >&2
    exit 1
fi

# shellcheck disable=SC1090
set -a
source "$ENV_FILE"
set +a

: "${SYNC_ROOT:?SYNC_ROOT 未設定}"

TEACHER_ARCHIVE_DIR="${TEACHER_ARCHIVE_DIR:-$HOME/class-inbox-teacher-archive}"

DRY_RUN=false
TARGET=""
STUDENT_ID_TO_CLEAN=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run) DRY_RUN=true; shift ;;
        --target)
            TARGET="$2"
            shift 2
            if [ "$TARGET" = "student" ]; then
                STUDENT_ID_TO_CLEAN="${1:-}"
                if [ -z "$STUDENT_ID_TO_CLEAN" ]; then
                    echo "ERROR: --target student の後に student-id が必要" >&2
                    exit 1
                fi
                shift
            fi
            ;;
        *) echo "Unknown option: $1" >&2; exit 1 ;;
    esac
done

if [ -z "$TARGET" ]; then
    cat >&2 <<USAGE
Usage:
  $0 --dry-run --target all
  $0 --target all
  $0 --target student <id>
  $0 --target teacher
  $0 --target everything

  --dry-run: 何が消えるか preview のみ（推奨：本番前に必ず実行）
USAGE
    exit 1
fi

TIMESTAMP=$(date +%Y%m%d-%H%M%S)
ARCHIVE_TARGET="$TEACHER_ARCHIVE_DIR/$TIMESTAMP-$TARGET"
mkdir -p "$ARCHIVE_TARGET"

clean_one() {
    local dir="$1"
    local label="$2"

    if [ ! -d "$dir" ]; then
        echo "  skip: $dir （存在しない）"
        return 0
    fi
    local count
    count=$(find "$dir" -maxdepth 1 -name '*.md' 2>/dev/null | wc -l)
    if [ "$count" -eq 0 ]; then
        echo "  skip: $dir （0 件）"
        return 0
    fi

    if [ "$DRY_RUN" = "true" ]; then
        echo "  [dry-run] $dir → $count files を削除予定"
        return 0
    fi

    # 必ず archive を取ってから削除
    mkdir -p "$ARCHIVE_TARGET/$label"
    cp "$dir"/*.md "$ARCHIVE_TARGET/$label/"
    rm -f "$dir"/*.md
    echo "  archived + cleaned: $dir ($count files → $ARCHIVE_TARGET/$label/)"
}

echo "=== class-inbox cleanup (先生用) ==="
echo "  target:     $TARGET"
echo "  dry-run:    $DRY_RUN"
echo "  archive to: $ARCHIVE_TARGET"
echo ""

case "$TARGET" in
    all)
        clean_one "$SYNC_ROOT/inbox/all" "all"
        ;;
    student)
        clean_one "$SYNC_ROOT/inbox/$STUDENT_ID_TO_CLEAN" "student-$STUDENT_ID_TO_CLEAN"
        ;;
    teacher)
        clean_one "$SYNC_ROOT/inbox/teacher" "teacher"
        ;;
    everything)
        clean_one "$SYNC_ROOT/inbox/all" "all"
        clean_one "$SYNC_ROOT/inbox/teacher" "teacher"
        # 全生徒 inbox を回す
        for d in "$SYNC_ROOT/inbox"/*/; do
            sub=$(basename "$d")
            case "$sub" in
                all|teacher) ;;
                *) clean_one "$d" "student-$sub" ;;
            esac
        done
        ;;
    *)
        echo "ERROR: 未知の target: $TARGET" >&2
        exit 1
        ;;
esac

echo ""
if [ "$DRY_RUN" = "true" ]; then
    echo "=== dry-run 完了（実削除はしていません）==="
else
    echo "=== 完了 ==="
    echo "archive: $ARCHIVE_TARGET"
fi
