# PID_UI Widget

EdgeTX 2.12 / Rotorflight 2.2 対応のパラメータ調整・表示Widgetです。  
An EdgeTX 2.12 / Rotorflight 2.2 compatible widget for real-time parameter adjustment and display.

---

## ドキュメント / Documentation

| | 日本語 | English |
|--|--------|---------|
| 概要 / Overview | [README_ja.md](docs/README_ja.md) | [README_en.md](docs/README_en.md) |
| セットアップ / Setup | [SETUP_ja.md](docs/SETUP_ja.md) | [SETUP_en.md](docs/SETUP_en.md) |
| リファレンス / Reference | [REFERENCE_ja.md](docs/REFERENCE_ja.md) | [REFERENCE_en.md](docs/REFERENCE_en.md) |

---

## セットアップツール / Setup Tools

| ツール / Tool | 日本語 | English |
|---|---|---|
| rfadj スイッチ設定 | [rfadj-editor.html](https://gbb01446-code.github.io/PID-UI/rfadj-editor.html) | [rfadj-editor-en.html](https://gbb01446-code.github.io/PID-UI/rfadj-editor-en.html) |
| RF2 CLI adjfunc 生成 | [rfadj-cli-gen.html](https://gbb01446-code.github.io/PID-UI/rfadj-cli-gen.html) | [rfadj-cli-gen-en.html](https://gbb01446-code.github.io/PID-UI/rfadj-cli-gen-en.html) |

---

## ファイル構成 / File Structure

```
PID-UI/
├── README.md
├── Pid_ui_model.yml              # EdgeTX model template
├── Pid_ui_CLI.txt                # Rotorflight CLI commands
├── docs/
│   ├── README_ja.md
│   ├── README_en.md
│   ├── SETUP_ja.md
│   ├── SETUP_en.md
│   ├── REFERENCE_ja.md
│   └── REFERENCE_en.md
├── WIDGETS/
│   └── PID_UI/
│       ├── main.lua              # Widget main script
│       └── sounds/               # Voice audio files (step1.wav–step10.wav)
└── SCRIPTS/
    └── rfadj.lua                 # Switch-to-GV conversion script
```
