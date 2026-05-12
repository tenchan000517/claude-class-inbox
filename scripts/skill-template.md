---
name: class-inbox
description: 授業の class-inbox システム。先生からの remote 指示を確認・対応・返信する。Use when user says 'クラスメッセージ', 'クラスチェック', 'クラスメッセージ確認', '先生からのメッセージ', 'class-inbox', '/class-inbox', or asks about teacher's instructions from the class inbox system.
---

# class-inbox skill

授業の class-inbox システム。`__PACKAGE_DIR__` に設定された生徒側 package を経由して、先生 PC からクラウド同期で届くメッセージを管理する。

## 環境

- **package**: `__PACKAGE_DIR__`
- **student-id**: `__STUDENT_ID__`
- **同期 root**: `__SYNC_ROOT__`
- **tmux session**: `__CLAUDE_SESSION__`
- **自分宛 inbox**: `__SYNC_ROOT__/inbox/__STUDENT_ID__/`
- **全員宛 inbox**: `__SYNC_ROOT__/inbox/all/`
- **先生 inbox**（返信先）: `__SYNC_ROOT__/inbox/teacher/`

## 操作

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

数秒で先生 PC に同期される。

### watcher の状態確認

```bash
ps -ef | grep student-watch | grep -v grep
tail -20 /tmp/class-inbox-watcher.log
```

### watcher 再起動

```bash
pkill -f student-watch.sh
cd __PACKAGE_DIR__ && nohup env $(cat .env | xargs) bash scripts/student-watch.sh > /tmp/class-inbox-watcher.log 2>&1 &
```

### archive（自分宛のみ・生徒側で実施可）

授業の節目で、自分宛メッセージを local archive に保存する：

```bash
# 自分宛だけ download（クラウドはそのまま・誰にも影響しない）
bash __PACKAGE_DIR__/scripts/archive.sh

# 自分宛 download + 自分宛クラウドを削除（自分にしか影響しない）
bash __PACKAGE_DIR__/scripts/archive.sh --clean

# 自分宛 + 全員宛も local に copy（read-only・クラウドは触らない）
bash __PACKAGE_DIR__/scripts/archive.sh --include-all
```

archive 先：`~/class-inbox-archive/__STUDENT_ID__-<timestamp>/`

### 注意：全員宛 inbox の削除はできない

`inbox/all/` のクラウド削除は他の生徒に影響するため、生徒側からは実施できません。学期末等のクリーンは先生が `teacher/cleanup.sh` で実施します。

### archive 履歴の確認

```bash
ls -lt ~/class-inbox-archive/
```

## ルール

- 受信したメッセージファイルは **削除しない**（履歴として残す）
- 返信時は student-id を必ず明記
- 先生に質問する時も同じ経路（inbox/teacher/）を使う
- watcher が止まっていたら再起動を提案する
