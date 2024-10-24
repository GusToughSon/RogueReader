import tkinter as tk
from tkinter import ttk
import threading
import psutil
import pymem
import time
import os
import pickle
import keyboard  # For hotkey detection
import autoit  # For AutoIt control sending
from concurrent.futures import ThreadPoolExecutor

CONFIG_FILE = "config.dat"
PROCESS_NAME = "Project Rogue Client.exe"
TARGET_WINDOW_NAME = "Project Rogue"
process_pid = None
pm = None

# Global flag to stop background threads
running = True

# Initialize default values
default_config_data = {
    'pot_delay': 2000,  # Default Pot Delay in milliseconds
    'heal_percent': 50,  # Default Heal Percent
    'healer_hotkey': '`',
    'targeter_hotkey': '-',
    'walker_hotkey': '/',
    'walker_set_hotkey': '}',
    'walker_wipe_hotkey': '{',
    'window_width': 4000,  # Default width
    'window_height': 6000,  # Default height
    'window_x': 100,  # Default x position
    'window_y': 100,  # Default y position,
    'healer_status': False,  # Default OFF
    'targeter_status': True,  # Default ON
    'walker_status': False  # Default OFF
}

config_data = default_config_data.copy()  # Start with defaults

# ThreadPool for task execution
executor = ThreadPoolExecutor(max_workers=5)

# Global timestamp for tracking last heal time
last_heal_time = 0

def save_config():
    """Save the configuration to the file."""
    with open(CONFIG_FILE, 'wb') as f:
        pickle.dump(config_data, f)

def load_config():
    """Load the configuration from the file, updating default values."""
    global config_data
    if os.path.exists(CONFIG_FILE):
        try:
            with open(CONFIG_FILE, 'rb') as f:
                loaded_data = pickle.load(f)
                config_data.update(loaded_data)  # Update with loaded config
        except (pickle.UnpicklingError, EOFError, Exception):
            save_config()  # Save defaults if loading fails
    else:
        save_config()  # Save defaults if file doesn't exist

# Healer, Targeter, and Walker dynamic status updating
def update_healer_status(new_status):
    """Update healer status dynamically and save to config."""
    config_data['healer_status'] = new_status
    save_config()

def update_targeter_status(new_status):
    """Update targeter status dynamically and save to config."""
    config_data['targeter_status'] = new_status
    save_config()

def update_walker_status(new_status):
    """Update walker status dynamically and save to config."""
    config_data['walker_status'] = new_status
    save_config()

def attach_to_process():
    global process_pid, pm
    while running:
        try:
            proc = [p for p in psutil.process_iter(['name']) if p.info['name'] == PROCESS_NAME]
            if proc:
                process_pid = proc[0].pid
                pm = pymem.Pymem(PROCESS_NAME)
                base_address = validate_base_address()
                if base_address:
                    print(f"[PROCESS DEBUG]: Attached to process {PROCESS_NAME} with PID {process_pid}")
                    return
            else:
                print(f"[PROCESS DEBUG]: {PROCESS_NAME} not found. Reattempting connection...")
        except Exception as e:
            print(f"[ERROR]: Error attaching to process: {e}")
        time.sleep(2)  # Retry connection every 2 seconds

def validate_base_address():
    try:
        if pm is None:
            return None
        base_address = pymem.process.module_from_name(pm.process_handle, PROCESS_NAME).lpBaseOfDll
        return base_address if base_address else None
    except Exception:
        return None

def read_memory(offset):
    try:
        base_address = validate_base_address()
        if base_address:
            value = pm.read_int(base_address + offset)
            return value
        print(f"[MEMORY DEBUG]: Failed to read memory at offset {hex(offset)}")
        return None
    except Exception as e:
        print(f"[ERROR]: Failed to read memory at offset {hex(offset)}: {e}")
        return None

# Perform targeting in its own thread
def perform_targeting():
    """Separate thread for handling targeting."""
    while running:
        if config_data['targeter_status']:  # Check if targeting is enabled
            if pm is None:
                attach_to_process()  # Reconnect if the process is lost

            mode = read_memory(0xAC1D60)
            target_type = read_memory(0xBEFA34)
            chat_open = read_memory(0x9B6998)

            # Pause if chat is open
            if chat_open == 1:
                time.sleep(0.4)
                continue

            # If no target or invalid target (65535), send 'Tab'
            if mode == 1 and (target_type == 0 or target_type == 65535):
                control_send_to_project_rogue("{TAB}")
                time.sleep(0.4)  # Sleep for 400 ms after sending 'Tab'
            else:
                time.sleep(0.3)
        else:
            time.sleep(0.1)  # Sleep briefly when targeting is off

