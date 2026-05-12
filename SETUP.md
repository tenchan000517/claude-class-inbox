# Setup 手順（Claude Code 用）

Claude Code がこの package を読んだ時に follow する setup 手順です。生徒（ユーザー）に対話で確認しながら進めてください。

## Step 0: package path の確定

このファイル（SETUP.md）が置かれているディレクトリの絶対パスを記録してください。以降 `<PACKAGE_DIR>` と呼びます。

```bash
PACKAGE_DIR=$(cd "$(dirname "${0:-./SETUP.md}")" && pwd)
```

## Step 1: tmux + 同期サービスの確認

### 1.1 tmux

```bash
which tmux
```

無ければインストール手順を案内：

| OS | コマンド |
|---|---|
| Ubuntu / WSL | `sudo apt install tmux` |
| Mac | `brew install tmux` |
| Windows | WSL2 + Ubuntu を入れてその中で `sudo apt install tmux` |

### 1.2 同期サービス（Syncthing 推奨・Drive はフォールバック）

#### Syncthing の場合

```bash
which syncthing
```

無ければ：

| OS | コマンド |
|---|---|
| Ubuntu / WSL | `sudo apt install syncthing` |
| Mac | `brew install syncthing` |
| Windows | https://syncthing.net/downloads/ から SyncTrayzor |

インストール後、Web UI（http://localhost:8384）にアクセスできれば OK。

生徒に以下を質問・案内：

1. Syncthing 起動済か？（`syncthing` または OS タスクトレイの SyncTrayzor）
2. 自分の Device ID を確認したか？（Web UI 右上「Actions」→「Show ID」）
3. 先生に自分の Device ID を共有したか？
4. 先生から folder share の招待が来ているか？受け入れて local path を `~/claude-class-inbox` に設定したか？

Syncthing が **両方向で接続済 + folder share 受領済** になっていれば、`~/claude-class-inbox/inbox/all/` 等が見えるはず。

#### Drive for desktop の場合

ストリーム モードでも mirror モードでも可。生徒に：

1. Drive for desktop 起動済か？
2. 先生から `claude-class-inbox/` フォルダの共有招待を受け入れたか？
3. `~/Google Drive/My Drive/claude-class-inbox/` または `~/Library/CloudStorage/GoogleDrive-<account>/My Drive/claude-class-inbox/` が見えるか？（OS により path 異なる）

## Step 2: 生徒情報の確認

生徒に以下を質問する：

- **student-id**：先生から指定された ID（例：`alice`、`bob`）
- **tmux session 名**：Claude Code を起動する session 名（default: `claude`）
- **同期フォルダ path**：クラウド同期サービス（Dropbox / Syncthing / Google Drive 等）が `~/claude-class-inbox/` に同期するよう設定済か確認。違うパスなら教えてもらう（default: `$HOME/claude-class-inbox`）

## Step 3: inbox 構造の確認

同期フォルダに以下が存在するか確認：

```
<sync-root>/inbox/all/
<sync-root>/inbox/<student-id>/
```

無ければ作成：

```bash
mkdir -p <sync-root>/inbox/all <sync-root>/inbox/<student-id>
```

注：先生側で既に作成済みの場合はクラウド同期で降ってくるはず。降ってこない場合は先生に確認するよう案内。

## Step 4: 設定ファイルを書き出す

`<PACKAGE_DIR>/.env` に確定した設定を記録：

```bash
cat > <PACKAGE_DIR>/.env <<EOF
STUDENT_ID=<student-id>
CLAUDE_SESSION=<session-name>
SYNC_ROOT=<sync-root>
EOF
```

## Step 5: skill を登録

```bash
bash <PACKAGE_DIR>/scripts/install-skill.sh
```

これで `~/.claude/skills/class-inbox/SKILL.md` が生成される（package path と生徒情報が埋め込まれる）。

## Step 6: watcher を起動

```bash
cd <PACKAGE_DIR>
nohup env $(cat .env | xargs) bash scripts/student-watch.sh > /tmp/class-inbox-watcher.log 2>&1 &
```

起動確認：

```bash
ps -ef | grep student-watch | grep -v grep
```

## Step 7: 日常運用フローの案内

setup が終わっただけでは生徒は Claude Code を使えません。**毎日の起動・離脱・再 attach** の流れを生徒に明示してください。

### 7.1 初回の Claude Code 起動

別ターミナルを開いて：

```bash
tmux new -s <session-name>    # 例: tmux new -s claude
```

これで tmux session が立ち上がり、自動的に attach 状態になる。中で：

```bash
claude
```

これで Claude Code が起動。先生からメッセージが来るとここに自動投入される。

### 7.2 セッションを残したまま離脱（detach）

PC を閉じる時や別作業に移る時：

```
Ctrl-b → d
```

Claude Code は tmux 内で動き続ける。ターミナルから抜けても OK。

### 7.3 戻る（attach）

```bash
tmux attach -t <session-name>    # 例: tmux attach -t claude
```

中で Claude Code がそのまま動いている状態に戻れる。会話履歴も残っている。

### 7.4 session 一覧確認

```bash
tmux ls
```

`claude: 1 windows (created ...)` のように表示されれば稼働中。

### 7.5 session を完全に終了させたい時

```bash
tmux kill-session -t <session-name>
```

（普段は kill する必要なし。detach で十分）

### 7.6 watcher の状態確認 / 再起動

watcher は setup 時に background 起動済。状態確認：

```bash
ps -ef | grep student-watch | grep -v grep
```

止まっていたら再起動：

```bash
pkill -f student-watch.sh
cd <PACKAGE_DIR> && nohup env $(cat .env | xargs) bash scripts/student-watch.sh > /tmp/class-inbox-watcher.log 2>&1 &
```

### 7.7 skill 経由の操作

Claude Code 内（tmux attach 後）で：

- `/class-inbox` で skill を呼び出し
- 「クラスメッセージ確認」「先生に返信」等の自然言語でも反応
- 新着があれば一覧表示、Read で開く、返信 Write など

### 7.8 PC 再起動後

PC を再起動すると tmux session も watcher も止まる。再起動後は：

```bash
# 1. tmux で Claude Code 起動
tmux new -s <session-name>
# 中で claude

# 2. 別ターミナルで watcher 再起動（7.6 の再起動コマンド）
```

頻繁に再起動するなら、watcher を起動する shell 関数や alias を `.bashrc` に書いておくと楽。

## トラブル時の確認ポイント

- tmux session が稼働中か：`tmux ls`
- watcher が稼働中か：`ps -ef | grep student-watch`
- 同期フォルダにファイルが届くか：`ls <sync-root>/inbox/<student-id>/`
- watcher log：`tail /tmp/class-inbox-watcher.log`
