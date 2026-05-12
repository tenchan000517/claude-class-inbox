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

> tmux をインストールします。**別の WSL ウィンドウを開きます**：
>
> `Ctrl+Shift+P`（Command Palette）→ `WSL: Connect to WSL in New Window` を選択
>
> 新しい VS Code ウィンドウが WSL Ubuntu モードで開きます。そのウィンドウで `Ctrl+\`` でターミナルを開いて：
>
> ```bash
> sudo apt update && sudo apt install -y tmux
> ```
>
> パスワードを聞かれたら入力。install 完了したら、最初の Claude Code ターミナルに戻って「インストール完了」と伝えてください。
>
> **このウィンドウは閉じないでください**。Syncthing の install 等で再利用します。

### 1.2 同期サービス（Syncthing 推奨）

#### 1.2.1 install チェック

```bash
which syncthing
```

未 install なら（生徒に丁寧に案内）：

> Syncthing をインストールします。**先ほど tmux を入れた WSL ウィンドウ（2 番目のウィンドウ）を再利用**してください。そこのターミナルで：
>
> ```bash
> sudo apt install -y syncthing
> ```
>
> （`apt update` は tmux install 時に既に走ってるので省略可）
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

- **student-id**：先生から指定された ID（例：`alice`、`bob`・小文字英数とハイフンのみ）
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

## Step 5: 初回 setup 完了 + tmux 移行の案内

ここまでで環境構築・skill 登録は完了。watcher の起動は **次のステップ（tmux 移行後・skill が自動で実施）** に委ねます。初回 setup ではここで一度 Claude Code を抜けて、tmux 上で再起動する流れを生徒に教えてください：

### 5.1 一度この Claude Code を終了

Claude Code 内で `Ctrl-C` を 2 回 or `exit` で抜けてもらう。

### 5.2 tmux とは何か（生徒が初めての場合は短く説明）

> tmux は「ターミナルの中で複数の session を持てる仕組み」です。Claude Code を tmux の中で動かす理由：
>
> 1. PC を一度閉じても session が残るので、戻れる
> 2. 先生からのメッセージを watcher が tmux 経由で自動投入できる（class-inbox の必須要件）

### 5.3 tmux 起動 + Claude Code 再起動

別ターミナル（同じ WSL Ubuntu）で：

```bash
cd /mnt/c/task/class
tmux new -s claude
```

`tmux new -s claude` を打つと session が起動して自動的に attach 状態になる（プロンプトの見た目が変わる）。中で：

```bash
claude
```

これで tmux 内 Claude Code が起動。

### 5.4 「授業準備」を呼ぶ

Claude Code 内で：

> 授業準備

skill が起動して：
- syncthing 稼働チェック（必要なら起動）
- 先生 PC との接続チェック
- watcher 起動（tmux pane 自動投入を有効化）
- 新着メッセージ表示

これでレク開始可能な状態に。

---

## Step 6: 日常運用（毎回のレクで生徒がやること）

```bash
cd /mnt/c/task/class
tmux attach -t claude     # 既存 session なら attach / 無ければ tmux new -s claude
```

中で Claude Code が動いていれば「授業準備」と発言、無ければ `claude` で起動 → 「授業準備」。

### 6.1 離脱 / 復帰

| 操作 | コマンド |
|---|---|
| tmux session から離脱（落とさない） | `Ctrl-b` → `d` |
| 戻る | `tmux attach -t claude` |
| session 一覧 | `tmux ls` |
| 完全終了 | `tmux kill-session -t claude` |

### 6.2 PC 再起動後

PC を再起動すると tmux / syncthing / watcher 全部止まる。再起動後：

```bash
cd /mnt/c/task/class
tmux new -s claude
claude
```

中で「授業準備」と発言。skill が syncthing / watcher を再起動してくれる。

### 6.3 skill 経由の操作

- 「授業準備」or `/class-inbox start` でレク開始準備
- 「クラスメッセージ確認」で新着確認
- 「先生に返信」で返信送信
- 「archive」で自分宛 inbox を local 保存（容量整理）

---

## トラブル時の確認ポイント

- 安全圏か：`pwd` が `/mnt/c/task/class/` 配下か
- tmux 稼働：`tmux ls`
- syncthing 稼働：`ps -ef | grep syncthing | grep -v grep`
- watcher 稼働：`ps -ef | grep student-watch | grep -v grep`
- 同期 folder にファイル：`ls /mnt/c/task/class/inbox/<self>/`
- watcher log：`tail /tmp/class-inbox-watcher.log`
- syncthing log：`tail /tmp/syncthing.log`
