# claude-class-inbox

授業で **先生から生徒の Claude Code セッションへ remote で指示を届ける** ための setup パッケージ。クラウド同期フォルダ + tmux + watcher の組み合わせで動く。

---

## 🚀 生徒：始め方（1 行）

自分の Claude Code に以下を伝えてください：

> `https://github.com/tenchan000517/claude-class-inbox` をクローンして、SETUP.md を読んでセットアップしてください。

これで以下が自動で完了します：

- tmux インストール確認
- 必要情報（student-id・tmux session 名・同期フォルダ path）の確認
- `.env` 書き出し
- `~/.claude/skills/class-inbox/` への skill 登録
- watcher の background 起動
- 日常運用フローの案内（attach / detach / 再起動）

setup 完了後は、Claude Code 内で `/class-inbox` や「クラスメッセージ確認」と発言すれば skill が起動して inbox を確認・操作できます。

---

## 🧑‍🏫 先生：事前準備

1. **このリポジトリのクローン**：

   ```bash
   git clone https://github.com/tenchan000517/claude-class-inbox.git
   cd claude-class-inbox
   ```

2. **クラウド同期サービスの選定** — 推奨：Google Drive（15GB 無料・招待 UI 完結）

3. **共有フォルダ作成**：

   ```
   ~/claude-class-inbox/
   ├── inbox/
   │   ├── all/                # 全員へのブロードキャスト
   │   ├── teacher/            # 生徒 → 先生の返信受信箱
   │   ├── student-alice/      # alice 個人宛
   │   └── student-bob/        # bob 個人宛
   ```

   各生徒に **編集者** 権限で共有招待。生徒は自分の `~/claude-class-inbox/` として同期するよう設定。

4. **メッセージ送信**（先生 PC で）：

   ```bash
   bash teacher/send.sh alice today-task body.md
   echo "今日の課題: ..." | bash teacher/send.sh all today-task -
   ```

5. **クラウドクリーンアップ**（節目で実施）：

   ```bash
   bash teacher/cleanup.sh --dry-run --target all     # 事前確認
   bash teacher/cleanup.sh --target all               # 全員宛をクリーン
   bash teacher/cleanup.sh --target everything        # 学期末・全クリーン
   ```

---

## アーキテクチャ

```
先生 PC                   クラウド同期                生徒 PC
                         (Drive/Dropbox/Syncthing)
 teacher/send.sh ---> ~/claude-class-inbox/inbox/alice/ ---> watcher
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
| 自分宛 inbox をクラウド削除 | ◯ | - |
| 全員宛 inbox を local copy | ◯（read-only） | ◯ |
| 全員宛 inbox をクラウド削除 | ✕ | ◯ |
| 他生徒 inbox をクラウド削除 | ✕ | ◯ |
| 先生宛 inbox をクラウド削除 | ✕ | ◯ |
| 学期末の全クリーン | ✕ | ◯ |

---

## 更新時

パッケージが更新された時は、生徒側で：

```bash
cd <package-path>
git pull
bash scripts/install-skill.sh    # skill を再生成（template に変更があった時）
```

---

## ライセンス

MIT
