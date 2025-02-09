# RogueReader - Trainer for Project Rogue

## Description

**RogueReader** is a trainer designed to enhance the gameplay experience in *Project Rogue*. It provides a real-time GUI for monitoring player stats, managing hotkeys for various in-game actions, and automating essential gameplay functions like healing, targeting, and curing sicknesses.

> **Disclaimer:** This tool is meant strictly for authorized security testing and personal use. Unauthorized use is illegal. The developers hold no liability for any misuse.

## Features

- **Auto-Healing**: Automatically presses the "2" key to use a healing item when health drops below a customizable percentage.
- **Memory Reading**: Reads and displays in-game data such as health, status effects, and player position.
- **Sickness Management**: Detects and cures various in-game afflictions.
- **Targeting System**: Automatically locks onto enemies using hotkeys.
- **Customizable Hotkeys**: Load and modify keybindings via a JSON configuration file.
- **Real-Time GUI**: Provides a visual interface to track and control various functions.

## Installation

### Requirements

- **Operating System**: Windows
- **AutoIt**: Ensure you have AutoIt installed to run the script.

### Setup

1. Download the **RogueReader** script and extract it to a directory of your choice.
2. Ensure **AutoIt3** is installed on your system.
3. Run the script (`RogueReader.au3`) using AutoIt or compile it into an executable.
4. Launch *Project Rogue* before running the script.

## Usage

### Running the Script

1. Start *Project Rogue*.
2. Run `RogueReader.au3` or its compiled executable.
3. The GUI will appear displaying various game stats.
4. Use hotkeys to toggle features like healing, targeting, and curing.

### Configuring Hotkeys

The script loads keybindings from a `Config.json` file. If this file is missing, it is automatically created with default values.

#### Default Hotkeys

| Action | Hotkey |
| ------ | ------ |
| Heal   | `{1}`  |
| Cure   | `{2}`  |
| Target | `{3}`  |
| Exit   | `{4}`  |

To modify hotkeys:

1. Open `Config.json` in a text editor.
2. Update the values to your preferred keys.
3. Save and restart the script.

### GUI Controls

- **Health, Position, and Status Displays**: Continuously updates in real-time.
- **Toggle Features**: Use hotkeys to enable/disable healing, targeting, and curing.
- **Kill Button**: Instantly closes *Project Rogue*.
- **Exit Button**: Closes the trainer.
- **Slider Control**: Adjusts the healing threshold dynamically.

## How It Works:

1. **Healing**: Watches your health. If it drops too low (default is 95%, adjustable via slider), it will automatically press the "2" key to heal.
2. **Hotkey to Toggle Healing**: Press a key to toggle healing on/off. Default is **\`** (under the Esc key), but it can be changed.
3. **Position and Health Display**: The GUI shows your character’s position (Pos X, Pos Y), health (HP), and max health (MaxHP) while playing.

## What You See:

- **Pos X and Pos Y**: Your character’s in-game position.
- **HP and MaxHP**: Your current and full health.
- **Healer**: Shows whether auto-healing is ON or OFF.
- **Pots go in #2**: A reminder that healing items should be assigned to the "2" key in-game.

## How to Stop:

1. Click **"Exit"** in the program to close it safely.
2. Press the hotkey again to stop auto-healing.

## Technical Details

### Memory Addresses

The script reads memory addresses to extract in-game information such as:

- **HP and Max HP**
- **Position (X, Y coordinates)**
- **Sickness Status**
- **Attack Mode and Target Type**

It uses **WinAPI-based memory access** for process reading and module enumeration to ensure compatibility.

### Process Handling

- The script continuously checks for *Project Rogue*'s process.
- If the process is not found, it waits until the game is launched.
- Upon detecting the game, it connects and updates memory addresses dynamically.

## Troubleshooting

### Common Issues & Fixes

#### Issue: GUI Not Displaying Correct Values

- Ensure *Project Rogue* is running.
- Restart the trainer.
- Run the script as **Administrator**.

#### Issue: Hotkeys Not Working

- Check `Config.json` for correct keybindings.
- Make sure `Config.json` is formatted properly.

#### Issue: Game Not Detected

- Confirm that the process name `Project Rogue Client.exe` matches the running process.
- Run the trainer **after** launching *Project Rogue*.

## Contribution

Feel free to contribute by submitting pull requests or reporting issues on GitHub.

## License

**Copyright © 2025 Macro Is Fun LLC**

Use only for authorized security testing. Unauthorized use is illegal. No liability for misuse.
