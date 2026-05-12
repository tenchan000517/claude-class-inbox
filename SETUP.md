# Setup 手順（Claude Code 用）

Claude Code がこの package を読んだ時に follow する setup 手順。生徒（ユーザー）に対話で確認しながら、1 ステップずつ進めてください。

---

## ⚠️ Step 0: 安全圏チェック（最重要）

最初に必ず確認：

```bash
pwd
```

以下のいずれかに該当しなければ **作業を中断** して、生徒に移動を促してください：

- 結果が `/mnt/c/task/class/...` で始まっている
- 結果が `/mnt/c/task/class/claude-class-inbox` である（clone 直後・推奨）

該当しない場合の案内：

> **危険な場所で動いています**。Claude Code は cwd 内では何でも操作できます。`~` や `C:\` 配下で動いていると、誤判断で大事なファイルが消えるリスクがあります。
>
> 一度この Claude Code を停止して、以下を実行してから再度起動してください：
>
> ```bash
> mkdir -p /mnt/c/task/class
> cd /mnt/c/task/class
> tmux new -s claude
> claude
> ```

該当する場合のみ、以下を続けます。

---

## Step 1: tmux + 同期サービスの確認

### 1.1 tmux

```bash
which tmux
```

未 install なら：

> Syncthing をインストールします。**別の WSL Ubuntu ターミナルを開いて**（VS Code 下部メニュー → ターミナル → 新規 → WSL Ubuntu を選択）、以下を実行してください。パスワードを聞かれたら入力：
>
> ```bash
> sudo apt update && sudo apt install -y tmux
> ```

### 1.2 同期サービス（Syncthing 推奨）

#### 1.2.1 install チェック

```bash
which syncthing
```

未 install なら（生徒に丁寧に案内）：

> Syncthing をインストールします。**別の WSL Ubuntu ターミナルを開いて** 以下を実行してください。パスワードを聞かれたら入力してください。
>
> ```bash
> sudo apt update && sudo apt install -y syncthing
> ```
>
> install 完了したら教えてください。

#### 1.2.2 syncthing 起動

```bash
ps -ef | grep "[s]yncthing serve" | head -3
```

未起動なら：

```bash
nohup syncthing serve --no-browser > /tmp/syncthing.log 2>&1 &
```

確認：

```bash
sleep 3 && curl -s http://localhost:8384 | head -3
```

HTML が返れば OK。

#### 1.2.3 Device ID 取得

```bash
syncthing cli show system 2>/dev/null | grep myID
```

> あなたの Device ID は **`XXXX-XXXX-...`** です。これを先生に送ってください（LINE / Slack / メール何でも OK）。

#### 1.2.4 先生からの folder 共有を待つ

> 先生があなたの Device ID を承認して `claude-class-inbox` フォルダを共有すると、Web UI（http://localhost:8384）に「New Folder ... wants to share」の通知が出ます。
>
> 受け入れ時に local path を **`/mnt/c/task/class/inbox`** に設定してください（`~/claude-class-inbox` ではない・安全圏に置くため）。

確認：

```bash
ls /mnt/c/task/class/inbox/ 2>/dev/null
```

`all/` / `teacher/` / 自分の `student-<id>/` が見えれば同期成功。

---

## Step 2: 生徒情報の確認

生徒に質問：

- **student-id**：先生から指定された ID（例：`kawai`、`kawasaki`）
- **tmux session 名**：default は `claude`

---

## Step 3: 設定ファイルを書き出す

`<PACKAGE_DIR>/.env` に記録（PACKAGE_DIR は cwd の親 = `/mnt/c/task/class/claude-class-inbox` 想定）：

```bash
cat > <PACKAGE_DIR>/.env <<EOF
STUDENT_ID=<student-id>
CLAUDE_SESSION=<session-name>
SYNC_ROOT=/mnt/c/task/class
EOF
```

注: SYNC_ROOT は `/mnt/c/task/class`（inbox の親）。

---

## Step 4: skill を登録

```bash
bash <PACKAGE_DIR>/scripts/install-skill.sh
```

`~/.claude/skills/class-inbox/SKILL.md` が生成される（cwd 安全圏チェック + package path + 生徒情報が埋め込まれる）。

---

## Step 5: watcher を起動

```bash
cd <PACKAGE_DIR>
nohup env $(cat .env | xargs) bash scripts/student-watch.sh > /tmp/class-inbox-watcher.log 2>&1 &
```

起動確認：

```bash
ps -ef | grep student-watch | grep -v grep
```

---

## Step 6: 日常運用フローの案内

setup 完了。生徒に以下を明示伝達：

### 6.1 毎回のレクで必要な操作

1. VS Code を開く
2. 下部メニュー → ターミナル → 新規 → **WSL Ubuntu** を選択（cmd / PowerShell ではない）
3. `cd /mnt/c/task/class/`
4. `tmux new -s claude` （session が既にあれば `tmux attach -t claude`）
5. `claude`
6. Claude Code 内で「**授業準備**」or `/class-inbox start` と発言
7. skill が自動で syncthing 起動 / watcher 起動 / 新着メッセージ表示

### 6.2 離脱 / 復帰

| 操作 | コマンド |
|---|---|
| tmux session から離脱（落とさない） | `Ctrl-b` → `d` |
| 戻る | `tmux attach -t claude` |
| session 一覧 | `tmux ls` |
| 完全終了 | `tmux kill-session -t claude` |

### 6.3 PC 再起動後

PC を再起動すると tmux / syncthing / watcher 全部止まる。再起動後は 6.1 の流れを最初からやり直し。

### 6.4 skill 経由の操作

Claude Code 内（tmux attach 後）で：

- `/class-inbox` で skill 起動
- 「クラスメッセージ確認」「先生に返信」等の自然言語でも反応
- `/class-inbox archive` で local 保存（容量整理）

---

## トラブル時の確認ポイント

- 安全圏か：`pwd` が `/mnt/c/task/class/` 配下か
- tmux 稼働：`tmux ls`
- syncthing 稼働：`ps -ef | grep syncthing | grep -v grep`
- watcher 稼働：`ps -ef | grep student-watch | grep -v grep`
- 同期 folder にファイル：`ls /mnt/c/task/class/inbox/<self>/`
- watcher log：`tail /tmp/class-inbox-watcher.log`
- syncthing log：`tail /tmp/syncthing.log`
