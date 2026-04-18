# PID_UI Setup Guide

---

## 1. Requirements

- Transmitter running EdgeTX 2.12 or later (color LCD)
- Flight controller running Rotorflight 2.2 or later
- Three 3-position switches (SD / SB / SA)
- step1.wav–step10.wav audio files (optional but recommended)

---

## 2. Installing Files

### 2-1. Widget Files

Copy the following files to your transmitter's SD card:

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

### 2-2. Script File

```
SCRIPTS/
└── rfadj.lua
```

---

## 3. EdgeTX Configuration

### 3-1. Global Variables (GV)

This widget uses the following GVs. Check that they do not conflict with your existing model configuration.

| GV | Purpose | Set by |
|----|---------|--------|
| GV1 | Throttle weight (head speed) | TX Set operation |
| GV2 | Collective weight (max pitch) | TX Set operation |
| GV3 | Cyclic Expo | TX Set operation |
| GV4 | Rudder Expo | TX Set operation |
| GV8 | Widget parameter index | rfadj.lua |
| GV9 | RF2 function ID output (→ CH9) | rfadj.lua |

### 3-2. Channel Assignment

Configure the following channels in your model:

| Channel | Content | Destination |
|---------|---------|-------------|
| CH9 | GV9 output | RF2 Adjustments Value Ch |
| CH10 | Ail trim analog output | RF2 Adjustments Step Ch (Ail) |
| CH11 | Ele trim analog output | RF2 Adjustments Step Ch (Ele) |
| CH12 | Rud trim analog output | RF2 Adjustments Step Ch (Rud) |
| CH13 | Throttle trim analog output | EdgeTX internal only (not sent to RF2) |

> **Note:** Set CH10–12 trims to 3-position (3P) mode.

### 3-3. Mixer Setup

Use GV1–4 as weights in the EdgeTX mixer:

| GV | Mixer target | Notes |
|----|-------------|-------|
| GV1 | Throttle channel weight | Head speed control |
| GV2 | Collective channel weight | Max pitch control |
| GV3 | Cyclic (Ail/Ele) Expo | Apply via mixer or curve |
| GV4 | Rudder Expo | Apply via mixer or curve |

### 3-4. Special Functions

Register `rfadj.lua` as a script that runs continuously via Special Functions:

```
SF: [Switch: Always ON] → [Script: rfadj] → [Enabled]
```

### 3-5. Adding the Widget

1. Enter widget edit mode and add `PID_UI` to an available slot
2. Long-press the widget to open settings and configure the options below:

| Option | Description | Recommended |
|--------|-------------|-------------|
| BattSrc | Battery voltage telemetry source | Select your sensor |
| ColorPast | Color for inactive values | Gray |
| ColorActive | Color for active/highlighted values | Red or bright color |
| ColorLabel | Label text color | White |
| MaxColl | Max collective pitch angle (degrees) | Match your RF2 setting |
| MaxRPM | Max head speed (RPM) | Match your helicopter spec |
| VoiceDelay | Delay before readout starts (×10ms) | 40 (400ms) |
| VoiceGuardTime | Minimum interval between readouts (×10ms) | 120 (1200ms) |

---

## 4. Rotorflight Configuration

### 4-1. Adjustments Setup

In RF2 Configurator's Adjustments tab, assign each function using CH9's value range (-80 to +80) as the identifier. Each function should occupy a non-overlapping range.

| Parameter | CH9 Range | SB/SA Position |
|-----------|-----------|----------------|
| M-Rate    | around -80 | SB Back · SA Back |
| C-Rate    | around -60 | SB Back · SA Mid |
| Expo (FC) | around -40 | SB Back · SA Fwd |
| P-Gain    | around -20 | SB Mid · SA Back |
| I-Gain    | around   0 | SB Mid · SA Mid |
| D-Gain    | around +20 | SB Mid · SA Fwd |
| FeedForward | around +40 | SB Fwd · SA Back |
| B-Gain    | around +60 | SB Fwd · SA Mid |
| Stop-Gain | around +80 | SB Fwd · SA Fwd |

- **Index Ch**: Channel outputting GV8 (or GV8 directly)
- **Value Ch (Range)**: CH9
- **Step Ch**: CH10–12 (per Ail/Ele/Rud axis)
- **Step type**: Stepped

### 4-2. Telemetry

Confirm that the AdjV (Adjustment Value) telemetry is being received on your transmitter. When RF2 and EdgeTX are connected via ELRS or CRSF, this is available automatically.

---

## 5. Verification

1. Set SD switch to middle (TX Set mode)
2. Confirm Thr RPM / Coll P. / Expo values are displayed on the widget
3. Move Ail trim up/down and confirm Thr RPM changes
4. Set SD switch forward (RF2 Adjustments mode)
5. Select a parameter with SB/SA and confirm values change with trim input
6. Confirm AdjV value appears in the bottom-right of the widget

---

## 6. Data Saving

- Parameter values are saved automatically when AdjV returns to 0
- Saving is not dependent on when you power off the transmitter
- Save files are generated automatically under `/WIDGETS/PID_UI/` using the model name and FM name
- Values changed directly in Rotorflight Configurator will not be reflected in the widget (AdjV is only sent on trim operation)
