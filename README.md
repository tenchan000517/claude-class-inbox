# claude-class-inbox

授業で **先生から生徒の Claude Code セッションへ remote で指示を届ける** ための setup パッケージ。Syncthing（推奨）or Google Drive で `inbox/` を端末間同期し、tmux + watcher で Claude Code pane に自動投入。

---

## ⚠️ 安全設計（最重要）

Claude Code の auto mode は **cwd 内では制限なく操作する**。`~` や `C:\` を cwd にして起動すると、誤判断時に **Windows ドキュメントごと消える** リスクあり。

**本パッケージは `/mnt/c/task/class/` 配下に固定** することで auto mode の blast radius を /mnt/c/task/class/ 以下に閉じる。

```
/mnt/c/task/class/                  ← cwd（auto mode の安全圏）
├── claude-class-inbox/             ← clone した package（scripts / SETUP / .env）
└── inbox/                          ← syncthing 同期 folder（メッセージ実体）
    ├── all/ / teacher/ / student-<id>/
```

clone 先 / sync folder / cwd すべて `/mnt/c/task/class/` 配下。**この path を逸脱した場合、skill は動作を拒否します**。

---

## 🚀 生徒：始め方（1 行）

自分の Claude Code に以下を伝えてください：

> `https://github.com/tenchan000517/claude-class-inbox` を `/mnt/c/task/class/claude-class-inbox/` にクローンして、SETUP.md を読んでセットアップしてください。

これで以下が自動で完了します：

- `/mnt/c/task/class/` の作成（必要に応じて）
- tmux + Syncthing インストール確認
- 必要情報（student-id・tmux session 名）の確認
- `.env` 書き出し
- `~/.claude/skills/class-inbox/` への skill 登録（cwd 安全圏チェック付き）
- watcher の background 起動
- 日常運用フローの案内（attach / detach / 再起動）

setup 完了後、毎回のレクで生徒が必要なのは：

1. VS Code → **WSL Ubuntu ターミナル** を開く（cmd / PowerShell ではない）
2. `cd /mnt/c/task/class/`
3. `tmux new -s claude` → `claude`
4. Claude Code 内で「**授業準備**」or `/class-inbox start`
5. skill が syncthing 起動 + watcher 起動 + 新着メッセージ表示 まで自動

---

## 🧑‍🏫 先生：事前準備

### Option A: Syncthing（推奨）

P2P 同期・中央サーバ不要・cross-network OK・教材価値高い。

#### 1. install

| OS | コマンド |
|---|---|
| Ubuntu / WSL | `sudo apt install syncthing` |
| Mac | `brew install syncthing` |
| Windows native | https://github.com/canton7/SyncTrayzor/releases |

#### 2. 起動 + Device ID 取得

```bash
nohup syncthing serve --no-browser > /tmp/syncthing.log 2>&1 &
syncthing cli show system | grep myID
```

Web UI: http://localhost:8384

#### 3. folder 構造の作成 + Syncthing 登録

```bash
mkdir -p /mnt/c/task/class/inbox/{all,teacher,student-kawai,student-kawasaki}
```

Web UI「フォルダーを追加」：
- Folder Label: `class-inbox`
- Folder ID: `class-inbox-2026`
- Folder Path: `/mnt/c/task/class/inbox`

#### 4. package を clone

```bash
git clone https://github.com/tenchan000517/claude-class-inbox.git /mnt/c/task/class/claude-class-inbox
```

#### 5. 生徒の Device 追加 + folder 共有

生徒から Device ID をもらったら、Web UI「接続先デバイスを追加」で追加。share 対象 folder にチェック。

#### 6. メッセージ送信

```bash
cd /mnt/c/task/class/claude-class-inbox
bash teacher/send.sh kawai today-task body.md
echo "今日の課題: ..." | bash teacher/send.sh all today-task -
```

### Option B: Google Drive（フォールバック）

Syncthing が動かない環境向け。同期 folder 先は `/mnt/c/task/class/inbox/` で固定。

---

### クラウドクリーンアップ（節目で実施）

```bash
cd /mnt/c/task/class/claude-class-inbox
bash teacher/cleanup.sh --dry-run --target all
bash teacher/cleanup.sh --target all
bash teacher/cleanup.sh --target everything    # 学期末・全クリーン
```

---

## アーキテクチャ

```
先生 PC                       同期層                       生徒 PC
                            (Syncthing / Drive)
 teacher/send.sh ---> /mnt/c/task/class/inbox/kawai/ ---> watcher
                  \                                  \
                   --> /mnt/c/task/class/inbox/all/   --> tmux send-keys
                                                      --> Claude Code pane
```

詳細は [SETUP.md](./SETUP.md) を参照。

---

## ディレクトリ構造

```
/mnt/c/task/class/claude-class-inbox/        # cloned git repo
├── README.md                                # 本ファイル
├── CLAUDE.md                                # Claude Code 自動 load 用 orientation
├── SETUP.md                                 # 初期セットアップ手順
├── scripts/                                 # 生徒側ツール
│   ├── student-watch.sh
│   ├── archive.sh
│   ├── install-skill.sh
│   └── skill-template.md
├── teacher/                                 # 先生専用ツール
│   ├── send.sh
│   ├── cleanup.sh
│   └── README.md
└── inbox/                                   # サンプル（実際は ../inbox/ を使う）
```

---

## 役割分担

| 操作 | 生徒 | 先生 |
|---|---|---|
| 自分宛 inbox を local download | ◯ | - |
| 自分宛 inbox をクリーン | ◯ | - |
| 全員宛 inbox を local copy | ◯（read-only） | ◯ |
| 全員宛 inbox をクリーン | ✕ | ◯ |
| 他生徒 inbox をクリーン | ✕ | ◯ |
| 学期末の全クリーン | ✕ | ◯ |

---

## 更新時

```bash
cd /mnt/c/task/class/claude-class-inbox
git pull
bash scripts/install-skill.sh
```

---

## ライセンス

MIT
