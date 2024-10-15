# RogueReader

**RogueReader** is a tool that reads memory values from a game called **Project Rogue Client** and helps you do some cool things, like setting waypoints for your character to move automatically and healing when needed.

---

## How It Works

- **Memory Reading:** The tool looks at the game's memory and finds important numbers, like your character's position and health.
- **Waypoints:** You can tell the tool to remember up to 20 places (called "waypoints") that your character should move to.
- **Auto-Healing:** The tool can automatically heal your character when their health gets low.
- **GUI:** The tool has a small window where you can see what's happening and interact with it.

---

## Hotkeys (Special Keys to Control the Tool)

- **` \ `** : Set a new waypoint where your character is standing.<br>
- **` ] `** : Wipe (delete) all waypoints.<br>
- **` / `** : Start moving through the waypoints one by one.<br>
- **` ' `** : Pause or resume waypoint movement.<br>

---

## How to Use the Tool

1. **Start the Tool**: Run the script while the game **Project Rogue Client** is open.
2. **Set Waypoints**: Press the `\` key to set waypoints where you want your character to go.
3. **Wipe Waypoints**: If you want to delete all waypoints, press the `]` key.
4. **Move Automatically**: Press `/` to start moving through the waypoints.
5. **Pause/Resume Movement**: If you need to pause the movement, press `'` to pause or resume.

---

## The GUI (Graphical User Interface)

When you run the tool, a small window will appear with the following information:

- **Type**: What kind of target your character is facing (Player, Monster, NPC, etc.).<br>
- **Attack Mode**: Whether your character is in Safe or Attack mode.<br>
- **Pos X**: Your character's current X position on the map.<br>
- **Pos Y**: Your character's current Y position on the map.<br>
- **HP (Health Points)**: Your character's current health.<br>
- **Max HP**: The maximum health your character can have.<br>
- **Healer Status**: Tells you if the healer is on or off.<br>
- **Waypoints**: The number of waypoints you’ve set.<br>
- **Navigating to Waypoint**: The current waypoint your character is moving toward.

---

## Auto-Healing

- The tool can automatically heal your character by pressing the `2` key when their health gets too low.
- You can set a threshold to control when the healing happens. By default, it will heal when your character’s health drops below **95%**.

---

## Troubleshooting

- **Exit Button Not Working**: If you click the exit button and nothing happens, don’t worry! This has been fixed, and the exit button should now work properly.
- **Errors**: If you run into problems, make sure the game is open and the tool can read its memory.

---

## Credits

This tool is built using **AutoIt** and reads memory from **Project Rogue Client** to make gameplay more enjoyable by automating some tasks.

---

That’s it! Have fun with your waypoints and auto-healing! 😊

---
