# PID_UI Widget

An EdgeTX 2.12 / Rotorflight 2.2 compatible widget for real-time parameter adjustment and display.

Adjust Rotorflight PID, rates, and transmitter-side parameters in flight using only switch inputs — with live display and automatic saving.

---

## Features

**RF2 Adjustments Mode (SD Forward)**
- Select from 9 parameters using a 3×3 switch grid
- Increment/decrement values via trim switches
- Receives confirmed values via AdjV telemetry and saves automatically
- Displays and manages Ail / Ele / Rud axes individually

**TX Set Mode (SD Middle / SD Back)**
- Throttle head speed (RPM display)
- Collective pitch (degree display)
- Cyclic Expo / Rudder Expo
- Manages values per flight mode (FM0–2)

**Common Features**
- Battery voltage, capacity, RPM, and timer display
- Per-flight-mode bank management (FM0–2)
- Voice readout on parameter change
- Automatic file saving of settings

---

## Requirements

| Item | Version |
|------|---------|
| EdgeTX | 2.12 or later |
| Rotorflight | 2.2 or later |
| Transmitter display | Color LCD (wide landscape layout recommended) |

---

## File Structure

```
WIDGETS/
└── PID_UI/
    ├── main.lua          # Widget main script
    ├── sounds/           # Voice audio files
    │   ├── step1.wav     # TX Set announcement
    │   ├── step2.wav     # M-Rate announcement
    │   ├── step3.wav     # C-Rate announcement
    │   ├── step4.wav     # Expo announcement
    │   ├── step5.wav     # P-Gain announcement
    │   ├── step6.wav     # I-Gain announcement
    │   ├── step7.wav     # D-Gain announcement
    │   ├── step8.wav     # FeedForward announcement
    │   ├── step9.wav     # B-Gain announcement
    │   ├── step10.wav    # Stop-Gain announcement
    │   └── step11.wav    # (unused / adj off)
    └── (save data files: auto-generated on first run)

SCRIPTS/
└── rfadj.lua             # Switch-to-GV conversion script
```

---

## Switch Overview

| Switch | Function |
|--------|----------|
| SD Back | TX Set display (read-only) |
| SD Middle | TX Set mode (adjustable) |
| SD Forward | RF2 Adjustments mode |
| SB × SA | 3×3 grid for parameter selection |
| Ail trim | Ail axis / Cyclic Expo / Head speed |
| Ele trim | Ele axis / Collective pitch |
| Rud trim | Rud axis / Rudder Expo |

See `SETUP.md` and `REFERENCE.md` for full details.

---

## Disclaimer

This widget is a tool to assist with in-flight parameter adjustment. Use at your own risk. The author accepts no responsibility for any damage, malfunction, or accidents caused by parameter changes made using this widget. Always verify parameters on the ground before flying.

---

## Setup Tools

| Tool | Description |
|------|-------------|
| [rfadj Switch Configuration Tool](https://gbb01446-code.github.io/PID-UI/rfadj-editor-en.html) | Change switch assignments and generate rfadj.lua |
| [RF2 CLI adjfunc Generator](https://gbb01446-code.github.io/PID-UI/rfadj-cli-gen-en.html) | Generate Adjustments & Telemetry CLI commands |