# Healing thread
def perform_healing():
    global last_heal_time
    while running:
        if config_data['healer_status']:
            if pm is None:
                attach_to_process()  # Reconnect if the process is lost

            current_time = time.time() * 1000  # Current time in milliseconds
            pot_delay = config_data['pot_delay']

            # Check if the required pot delay time has passed
            if current_time - last_heal_time >= pot_delay:
                real_hp = read_memory(0x9BF988)
                max_hp = read_memory(0x9BF98C)
                chat_open = read_memory(0x9B6998)

                # Pause if chat is open
                if chat_open == 1:
                    print("[HEALER DEBUG]: Chat is open, pausing healing.")
                    time.sleep(0.4)
                    continue

                if real_hp is None or max_hp is None:
                    continue

                real_hp_scaled = real_hp / 65535  # Real HP calculation
                heal_percent = config_data['heal_percent'] / 100.0  # HealPercent scaled to 0-0.98

                if real_hp_scaled < (max_hp * heal_percent):
                    control_send_to_project_rogue("2")
                    last_heal_time = current_time
                    healer_sleep(pot_delay)

        time.sleep(0.1)

def healer_sleep(ms_delay):
    """Custom sleep function for the healer with interrupt on healer_status change."""
    total_sleep_time = ms_delay / 1000.0
    for _ in range(int(total_sleep_time * 10)):  # Small chunks of 0.1 seconds
        if not config_data['healer_status']:
            return
        time.sleep(0.1)

def control_send_to_project_rogue(key):
    """Control sends the key to the Project Rogue window using AutoIt's ControlSend."""
    try:
        if autoit.win_exists(TARGET_WINDOW_NAME):
            try:
                autoit.control_send(TARGET_WINDOW_NAME, "", key)
                print(f"[AUTOIT DEBUG]: Sent {key} to {TARGET_WINDOW_NAME}")
            except autoit.AutoItError as e:
                print(f"[AUTOIT ERROR]: {e}")
        else:
            print(f"[AUTOIT ERROR]: Window '{TARGET_WINDOW_NAME}' not found.")
    except OSError as os_error:
        print(f"[AUTOIT ERROR]: OSError encountered while checking window: {os_error}")
        time.sleep(2)  # Delay to allow the game client to reinitialize before retrying

# Hotkey listener for toggling status
def hotkey_listener():
    while running:
        if keyboard.is_pressed(config_data['healer_hotkey']):
            new_status = not config_data['healer_status']
            update_healer_status(new_status)
            root.after(0, lambda: healer_status_label.config(bg="green" if new_status else "red"))
            root.after(0, lambda: healer_status_label.config(text=f"Healer: {'ON' if new_status else 'OFF'}"))
            time.sleep(0.2)

        if keyboard.is_pressed(config_data['targeter_hotkey']):
            new_status = not config_data['targeter_status']
            update_targeter_status(new_status)
            root.after(0, lambda: targeter_status_label.config(bg="green" if new_status else "red"))
            root.after(0, lambda: targeter_status_label.config(text=f"Targeter: {'ON' if new_status else 'OFF'}"))
            time.sleep(0.2)

        if keyboard.is_pressed(config_data['walker_hotkey']):
            new_status = not config_data['walker_status']
            update_walker_status(new_status)
            root.after(0, lambda: walker_status_label.config(bg="green" if new_status else "red"))
            root.after(0, lambda: walker_status_label.config(text=f"Walker: {'ON' if new_status else 'OFF'}"))
            time.sleep(0.2)

# Update memory display in the GUI
def update_memory_display():
    while running:
        if pm is None:
            attach_to_process()  # Reconnect if the process is lost

        real_hp = read_memory(0x9BF988)
        max_hp = read_memory(0x9BF98C)
        pos_x = read_memory(0xBF2C58)
        pos_y = read_memory(0xBF2C50)
        sickness = read_memory(0xBF0D50)
        chat_open = read_memory(0x9B6998)
        mode = read_memory(0xAC1D60)
        target_type = read_memory(0xBEFA34)

        real_hp_scaled = real_hp / 65535 if real_hp else 0
        root.after(0, lambda: hp_label.config(text=f"Real HP: {real_hp_scaled:.2f} | Max HP: {max_hp}" if real_hp and max_hp else "Real HP: N/A | Max HP: N/A"))
        root.after(0, lambda: posx_label.config(text=f"PosX: {pos_x}" if pos_x else "PosX: N/A"))
        root.after(0, lambda: posy_label.config(text=f"PosY: {pos_y}" if pos_y else "PosY: N/A"))
        sickness_status = 'Poison' if sickness == 1 else 'Disease' if sickness == 2 else 'None'
        root.after(0, lambda: sickness_label.config(text=f"Sickness: {sickness_status}"))
        chat_status = 'Yes' if chat_open == 1 else 'No'
        root.after(0, lambda: chat_label.config(text=f"Chat Open: {chat_status}"))
        mode_status = 'Attack' if mode == 1 else 'None'
        root.after(0, lambda: mode_label.config(text=f"Mode: {mode_status}"))
        target_type_str = "Monster" if target_type == 1 else "NPC" if target_type == 2 else "Player" if target_type == 3 else "None"
        root.after(0, lambda: type_label.config(text=f"Type: {target_type_str}"))

        time.sleep(0.5)

