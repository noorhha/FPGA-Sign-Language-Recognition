# FPGA-Based Finger-Spelling Recognition System

**VHDL | DE2-115 FPGA | Flex Sensors | Finite-State Machine (FSM) | 16×2 LCD**

A Computer Engineering project that reads five digital finger-bend inputs, maps selected 5-bit patterns to alphabet characters, and displays the current character and an accumulated message on the DE2-115 board's LCD. Two push buttons allow the user to save a character or clear the message.

> **Implementation note:** The included VHDL demonstrates **pattern-to-character decoding**; it is not a trained machine-learning model. The lookup table assigns 26 patterns to A–Z, but it does not by itself establish recognition accuracy for standard sign-language gestures.

## Features

- Five-bit sensor input (`flex[4:0]`) representing finger positions.
- Combinational lookup from 26 binary patterns to letters **A–Z**.
- Continuous display of the current character and its five-bit input pattern.
- A 16-character message buffer shown on the LCD's second line.
- **KEY0:** append the currently decoded character; **KEY1:** clear the saved message.
- Five LEDs mirror the current sensor-bit states for debugging.
- A VHDL FSM sequences LCD command/data writes and enable timing.

## Hardware

| Component | Purpose |
| --- | --- |
| Altera/Terasic DE2-115 (Cyclone IV) | Executes the VHDL design using the 50 MHz board clock |
| Five flex sensors | Sense finger bending (one per finger) |
| Voltage-divider and comparator interface | Converts analog sensor voltages into five digital inputs |
| On-board 16×2 HD44780-compatible LCD | Displays the current letter, input pattern, and saved message |
| KEY0, KEY1 | Save a letter and clear the message |
| LEDR[4:0] | Display input logic levels |

**Note:** The hardware report describes a **comparator-based digital interface**. The VHDL accepts digital input bits and contains no ADS1115 or I²C interface.

## How it works

```text
Five flex sensors
      │ analog voltages
      ▼
Voltage dividers + comparators
      │ 5 digital bits
      ▼
DE2-115 FPGA ───────► LEDR[4:0] (input monitoring)
      │
      ├──► Pattern-to-letter lookup (A–Z)
      │
      ├──► KEY0: save letter / KEY1: clear message
      │
      └──► LCD write FSM ──► 16×2 LCD
                            Line 1: CUR: <letter> <5-bit pattern>
                            Line 2: saved characters
```

The `letter_char` function maps `00000` through `11001` to **A** through **Z**, respectively; other patterns return `?`. For example:

| Digital input | Decoded character |
| --- | --- |
| `00000` | A |
| `00001` | B |
| `00010` | C |
| `11001` | Z |
| Other patterns | `?` |

These are **code lookup assignments**, not a verified mapping of all physical hand gestures.

## LCD finite-state machine

The implemented LCD-control FSM in `test.vhd` has six states:

1. **`POWER_WAIT`** — wait after power-on before issuing LCD commands.
2. **`LOAD_STEP`** — load an initialization command or display byte.
3. **`EN_HIGH`** — assert LCD enable for the configured interval.
4. **`EN_LOW`** — deassert LCD enable.
5. **`WAIT_STEP`** — insert a delay between transfers.
6. **`NEXT_STEP`** — advance to the next LCD command/data position and repeat.

The sequence initializes the LCD (`0x38`, `0x0C`, `0x01`, `0x06`), writes the first and second lines, and then refreshes display content. A separate clocked section detects falling edges on the active-low keys and delays subsequent key actions.

The *system-level* FSM in [`FSM_HardwareDescription.pdf`](FSM_HardwareDescription.pdf) illustrates the broader sensing, decoding, save/clear, and display workflow; the six states above describe the **actual LCD-control implementation**.

## Source code and documentation

| File | Description |
| --- | --- |
| [`test.vhd`](test.vhd) | VHDL source; top-level entity is `test` |
| [`FSM_HardwareDescription.pdf`](FSM_HardwareDescription.pdf) | System-level FSM diagram, hardware photographs, and module descriptions |

### Suggested project images

The PDF report contains a system-level FSM diagram, the comparator/breadboard interface, and a photograph of the DE2-115 with the sensor glove. If you export these images into an `images/` directory, you can embed them here:

```markdown
![System-level FSM](images/fsm_diagram.png)
![Hardware prototype](images/hardware_setup.jpg)
```

## Running the design on the DE2-115

1. Open **Intel/Altera Quartus** and create a project targeting the FPGA on your DE2-115 board.
2. Add `test.vhd` and set **`test`** as the top-level entity.
3. Assign `CLOCK_50`, `flex[4:0]`, `KEY[1:0]`, `LEDR[4:0]`, and the LCD signals to the correct physical pins according to the **DE2-115 manual** and your wiring. **A pin-assignment file is not included** in this repository.
4. Connect the five **digital comparator outputs** to the FPGA's chosen input pins. Use FPGA-compatible voltage levels and a common ground.
5. Compile and program the board, then observe the live character and sensor pattern on LCD line 1.
6. Press **KEY0** to save the displayed character; press **KEY1** to clear the saved message.

**Reproducibility limits:** The repository contains the VHDL and hardware description, but no Quartus project, pin assignments, or automated testbench. Additional board-specific setup is required. The code has not been independently recompiled or hardware-tested as part of preparing this README.

## Potential improvements

- Calibrate and document the correspondence between real hand gestures and 5-bit sensor patterns.
- Add an automated VHDL testbench and waveform screenshots.
- Include Quartus project files and verified `.qsf` pin assignments.
- Improve input synchronization, switch debouncing, and handling of a full message buffer.
- Compare gesture recognition behavior across users and report measured accuracy.

## Project context

Developed as part of **Advanced Digital Systems Design (CEN466 / EEN466)**. This repository is intended to document the FPGA logic, sensor interface, and hardware integration.
