# PID_UI セットアップガイド

---

## 1. 必要なもの

- EdgeTX 2.12以上を搭載した送信機（カラー液晶）
- Rotorflight 2.2以上を搭載したフライトコントローラー
- 3段スイッチ × 3個（SD / SB / SA）
- step1.wav〜step10.wav の音声ファイル（任意、あると便利）

---

## 2. ファイルのインストール

### 2-1. Widgetファイルの配置

送信機のSDカードに以下の構成でファイルをコピーしてください。

```
WIDGETS/
└── PID_UI/
    ├── main.lua
    └── sounds/
        ├── step1.wav
        ├── step2.wav
        ├── step3.wav
        ├── step4.wav
        ├── step5.wav
        ├── step6.wav
        ├── step7.wav
        ├── step8.wav
        ├── step9.wav
        └── step10.wav
```

### 2-2. スクリプトファイルの配置

```
SCRIPTS/
└── rfadj.lua
```

---

## 3. EdgeTX の設定

### 3-1. グローバル変数（GV）の確認

本Widgetは以下のGVを使用します。モデルのGV設定と競合しないよう確認してください。

| GV | 用途 | 設定者 |
|----|------|--------|
| GV1 | スロットルウェイト（回転数） | TX Set操作で更新 |
| GV2 | コレクティブウェイト（最大ピッチ） | TX Set操作で更新 |
| GV3 | サイクリックExpo | TX Set操作で更新 |
| GV4 | ラダーExpo | TX Set操作で更新 |
| GV8 | Widget用パラメータインデックス | rfadj.luaが設定 |
| GV9 | RF2機能識別用出力（CH9へ） | rfadj.luaが設定 |

### 3-2. チャンネルの設定

以下のチャンネルを設定してください。

| チャンネル | 内容 | 送信先 |
|-----------|------|--------|
| CH9 | GV9の出力 | RF2 Adjustments Value Ch |
| CH10 | Ailトリムのアナログ出力 | RF2 Adjustments Step Ch（Ail軸） |
| CH11 | Eleトリムのアナログ出力 | RF2 Adjustments Step Ch（Ele軸） |
| CH12 | Rudトリムのアナログ出力 | RF2 Adjustments Step Ch（Rud軸） |
| CH13 | スロットル用トリムのアナログ出力 | EdgeTX内部のみ（RF2不使用） |

> **注意:** CH10〜12のトリムは3ポジション（3P）設定にしてください。

### 3-3. ミキサーの設定

GV1〜4をEdgeTXミキサーのウェイトとして使用します。

| GV | ミキサー適用先 | 備考 |
|----|--------------|------|
| GV1 | スロットルチャンネルのウェイト | 回転数調整 |
| GV2 | コレクティブチャンネルのウェイト | 最大ピッチ調整 |
| GV3 | サイクリック（Ail/Ele）のExpo | ミキサーまたはカーブで適用 |
| GV4 | ラダーのExpo | ミキサーまたはカーブで適用 |

### 3-4. スペシャルファンクションの設定

`rfadj.lua` をスクリプトとして常時実行するようにスペシャルファンクションに登録してください。

```
SF: [スイッチ: 常時ON] → [スクリプト: rfadj] → [有効]
```

### 3-5. Widgetの追加

1. ウィジェット画面の編集モードで空きスペースに `PID_UI` を追加
2. Widgetを長押しして設定画面を開き、以下のオプションを設定

| オプション | 内容 | 推奨値 |
|-----------|------|--------|
| BattSrc | バッテリー電圧のテレメトリーソース | 使用するセンサーを選択 |
| ColorPast | 非アクティブ値の表示色 | グレー系 |
| ColorActive | アクティブ値・ハイライト色 | 赤など目立つ色 |
| ColorLabel | ラベル文字色 | 白 |
| MaxColl | コレクティブピッチ最大角度（度） | RF2側の設定値に合わせる |
| MaxRPM | スロットル最大回転数（RPM） | ヘリの最大ヘッドスピードに合わせる |
| VoiceDelay | 読み上げ開始までの待機時間（×10ms） | 40（400ms）推奨 |
| VoiceGuardTime | 読み上げ間の最低インターバル（×10ms） | 120（1200ms）推奨 |

---

## 4. Rotorflight の設定

### 4-1. Adjustments の設定

RF2 ConfiguratorのAdjustmentsタブで、以下のように各機能を設定してください。

CH9の値（-80〜+80）で機能を識別します。各機能に重複しない範囲を割り当てます。

| パラメータ | CH9範囲 | SB/SA位置 |
|-----------|---------|----------|
| M-Rate    | -80付近 | SB奥・SA奥 |
| C-Rate    | -60付近 | SB奥・SA中 |
| Expo (FC) | -40付近 | SB奥・SA手前 |
| P-Gain    | -20付近 | SB中・SA奥 |
| I-Gain    |   0付近 | SB中・SA中 |
| D-Gain    | +20付近 | SB中・SA手前 |
| FeedForward | +40付近 | SB手前・SA奥 |
| B-Gain    | +60付近 | SB手前・SA中 |
| Stop-Gain | +80付近 | SB手前・SA手前 |

- **Index Ch**: GV8を出力するチャンネル（または直接GV8）
- **Value Ch（Range）**: CH9
- **Step Ch**: CH10〜12（Ail/Ele/Rud各軸）
- **Step type**: Stepped

### 4-2. テレメトリーの設定

AdjV（Adjustment Value）テレメトリーが送信機で受信できることを確認してください。RF2とEdgeTXがElRSまたはCRSFで接続されている場合は自動的に利用可能です。

---

## 5. 動作確認

1. SDスイッチを中（TX Setモード）にする
2. Widget上にThr RPM / Coll P. / Expo が表示されることを確認
3. Ailトリムを上下に動かしてThr RPMの値が変化することを確認
4. SDスイッチを手前（RF2 Adjustmentsモード）にする
5. SB/SAスイッチでパラメータを選択し、トリムで値が変化することを確認
6. AdjV欄（画面右下）に値が表示されることを確認

---

## 6. データの保存について

- パラメータ値はAdjVが0に戻った時点で自動保存されます
- 電源OFFのタイミングに依存しません
- 保存ファイルは `/WIDGETS/PID_UI/` 以下にモデル名とFM名で自動生成されます
- Rotorflight Configuratorで直接変更した値はWidgetには反映されません（AdjVは操作時のみ送信されるため）
