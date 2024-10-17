# RogueReader - Automated Memory Reader and Healer for "Project Rogue"

## Overview

RogueReader is an automation script written in AutoIt that reads memory values from the game "Project Rogue" and automates actions based on real-time data. The script uses specific memory addresses to track the player's position, health, and status effects (like ailments) and can automate healing, cure ailments, and other functions based on the game state. It also features a graphical user interface (GUI) for real-time feedback and customization.

## Features

- **Memory Reading**: Reads memory values like position (X, Y), health points (HP), maximum HP, attack mode, and chat status.
- **Healing Automation**: Automatically heals the player when HP falls below a configurable threshold.
- **Ailment Detection**: Detects ailments like poisoning and diseases, and cures them automatically.
- **Customizable Hotkeys**: Set hotkeys for toggling the healer and other actions.
- **Configurable Refresh Rates**: Users can customize the refresh rate (in ms) for reading memory values.
- **Real-time GUI Feedback**: Provides a user-friendly interface displaying the current in-game stats.

## Requirements

- **AutoIt**: Download and install AutoIt from [AutoIt Website](https://www.autoitscript.com/site/autoit/).
- **Project Rogue Game**: The script interacts with the game process. Make sure the game is running.

## How to Use

1. **Clone the Repository**:
   ```bash
   git clone https://github.com/YourGitHubUsername/RogueReader.git
