# RogueReader

**RogueReader** is a tool designed to help automate healing and monitor certain data while playing a game called **Project Rogue**. It checks your character's health, position, and other game-related data, and automatically sends commands to heal your character when needed.

### Features:
1. **Auto-Healing**: It automatically presses the "2" key to use a healing item if your health drops below a certain percentage.
2. **Memory Reader**: It reads your character's position, health, and other values from the game.
3. **Hotkey**: You can press a special key to turn the auto-healing on or off.
4. **Custom Settings**: You can adjust the healing percentage and the refresh speed (how fast the program checks your data).
5. **Configurable Hotkey**: You can change which key is used to turn healing on or off.

## How It Works:

1. **Healing**: The program watches your health. If your health gets too low (you can decide how low by setting the percentage), it will automatically press the "2" key to heal your character.
2. **Hotkey to Toggle Healing**: You can turn the healer on or off by pressing a key. The default key is **`** (the one under the Esc key), but you can change it in the program.
3. **Position and Health Display**: The program also shows your character's position (Pos X, Pos Y), health (HP), and maximum health (MaxHP) in a window while you're playing.

## How to Use It:

1. **Run the Script**: Start **RogueReader** by opening the `RogueReader.au3` file.
2. **Configure Your Settings**:
   - **Healer Hotkey**: Click the "Change Hotkey" button to choose which key turns the healer on and off.
   - **Healing Percentage**: Use the slider to set the health percentage below which your character will auto-heal. The default is 95%.
   - **Refresh Rate**: Use the second slider to control how often the program checks your character's health (lower numbers are faster, higher numbers are slower).
3. **Watch the Data**: The window will show your current position (Pos X and Pos Y), health (HP), and maximum health (MaxHP).
4. **Killing the Game**: You can click the "Kill Rogue" button to close the game from the program.

## What You See:

- **Pos X and Pos Y**: These show where your character is in the game.
- **HP and MaxHP**: HP is your current health, and MaxHP is your full health.
- **Healer**: This tells you if auto-healing is ON or OFF.
- **Pots go in #2**: A reminder that healing items should be set to the "2" key in your game.

## How to Stop:
1. Click the **"Exit"** button in the program to close it safely.
2. You can also press the hotkey again to stop the healer if needed.

## What Do I Need to Know About the Game?

- Make sure you have healing items set to the **"2" key** in your game so that the healer can use them automatically when needed.
"""
