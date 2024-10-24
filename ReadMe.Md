# Rogue Reader Project

## Description

Rogue Reader is an automation tool designed for the **Project Rogue Client**. It integrates various features such as:
- **Auto-Healing**: Automatically heals the player when health falls below a configured threshold.
- **Auto-Targeting**: Automatically targets monsters, NPCs, or players depending on the game state.
- **Auto-Walking**: Supports automated walking in the game.
- **Dynamic Controls**: Allows toggling of healer, targeter, and walker features via configurable hotkeys.

This project is designed to interact with the game client using **AutoIt** to send controls and **Python's pymem** to read memory from the game process. 

## Features

- **Healer**: Automatically heals the character based on health percentage and configurable delay.
- **Targeter**: Automatically targets enemies when no valid target is selected.
- **Walker**: Automates walking to predefined locations within the game.
- **Dynamic Configuration**: Hotkeys, delays, and other settings are configurable and saved between sessions.
- **Reconnection Logic**: Automatically reattaches to the game client if it is closed and reopened.

## Setup

### Prerequisites
Before running the project, ensure that you have the following dependencies installed:
- Python 3.13 or higher
- The following Python packages:
  ```bash
  pip install psutil pymem autoit keyboard
