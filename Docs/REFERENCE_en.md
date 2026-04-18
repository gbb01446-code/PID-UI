# PID_UI Reference Guide

---

## 1. Switch Reference

### SD Switch (Mode Selection)

| SD Position | Mode | Description |
|-------------|------|-------------|
| Up (Back) | TX Set (view) | Display transmitter-side parameters (read-only) |
| Mid | TX Set (adjust) | Adjust transmitter-side parameters with trims |
| Down (Fwd) | RF2 Adjustments | Increment/decrement RF2 parameters with trims |

---

### SB × SA Switch Grid (active in RF2 Adjustments mode only)

| | SA Up | SA Mid | SA Down |
|--|-------|--------|---------|
| **SB Up** | ② M-Rate | ③ C-Rate | ④ Expo (FC) |
| **SB Mid** | ⑤ P-Gain | ⑥ I-Gain | ⑦ D-Gain |
| **SB Down** | ⑧ FeedForward | ⑨ B-Gain | ⑩ Stop-Gain |

---

### Trim Switch Functions

**TX Set Mode (SD Mid)**

| Trim | Action | Target |
|------|--------|--------|
| Ail trim | Up / Down | GV1 (Throttle weight) +1 / -1 |
| Ele trim | Up / Down | GV2 (Collective weight) +1 / -1 |
| Rud trim | Up / Down | GV4 (Rudder Expo) +2 / -2 |
| Thr trim | Up / Down | GV3 (Cyclic Expo) +2 / -2 |

**RF2 Adjustments Mode (SD Down)**

| Trim | Action | Target |
|------|--------|--------|
| Ail trim | Up / Down | Step selected parameter on Ail axis |
| Ele trim | Up / Down | Step selected parameter on Ele axis |
| Rud trim | Up / Down | Step selected parameter on Rud axis (TL direction for Stop-Gain) |
| Ail trim (Stop-Gain) | Left / Right | Step Stop-Gain TR direction |

> **Stop-Gain note:** When SB Down · SA Down (⑩) is selected, the Rud axis is fixed. Ail trim maps to TR (right), Rud trim maps to TL (left).

---

## 2. Display Reference

### Left Panel (all modes)

| Display | Content |
|---------|---------|
| Model name | EdgeTX model name |
| T1 | Timer 1 (mm:ss format) |
| RPM | Head speed (Hspd telemetry) |
| V | Battery voltage (shown in red below 3.5V) |
| Bat% | Battery capacity |

---

### Right Panel — TX Set Mode (SD Mid / SD Up)

| Row | Display | Content |
|-----|---------|---------|
| Thr RPM | 0 – MaxRPM | GV1 converted to RPM. FM0–2 shown side by side |
| Coll P. | 0.0 – MaxColl° | GV2 converted to degrees |
| A/E Expo | 0 – 100 | Cyclic Expo (GV3) |
| Rud Expo | 0 – 100 | Rudder Expo (GV4) |

- The active FM column is highlighted
- The row currently being adjusted is highlighted

---

### Right Panel — RF2 Adjustments Mode (SD Down)

**Screen 1 (M-Rate / C-Rate / Expo / Stop-Gain selected)**

| Column | Parameter |
|--------|-----------|
| M-Rt | M-Rate (display = AdjV × 10) |
| C-Rt | C-Rate (display = AdjV × 10) |
| Exp | Expo (FC) |
| T-L | Stop-Gain TL direction |
| T-R | Stop-Gain TR direction |

**Screen 2 (P / I / D / FF / B-Gain selected)**

| Column | Parameter |
|--------|-----------|
| P | P-Gain |
| I | I-Gain |
| D | D-Gain |
| FF | FeedForward |
| B | B-Gain |

- The active axis row (Ail / Ele / Rud) is highlighted
- The selected parameter cell is shown in the active color

---

### Footer (all modes)

| Display | Content |
|---------|---------|
| Bank | Current flight mode (FM0–2) |
| AdjV | Telemetry return value from RF2 (current confirmed value) |

---

## 3. Option Reference

| Option | Type | Default | Range | Description |
|--------|------|---------|-------|-------------|
| BattSrc | SOURCE | none | — | Battery voltage telemetry source |
| ColorPast | COLOR | gray | — | Color for inactive values |
| ColorActive | COLOR | red | — | Color for active values and highlights |
| ColorLabel | COLOR | white | — | Label and text color |
| MaxColl | VALUE | 14 | 10–16 | Max collective pitch angle (degrees). Must match RF2 setting |
| MaxRPM | VALUE | 3000 | 2000–6000 | Max head speed (RPM). Match your helicopter's max head speed |
| VoiceDelay | VALUE | 30 | 0–200 | Wait time before readout starts after input stops (×10ms). Recommended: 40 |
| VoiceGuardTime | VALUE | 200 | 0–300 | Minimum interval between readouts (×10ms). Recommended: 120 |

---

## 4. GV and Channel Reference

| Name | Number | Purpose | Set by | Notes |
|------|--------|---------|--------|-------|
| GV1 | GV1 | Throttle weight | Widget (TX Set) | Used as weight in mixer |
| GV2 | GV2 | Collective weight | Widget (TX Set) | Used as weight in mixer |
| GV3 | GV3 | Cyclic Expo | Widget (TX Set) | Applied via mixer or curve |
| GV4 | GV4 | Rudder Expo | Widget (TX Set) | Applied via mixer or curve |
| GV8 | GV8 | Widget parameter index | rfadj.lua | Not used directly by RF2 |
| GV9 | GV9 | RF2 function ID output (→ CH9) | rfadj.lua | Sent to RF2 via CH9 |
| CH9 | — | GV9 output | rfadj.lua | RF2 Adjustments Value Ch |
| CH10 | — | Ail trim output | EdgeTX | Must be set to 3P |
| CH11 | — | Ele trim output | EdgeTX | Must be set to 3P |
| CH12 | — | Rud trim output | EdgeTX | Must be set to 3P |
| CH13 | — | Throttle trim output | EdgeTX | EdgeTX internal only (not sent to RF2) |

---

## 5. Troubleshooting

### AdjV is always 0

- Check the telemetry connection between RF2 and EdgeTX (ELRS/CRSF required)
- Verify that CH10–12 are correctly assigned as Step Ch in RF2 Configurator's Adjustments tab
- Check that the trims are configured in 3P mode

### Displayed values do not match actual RF2 values

- Values stored in the widget are received via AdjV telemetry
- Values changed directly in Rotorflight Configurator are not reflected automatically
- Move a trim once to trigger RF2 to return the actual value via AdjV and sync

### No voice readout

- Check that step1.wav–step10.wav exist in `/WIDGETS/PID_UI/sounds/`
- Check the VoiceDelay and VoiceGuardTime option values
- Confirm that system sounds are enabled in EdgeTX

### Values are not being saved

- Wait a moment after the last trim operation before powering off (AdjV should return to 0 within a few seconds)
- Check available space on the SD card

### Trim input has no effect in TX Set mode

- Confirm the SD switch is in the middle position (TX Set mode)
- Check that the trims are configured in 3P mode
- Verify that rfadj.lua is correctly registered and running in Special Functions
