# claude-class-inbox

授業で **先生から生徒の Claude Code セッションへ remote で指示を届ける** ための setup パッケージ。Syncthing（推奨）or Google Drive で `~/claude-class-inbox/` を端末間同期し、tmux + watcher で Claude Code pane に自動投入。

---

## 🚀 生徒：始め方（1 行）

自分の Claude Code に以下を伝えてください：

> `https://github.com/tenchan000517/claude-class-inbox` をクローンして、SETUP.md を読んでセットアップしてください。

これで以下が自動で完了します：

- tmux + Syncthing（or Drive）インストール確認
- 必要情報（student-id・tmux session 名・同期フォルダ path）の確認
- `.env` 書き出し
- `~/.claude/skills/class-inbox/` への skill 登録
- watcher の background 起動
- 日常運用フローの案内（attach / detach / 再起動）

setup 完了後は、Claude Code 内で `/class-inbox` や「クラスメッセージ確認」と発言すれば skill が起動して inbox を確認・操作できます。

---

## 🧑‍🏫 先生：事前準備

### Option A: Syncthing（推奨）

P2P 同期。中央サーバ不要・Google アカウント不要・LAN なら高速・cross-network も OK・完全 open source。授業の教材価値も高い。

#### 1. Syncthing のインストール

| OS | 方法 |
|---|---|
| Ubuntu / WSL | `sudo apt install syncthing` |
| Mac | `brew install syncthing` |
| Windows | https://syncthing.net/downloads/ から SyncTrayzor |

#### 2. Syncthing 起動 + 自分の Device ID 確認

```bash
syncthing
```

Web UI（http://localhost:8384）が開く。右上「Actions」→「Show ID」で自分の Device ID を確認（`XXXX-XXXX-...` 形式）。

#### 3. ローカル folder 作成 + Syncthing に登録

```bash
mkdir -p ~/claude-class-inbox/inbox/{all,teacher,student-kawai,student-kawasaki}
```

Web UI で「Add Folder」：
- Folder Path: `~/claude-class-inbox`（or 同期したい path）
- Folder ID: 任意（例: `class-inbox-2026`）

#### 4. 生徒 Device の追加 + folder 共有

生徒から Device ID をもらったら、Web UI「Add Remote Device」で追加。share 対象 folder にチェック。

#### 5. メッセージ送信

```bash
git clone https://github.com/tenchan000517/claude-class-inbox.git
cd claude-class-inbox
bash teacher/send.sh kawai today-task body.md
echo "今日の課題: ..." | bash teacher/send.sh all today-task -
```

数秒で生徒 PC に同期される。

---

### Option B: Google Drive（フォールバック）

Syncthing が動かない環境（企業 / 学校ネットワークで Syncthing ポート遮断等）向け。

1. Drive for desktop インストール（https://www.google.com/drive/download/）
2. ストリーム モードで OK（実 disk 使用は metadata のみ）
3. My Drive 直下に `claude-class-inbox/inbox/{all,teacher,student-<id>}/` を作成
4. 各生徒 Google アカウントに `claude-class-inbox/` を編集者権限で共有招待

---

### クラウドクリーンアップ（節目で実施）

```bash
bash teacher/cleanup.sh --dry-run --target all     # 事前確認
bash teacher/cleanup.sh --target all               # 全員宛をクリーン
bash teacher/cleanup.sh --target everything        # 学期末・全クリーン
```

---

## アーキテクチャ

```
先生 PC                   同期層                       生徒 PC
                         (Syncthing / Drive)
 teacher/send.sh ---> ~/claude-class-inbox/inbox/kawai/ ---> watcher
                  \                                    \
                   --> ~/claude-class-inbox/inbox/all/  --> tmux send-keys
                                                         --> Claude Code pane
```

詳細は [SETUP.md](./SETUP.md) を参照。

---

## ディレクトリ構造

```
claude-class-inbox/
├── README.md            # 本ファイル
├── CLAUDE.md            # Claude Code 自動 load 用 orientation
├── SETUP.md             # 初期セットアップ手順（Claude が follow する）
├── scripts/             # 生徒側ツール
│   ├── student-watch.sh   # 常駐 watcher
│   ├── archive.sh         # 自分宛 inbox の local archive
│   ├── install-skill.sh   # skill 登録
│   └── skill-template.md  # skill SKILL.md テンプレ
├── teacher/             # 先生専用ツール（生徒は実行しない）
│   ├── send.sh            # メッセージ送信
│   ├── cleanup.sh         # クラウドクリーンアップ（破壊的）
│   └── README.md
└── inbox/               # サンプル inbox 構造（.gitkeep のみ）
    ├── all/
    ├── student-alice/
    └── student-bob/
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
| 先生宛 inbox をクリーン | ✕ | ◯ |
| 学期末の全クリーン | ✕ | ◯ |

---

## 更新時

```bash
cd <package-path>
git pull
bash scripts/install-skill.sh    # skill を再生成
```

---

## ライセンス

MIT
