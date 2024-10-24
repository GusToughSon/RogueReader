# 🛡️ Project Rogue Helper

**Project Rogue Helper** is an assistant for the game "Project Rogue." It helps you automatically heal, target enemies, and walk in the game! Plus, you can control everything with easy hotkeys!

## ⚙️ Features

- **Automatic Healing**: It heals you when your health is low.
- **Automatic Targeting**: Finds enemies for you to attack.
- **Automatic Walking**: Moves your character through locations you set in the game!
- **Custom Hotkeys**: Set your own hotkeys for healer, targeter, and walker.
- **Live Game Data**: See your character’s health, position, and more!

---

## 🖼️ How It Works

Here's a simple visual explanation:

1. **Healing**: Automatically presses the "heal" button (set to key `2` in the game) when your health drops below a set percentage.
2. **Targeting**: Automatically presses the "target" button (set to `Tab`) when there’s no target.
3. **Walking**: Automatically walks your character through locations you set and saves them to a file.

```plaintext
+---------------------+
|   Project Rogue     |
+---------------------+
      |    ^    |
   Healing    Targeting
      |    ^    |
      v    |    v
+---------------------+
|   Rogue Helper      |
+---------------------+
   |        |       |
  Health   Target   Walk
  |       |        |
  v       v        v
Auto Heal  Auto Target  Auto Walk (with locations)
