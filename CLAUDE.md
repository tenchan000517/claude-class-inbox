# claude-class-inbox package

このディレクトリは「先生から生徒の Claude Code へ remote で指示を届ける」ための **生徒側 setup package** です。

## 起動時の動き

Claude Code がこのディレクトリの path を読んだら、以下を実施してください：

1. `SETUP.md` を読む — setup 手順が書いてある
2. 生徒（ユーザー）に必要な情報を確認する（student-id / tmux session 名 / 同期フォルダ path）
3. 環境を構築する（tmux 確認 / 同期フォルダ確認 / watcher 起動）
4. `scripts/install-skill.sh` を実行して `~/.claude/skills/class-inbox/` に skill を登録
5. setup 完了報告 + 以降の運用方法（`/class-inbox` 等）を生徒に伝える

## ディレクトリ構造

```
claude-class-inbox/
├── CLAUDE.md            # 本ファイル（自動 load 用 orientation）
├── SETUP.md             # setup 手順（Claude が follow する）
├── README.md            # human 向けドキュメント
├── inbox/               # 各 inbox（クラウド同期フォルダにマップされる）
│   ├── all/             # 全員向け
│   └── student-<id>/    # 個人向け
└── scripts/
    ├── student-watch.sh    # 常駐 watcher（新着 → tmux 投入）
    ├── teacher-send.sh     # 先生用送信（生徒側では使わない）
    ├── install-skill.sh    # skill 登録
    └── skill-template.md   # skill SKILL.md テンプレ
```

## 注意

- このディレクトリは生徒の workspace ではなく **環境構築の package**。setup 後は基本触らない
- 生徒の Claude Code は別のディレクトリ（自分のコード）で動かす
- 本 package と Claude Code の workspace は分離して OK
