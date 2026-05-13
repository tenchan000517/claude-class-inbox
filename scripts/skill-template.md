---
name: class-inbox
description: 授業の class-inbox システム。先生からの remote 指示を確認・対応・返信する。Use when user says '授業準備', 'クラスメッセージ', 'クラスチェック', 'クラスメッセージ確認', '先生からのメッセージ', 'class-inbox', '/class-inbox', '/class-inbox start', 'class start', '授業始める', or asks about teacher's instructions from the class inbox system.
---

# class-inbox skill

授業の class-inbox システム。`__PACKAGE_DIR__` に設定された生徒側 package を経由して、先生 PC からクラウド同期で届くメッセージを管理する。

## 環境

- **package**: `__PACKAGE_DIR__`
- **student-id**: `__STUDENT_ID__`
- **同期 root**: `__SYNC_ROOT__`（SYNC_ROOT/inbox/ 配下にメッセージ実体）
- **tmux session**: `__CLAUDE_SESSION__`
- **自分宛 inbox**: `__SYNC_ROOT__/inbox/__STUDENT_ID__/`
- **全員宛 inbox**: `__SYNC_ROOT__/inbox/all/`
- **先生 inbox**（返信先）: `__SYNC_ROOT__/inbox/teacher/`

---

## ⚠️ 起動時の安全圏チェック（必ず最初に実施）

```bash
pwd
echo "TMUX=$TMUX"
```

### A. cwd が `/mnt/c/task/class/` 配下でない場合

**動作拒否**。生徒に以下を案内：

> このセッションは安全圏（`/mnt/c/task/class/`）の外で動いています。
> Claude Code の auto mode は cwd 内では制限なく操作するため、`~` や `C:\` で動かしていると誤判断で大事なファイルが消えるリスクがあります。
>
> 一度この Claude Code を停止して、以下を実行してから再度起動してください：
>
> ```bash
> cd /mnt/c/task/class
> tmux new -s claude        # session 既存なら attach
> claude
> ```
>
> その後「授業準備」と発言してください。

### B. cwd は安全圏だが、TMUX 環境変数が空 = tmux の外で動いている

**動作可能だが watcher の送信先が無い**。生徒に：

> tmux の外で動いています。watcher からのメッセージ自動投入が効きません。
>
> 一度この Claude Code を停止して、以下を実行してから再度起動してください：
>
> ```bash
> tmux new -s claude
> claude
> ```

### C. cwd が安全圏 + TMUX 内

OK。以下の操作に進む。

---

## 「授業準備」/ `/class-inbox start` 系の操作

生徒から「授業準備」「class-inbox start」「授業始める」等を受けたら、以下を順次実行：

### 1. Syncthing 起動チェック

```bash
ps -ef | grep "[s]yncthing serve" | head -3
```

未起動なら：

```bash
nohup syncthing serve --no-browser > /tmp/syncthing.log 2>&1 &
sleep 3
```

確認：

```bash
curl -s http://localhost:8384 | head -3
```

### 2. Syncthing 接続状態確認

```bash
syncthing cli show connections 2>/dev/null
```

先生 PC との接続が立っていれば OK。立っていなければ生徒に通知：

> 先生 PC への Syncthing 接続が確立されていません。先生 PC が起動してオンラインか、Device ID 共有が完了しているか確認してください。

### 3. watcher 起動チェック（Monitor tool 経由）

Claude Code の **Monitor tool** で watcher が稼働中か確認。稼働していなければ、Monitor tool で以下を起動する（**nohup ではなく Monitor tool で起動することで Claude Code が監視可能になる**）。

| Monitor 設定 | 値 |
|---|---|
| description | `class-inbox watcher (__STUDENT_ID__)` |
| persistent | `true` |
| timeout_ms | `3600000` |
| command | 下記スクリプト |

```bash
STUDENT_ID="__STUDENT_ID__"
CLAUDE_SESSION="__CLAUDE_SESSION__"
SYNC_ROOT="__SYNC_ROOT__"
PROCESSED="/tmp/class-inbox-processed-$STUDENT_ID"
touch "$PROCESSED"
TARGET="$CLAUDE_SESSION:0.0"