# Exit the script/program and stop all threads
def stop_threads_and_exit():
    global running
    running = False
    print("[EXIT DEBUG]: Stopping all threads...")
    time.sleep(0.5)
    for thread in threading.enumerate():
        if thread != threading.main_thread():
            thread.join(timeout=1)
    print("[EXIT DEBUG]: All threads stopped. Closing GUI.")
    root.quit()
    root.destroy()

def save_window_size_position():
    config_data['window_width'] = root.winfo_width()
    config_data['window_height'] = root.winfo_height()
    config_data['window_x'] = root.winfo_x()
    config_data['window_y'] = root.winfo_y()
    save_config()

def kill_rogue_process():
    global process_pid
    if process_pid:
        try:
            proc = psutil.Process(process_pid)
            proc.terminate()
            proc.wait(timeout=5)
        except psutil.NoSuchProcess:
            pass
        except psutil.TimeoutExpired:
            proc.kill()
        except Exception as e:
            print(f"[ERROR]: Failed to kill Project Rogue (PID: {process_pid}): {e}")

def update_pot_delay_values():
    config_data['pot_delay'] = pot_delay_slider.get()
    pot_delay_value_label.config(text=f"{config_data['pot_delay']} ms")
    save_config()

def update_heal_percent_values():
    config_data['heal_percent'] = heal_percent_slider.get()
    save_config()

# GUI Setup
root = tk.Tk()
root.title("Rogue Reader")
load_config()

width = config_data.get('window_width', 400)
height = config_data.get('window_height', 600)
x_pos = config_data.get('window_x', 100)
y_pos = config_data.get('window_y', 100)

root.geometry(f"{width}x{height}+{x_pos}+{y_pos}")
root.bind("<Configure>", lambda e: save_window_size_position())

# Hotkey Settings Frame
hotkey_frame = ttk.LabelFrame(root, text="Hotkey Settings", padding="10")
hotkey_frame.pack(fill="both", expand="yes", padx=10, pady=10)

# Healer Hotkey
healer_hotkey_label = tk.Label(hotkey_frame, text="Healer Hotkey:")
healer_hotkey_label.grid(row=0, column=0, sticky='w')
healer_hotkey_entry = tk.Entry(hotkey_frame)
healer_hotkey_entry.insert(0, config_data['healer_hotkey'])
healer_hotkey_entry.grid(row=0, column=1)
healer_status_label = tk.Label(hotkey_frame, text="Healer: OFF" if not config_data['healer_status'] else "Healer: ON", bg="red" if not config_data['healer_status'] else "green", fg="white")
healer_status_label.grid(row=0, column=2)
save_healer_button = tk.Button(hotkey_frame, text="Save Healer Hotkey", command=lambda: set_hotkey('healer_hotkey', healer_hotkey_entry))
save_healer_button.grid(row=0, column=3)

# Targeter Hotkey
targeter_hotkey_label = tk.Label(hotkey_frame, text="Targeter Hotkey:")
targeter_hotkey_label.grid(row=1, column=0, sticky='w')
targeter_hotkey_entry = tk.Entry(hotkey_frame)
targeter_hotkey_entry.insert(0, config_data['targeter_hotkey'])
targeter_hotkey_entry.grid(row=1, column=1)
targeter_status_label = tk.Label(hotkey_frame, text="Targeter: OFF" if not config_data['targeter_status'] else "Targeter: ON", bg="red" if not config_data['targeter_status'] else "green", fg="white")
targeter_status_label.grid(row=1, column=2)
save_targeter_button = tk.Button(hotkey_frame, text="Save Targeter Hotkey", command=lambda: set_hotkey('targeter_hotkey', targeter_hotkey_entry))
save_targeter_button.grid(row=1, column=3)

# Walker Hotkey
walker_hotkey_label = tk.Label(hotkey_frame, text="Walker Hotkey:")
walker_hotkey_label.grid(row=2, column=0, sticky='w')
walker_hotkey_entry = tk.Entry(hotkey_frame)
walker_hotkey_entry.insert(0, config_data['walker_hotkey'])
walker_hotkey_entry.grid(row=2, column=1)
walker_status_label = tk.Label(hotkey_frame, text="Walker: OFF" if not config_data['walker_status'] else "Walker: ON", bg="red" if not config_data['walker_status'] else "green", fg="white")
walker_status_label.grid(row=2, column=2)
save_walker_button = tk.Button(hotkey_frame, text="Save Walker Hotkey", command=lambda: set_hotkey('walker_hotkey', walker_hotkey_entry))
save_walker_button.grid(row=2, column=3)

