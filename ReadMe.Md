# RogueReader - Memory Reader for Project Rogue

RogueReader is a Python-based memory reader for the game **Project Rogue**. It reads specific in-game values such as position (`PosX`, `PosY`), health, sickness, mode, type, and more directly from the game's memory and displays them in a GUI in real-time. The application also allows you to adjust the update speed dynamically using a slider, with settings saved persistently between launches.

## Features

- **Memory Reading**: Reads in-game values like position, health (Real HP), sickness, mode, and type from the **Project Rogue** process.
- **Real-time GUI Updates**: Displays values in real-time on a GUI, with fast refreshes.
- **Slider for Update Speed**: Adjust the update speed dynamically via a slider in the GUI, ranging from **0.05 seconds** to **1 second**.
- **Config Persistence**: The slider value (update speed) is saved in a **binary configuration file** and loaded automatically at startup.
- **Kill Project Rogue**: A button to kill the **Project Rogue** process directly from the GUI.
- **Debugging Mode**: Toggle debug messages to the console to monitor memory reads and process interaction.

## Installation

### Prerequisites
- Python 3.x
- The following Python libraries must be installed:
  - `pymem`
  - `psutil`
  - `tkinter`
  - `pywin32`

You can install the required libraries using `pip`:

```bash
pip install pymem psutil pywin32