dispatch() {
  local inbox="$1" label="$2"
  for f in "$inbox"/*.md; do
    [ -e "$f" ] || continue
    if ! grep -Fxq "$f" "$PROCESSED"; then
      echo "[$(date +%T)] NEW ($label): $(basename "$f")"
      if tmux list-panes -t "$TARGET" &>/dev/null; then
        tmux send-keys -t "$TARGET" -- "新着メッセージ ($label) を読んで対応してください: $f"
        sleep 0.5
        tmux send-keys -t "$TARGET" C-m
      fi
      echo "$f" >> "$PROCESSED"
    fi
  done
}

while true; do
  dispatch "$SYNC_ROOT/inbox/$STUDENT_ID" "自分宛"
  dispatch "$SYNC_ROOT/inbox/all" "全員宛"
  sleep 5
done
```

設計ポイント：
- **処理済リスト方式**（`$PROCESSED` ファイルで dispatch 済を管理）→ Syncthing の mtime 保持問題に影響されない
- **Monitor tool 経由**で起動するため、Claude Code が watcher 稼働を監視・通知できる（旧 nohup 方式は監視外だった）

旧 `scripts/student-watch.sh` は historical reference として残るが、本 skill では使わない。

### 4. 新着メッセージ確認

```bash
ls -lt __SYNC_ROOT__/inbox/__STUDENT_ID__/*.md 2>/dev/null
ls -lt __SYNC_ROOT__/inbox/all/*.md 2>/dev/null
```

未読があれば一覧を見せて、興味あるものを Read で開く。

### 5. ステータス summary を生徒に提示

```
=== 授業準備完了 ===
- Syncthing: 起動中 ✓
- 先生 PC 接続: ✓
- watcher: 起動中 ✓
- 自分宛 新着: N 件
- 全員宛 新着: N 件
```

---

## その他の操作

### 新着・未読メッセージを確認

```bash
ls -lt __SYNC_ROOT__/inbox/__STUDENT_ID__/*.md 2>/dev/null
ls -lt __SYNC_ROOT__/inbox/all/*.md 2>/dev/null
```

→ 一覧をユーザーに見せる。各ファイルを Read で読む。

### 先生に返信を送る

返信内容をユーザーに確認後、以下のフォーマットで write：

```
__SYNC_ROOT__/inbox/teacher/<ISO8601>-from-__STUDENT_ID__-<topic>.md
```

```
---
from: __STUDENT_ID__
to: teacher
topic: <topic>
timestamp: <ISO8601>
---

<body>
```

**Write 直後に Syncthing rescan を強制トリガー**（必須・省略禁止）。Syncthing の fsWatcher が新規ファイルを取りこぼすことがあり、これを省くと先生側に届くのが大幅に遅延する or 届かない事態が発生する：

```bash
# Syncthing config の場所は環境によって異なる（~/.local/state/syncthing/ or ~/.config/syncthing/）
for CFG in ~/.local/state/syncthing/config.xml ~/.config/syncthing/config.xml; do
  if [ -f "$CFG" ]; then
    APIKEY=$(grep '<apikey>' "$CFG" | sed 's/.*<apikey>\(.*\)<\/apikey>.*/\1/')
    curl -s -X POST -H "X-API-Key: $APIKEY" "http://localhost:8384/rest/db/scan?folder=class-inbox-2026" > /dev/null
    break
  fi
done
```

これで数秒で先生 PC に同期される。**この rescan trigger を組み込まないと、生徒の返信が teacher 側に届かない問題が再発するため、返信送信フローでは必須**。

### archive（自分宛のみ・生徒側で実施可）

```bash
# 自分宛だけ download（クラウドはそのまま）
bash __PACKAGE_DIR__/scripts/archive.sh

# 自分宛 download + 自分宛クラウドを削除
bash __PACKAGE_DIR__/scripts/archive.sh --clean

# 自分宛 + 全員宛も local に copy（read-only）
bash __PACKAGE_DIR__/scripts/archive.sh --include-all
```

archive 先：`~/class-inbox-archive/__STUDENT_ID__-<timestamp>/`

### 注意：全員宛 inbox の削除はできない

`inbox/all/` のクラウド削除は他の生徒に影響するため、生徒側からは実施できません。学期末等のクリーンは先生のみが実施します。

### watcher 再起動

旧 watcher プロセスがあれば停止：

```bash
pkill -f student-watch.sh
```

その後、§「授業準備」§3 の Monitor tool 起動手順を再実行（処理済リストは `$PROCESSED` ファイルにあるので、再起動しても既処理ファイルは再 dispatch されない）。

完全に最初から拾い直したい場合は `$PROCESSED` ファイルを削除してから Monitor 再起動：

```bash
rm -f /tmp/class-inbox-processed-__STUDENT_ID__
```

---

## ルール

- 受信したメッセージファイルは **削除しない**（履歴として残す）
- 返信時は student-id を必ず明記
- 先生に質問する時も同じ経路（inbox/teacher/）を使う
- watcher が止まっていたら再起動を提案する
- cwd 安全圏（`/mnt/c/task/class/`）から外れたら操作を拒否