# WalkerSet Hotkey
walkerset_hotkey_label = tk.Label(hotkey_frame, text="WalkerSet Hotkey:")
walkerset_hotkey_label.grid(row=3, column=0, sticky='w')
walkerset_hotkey_entry = tk.Entry(hotkey_frame)
walkerset_hotkey_entry.insert(0, config_data['walker_set_hotkey'])
walkerset_hotkey_entry.grid(row=3, column=1)
save_walkerset_button = tk.Button(hotkey_frame, text="Save WalkerSet Hotkey", command=lambda: set_hotkey('walker_set_hotkey', walkerset_hotkey_entry))
save_walkerset_button.grid(row=3, column=3)

# WalkerWipe Hotkey
walkerwipe_hotkey_label = tk.Label(hotkey_frame, text="WalkerWipe Hotkey:")
walkerwipe_hotkey_label.grid(row=4, column=0, sticky='w')
walkerwipe_hotkey_entry = tk.Entry(hotkey_frame)
walkerwipe_hotkey_entry.insert(0, config_data['walker_wipe_hotkey'])
walkerwipe_hotkey_entry.grid(row=4, column=1)
save_walkerwipe_button = tk.Button(hotkey_frame, text="Save WalkerWipe Hotkey", command=lambda: set_hotkey('walker_wipe_hotkey', walkerwipe_hotkey_entry))
save_walkerwipe_button.grid(row=4, column=3)

# Slider Frame
slider_frame = ttk.LabelFrame(root, text="Settings", padding="10")
slider_frame.pack(fill="both", expand="yes", padx=10, pady=10)

# Pot Delay Slider
pot_delay_label = tk.Label(slider_frame, text="Pot Delay (ms):")
pot_delay_label.grid(row=0, column=0)
pot_delay_slider = tk.Scale(slider_frame, from_=1500, to=4500, orient="horizontal", resolution=100, command=lambda e: update_pot_delay_values())
pot_delay_slider.set(config_data['pot_delay'])
pot_delay_slider.grid(row=0, column=1)
pot_delay_value_label = tk.Label(slider_frame, text=f"{config_data['pot_delay']} ms")
pot_delay_value_label.grid(row=0, column=2)

# Heal Percent Slider
heal_percent_label = tk.Label(slider_frame, text="Heal Percent (%):")
heal_percent_label.grid(row=1, column=0)
heal_percent_slider = tk.Scale(slider_frame, from_=1, to=98, orient="horizontal", resolution=1, command=lambda e: update_heal_percent_values())
heal_percent_slider.set(config_data['heal_percent'])
heal_percent_slider.grid(row=1, column=1)

# Live Data Frame
info_frame = ttk.LabelFrame(root, text="Live Data", padding="10")
info_frame.pack(fill="both", expand="yes", padx=10, pady=10)

posx_label = tk.Label(info_frame, text="PosX: 0")
posx_label.grid(row=0, column=0)
posy_label = tk.Label(info_frame, text="PosY: 0")
posy_label.grid(row=0, column=1)
hp_label = tk.Label(info_frame, text="Real HP: 0.00 | Max HP: 0.00")
hp_label.grid(row=1, column=0, columnspan=2)
sickness_label = tk.Label(info_frame, text="Sickness: None")
sickness_label.grid(row=2, column=0)
chat_label = tk.Label(info_frame, text="Chat Open: No")
chat_label.grid(row=2, column=1)
mode_label = tk.Label(info_frame, text="Mode: None")
mode_label.grid(row=3, column=0)
type_label = tk.Label(info_frame, text="Type: None")  # Initialize as "None"
type_label.grid(row=3, column=1)

# Kill and Exit Buttons
button_frame = ttk.Frame(root, padding="5")
button_frame.pack(fill="both", expand="yes", padx=5, pady=5)

# Stack the buttons vertically
kill_button = tk.Button(button_frame, text="Kill Project Rogue", command=kill_rogue_process, font=('Arial', 8))
kill_button.pack(side="top", pady=5)

exit_button = tk.Button(button_frame, text="Exit", command=stop_threads_and_exit, font=('Arial', 8))
exit_button.pack(side="top", pady=5)

# Start background threads
load_config()
threading.Thread(target=hotkey_listener).start()
threading.Thread(target=perform_healing).start()  # Healing thread
threading.Thread(target=perform_targeting).start()  # Targeting thread
threading.Thread(target=update_memory_display).start()  # Update memory values display thread

root.mainloop()
