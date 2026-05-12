# claude-class-inbox package

このディレクトリは「先生から生徒の Claude Code へ remote で指示を届ける」ための **生徒側 setup package** です。

---

## ⚠️ 安全設計（最初に意識すること）

Claude Code の auto mode は cwd 内では制限なく操作する。**clone 先・cwd・同期 folder すべて `/mnt/c/task/class/` 配下に固定**することで、誤判断時の blast radius を限定する。

clone 先：`/mnt/c/task/class/claude-class-inbox/`
同期 folder：`/mnt/c/task/class/inbox/`
tmux + claude の cwd：`/mnt/c/task/class/`

これを逸脱した場所で動作している場合は、SETUP.md Step 0 で動作を中断して生徒に安全圏への移動を促してください。

---

## 起動時の動き

Claude Code がこのディレクトリの path を読んだら、以下を実施してください：

1. **Step 0 安全圏チェック**：`pwd` を確認、`/mnt/c/task/class/` 配下でなければ中断 + 移動指示
2. `SETUP.md` を読む — setup 手順が書いてある
3. 生徒に必要情報を確認する（student-id / tmux session 名）
4. 環境を構築する（tmux 確認 / syncthing 確認 + Device ID 取得 / 先生からの folder 共有受領）
5. `.env` 書き出し → `scripts/install-skill.sh` 実行 → `~/.claude/skills/class-inbox/` に skill を登録
6. watcher の background 起動
7. 日常運用フローを生徒に伝える（毎回のレクで必要な 5 ステップ：terminal を WSL Ubuntu で開く / `cd /mnt/c/task/class/` / `tmux new -s claude` / `claude` / 「授業準備」と発言）

## ディレクトリ構造

```
/mnt/c/task/class/                       # cwd（安全圏）
├── claude-class-inbox/                  # 本 package（cloned）
│   ├── CLAUDE.md                        # 本ファイル（自動 load 用 orientation）
│   ├── SETUP.md                         # setup 手順
│   ├── README.md                        # human 向けドキュメント
│   ├── scripts/
│   │   ├── student-watch.sh             # 常駐 watcher
│   │   ├── archive.sh                   # 自分宛 inbox の local archive
│   │   ├── install-skill.sh             # skill 登録
│   │   └── skill-template.md            # skill SKILL.md テンプレ
│   └── teacher/                         # 先生専用ツール（生徒は実行しない）
└── inbox/                               # syncthing 同期 folder（メッセージ実体）
    ├── all/
    ├── teacher/
    └── student-<id>/
```

## 注意

- このディレクトリ（claude-class-inbox/）は生徒の workspace ではなく **環境構築の package**。setup 後は基本触らない
- 生徒の Claude Code は `cd /mnt/c/task/class/`（parent）で動かす
- inbox/ 配下のメッセージは syncthing で全自動同期される（手動 commit 不要）
