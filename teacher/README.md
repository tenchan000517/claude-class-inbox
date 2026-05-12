# teacher/ — 先生専用ツール

このディレクトリは **先生のみ実行** するスクリプトを格納します。生徒は実行しないでください（特に `cleanup.sh` は全 PC のクラウド同期に影響します）。

## ファイル

| ファイル | 用途 |
|---|---|
| `send.sh` | 先生 → 生徒のメッセージ送信 |
| `cleanup.sh` | クラウド上の inbox を削除（破壊的・授業節目で先生のみ実施） |

## send.sh

```bash
# 個人宛
bash send.sh alice today-task body.md

# 全員宛
echo "今日の課題は..." | bash send.sh all today-task -
```

## cleanup.sh（取扱注意）

クラウド同期の inbox を削除します。削除前に必ず local archive を取ります。

```bash
# 何が消えるか preview のみ（本番前に必ず実行）
bash cleanup.sh --dry-run --target all

# 全員宛 inbox をクリーン
bash cleanup.sh --target all

# 特定生徒の inbox をクリーン
bash cleanup.sh --target student alice

# 先生宛 inbox（生徒からの返信受信箱）をクリーン
bash cleanup.sh --target teacher

# 全部クリーン（学期末用）
bash cleanup.sh --target everything
```

### 安全装置

- 削除前に必ず `~/class-inbox-teacher-archive/<timestamp>-<target>/` に download
- `--dry-run` で事前確認可能
- 全員宛・他生徒・先生宛のクリーンはこの script でのみ実行（生徒の archive.sh では実施不可）

### 生徒側との分担

| 操作 | 先生 (teacher/cleanup.sh) | 生徒 (scripts/archive.sh) |
|---|---|---|
| 自分宛 inbox を local download | - | ◯ |
| 自分宛 inbox をクラウド削除 | - | ◯（--clean） |
| 全員宛 inbox を local download | ◯ | ◯（--include-all・read-only） |
| 全員宛 inbox をクラウド削除 | ◯ | ✕ |
| 他生徒 inbox をクラウド削除 | ◯ | ✕ |
| 先生宛 inbox をクラウド削除 | ◯ | ✕ |
