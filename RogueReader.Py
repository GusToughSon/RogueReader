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
    'window_width': 400,  # Default width
    'window_height': 600,  # Default height
    'window_x': 100,  # Default x position
    'window_y': 100,  # Default y position,
}

config_data = default_config_data.copy()  # Start with defaults

# States for Healer, Targeter, Walker
healer_status = False
targeter_status = True  # Default on
walker_status = False

# Last known values to avoid unnecessary UI updates
last_known_values = {
    "real_hp": None,
    "max_hp": None,
    "sickness": None,
    "pos_x": None,
    "pos_y": None,
    "type_val": None,
    "chat_open": None,
    "mode": None
}

# ThreadPool for task execution
executor = ThreadPoolExecutor(max_workers=5)

# Global timestamp for tracking last heal time
last_heal_time = 0

def save_config():
    with open(CONFIG_FILE, 'wb') as f:
        pickle.dump(config_data, f)

def load_config():
    global config_data
    if os.path.exists(CONFIG_FILE):
        try:
            with open(CONFIG_FILE, 'rb') as f:
                loaded_data = pickle.load(f)
                config_data.update(loaded_data)  # Update with loaded config
        except (pickle.UnpicklingError, EOFError, Exception):
            save_config()
    else:
        save_config()

def attach_to_process():
    global process_pid, pm
    while running:  # Ensure the loop stops when the program exits
        try:
            proc = [p for p in psutil.process_iter(['name']) if p.info['name'] == PROCESS_NAME]
            if proc:
                process_pid = proc[0].pid
                pm = pymem.Pymem(PROCESS_NAME)
                base_address = validate_base_address()
                if base_address:
                    return
        except Exception as e:
            print(f"[ERROR]: Error attaching to process: {e}")
        time.sleep(2)

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
        return None
    except Exception:
        return None

def perform_healing_and_targeting():
    """Separate thread for handling healing and targeting"""
    global last_heal_time
    while running:
        # Healing logic
        if healer_status:
            current_time = time.time() * 1000  # Current time in milliseconds
            pot_delay = config_data['pot_delay']
            
            # Check if the required pot delay time has passed
            if current_time - last_heal_time >= pot_delay:
                print("[HEALER DEBUG]: Checking healer status and health.")
                
                real_hp = read_memory(0x9BF988)
                max_hp = read_memory(0x9BF98C)
                
                if real_hp is None or max_hp is None:
                    print("[HEALER DEBUG]: Error reading HP from memory. Skipping healing check.")
                    continue

                real_hp_scaled = real_hp / 65535  # Real HP calculation
                heal_percent = config_data['heal_percent'] / 100.0  # HealPercent is 1-98 scaled to 0-0.98

                print(f"[HEALER DEBUG]: Current HP: {real_hp_scaled}, Max HP: {max_hp}, Heal Threshold: {heal_percent*100}%")

                if real_hp_scaled < (max_hp * heal_percent):
                    print(f"[HEALER DEBUG]: HP is below {heal_percent*100}% of max HP, sending '2' to heal.")
                    control_send_to_project_rogue("2")
                    
                    last_heal_time = current_time  # Update the last heal time
                    print(f"[HEALER DEBUG]: Updated last heal time to {last_heal_time} ms.")
                    
                    healer_sleep(pot_delay)  # Use the Pot Delay value from the slider
                    print("[HEALER DEBUG]: Finished waiting for the pot delay, checking health again.")
                else:
                    print(f"[HEALER DEBUG]: HP is above {heal_percent*100}%. No healing needed.")

        # Targeting logic
        if targeter_status:
            # Check if in attack mode and if type is None
            mode = read_memory(0xAC1D60)
            target_type = read_memory(0xBEFA34)
            
            if mode == 1 and target_type == 0:
                print("[TARGETER DEBUG]: No target, sending 'Tab' to target next.")
                control_send_to_project_rogue("Tab")
                time.sleep(0.4)  # Sleep for 400 ms after sending 'Tab'

        time.sleep(0.1)  # Keep the thread responsive with a short sleep between cycles

def healer_sleep(ms_delay):
    """Custom sleep function for the healer with interrupt on healer_status change"""
    global healer_status
    total_sleep_time = ms_delay / 1000.0  # Convert milliseconds to seconds
    print(f"[HEALER DEBUG]: Sleeping for {total_sleep_time} seconds.")
    
    # Loop in small increments to ensure we can catch healer_status changes
    for _ in range(int(total_sleep_time * 10)):  # Small chunks of 0.1 seconds
        if not healer_status:
            print("[HEALER DEBUG]: Healer status changed. Exiting sleep early.")
            return
        time.sleep(0.1)  # Sleep in small increments to check healer_status frequently

def control_send_to_project_rogue(key):
    """Control sends the key to the Project Rogue window using AutoIt's ControlSend."""
    if autoit.win_exists(TARGET_WINDOW_NAME):
        autoit.control_send(TARGET_WINDOW_NAME, "", key)
        print(f"[HEALER DEBUG]: Sent key '{key}' to '{TARGET_WINDOW_NAME}' using ControlSend.")
    else:
        print(f"[HEALER DEBUG]: Window '{TARGET_WINDOW_NAME}' not found.")

def update_vars():
    cycle_counter = 0
    while running:  # Ensure the loop stops when the program exits
        if pm:
            executor.submit(read_and_update_hp_sickness)
            executor.submit(read_and_update_type)
            executor.submit(read_and_update_position)  # Added position update here
            executor.submit(read_and_update_chat_mode)  # Added chat mode update here
        else:
            attach_to_process()

        cycle_counter += 1
        time.sleep(0.5)

def read_and_update_hp_sickness():
    """Reads and updates HP and Sickness status."""
    real_hp = read_memory(0x9BF988)  # Corrected Reading HP
    max_hp = read_memory(0x9BF98C)  # Corrected Reading Max HP
    sickness = read_memory(0xBF0D50)  # Reverted to the previous working Sickness memory address

    if real_hp != last_known_values['real_hp'] or max_hp != last_known_values['max_hp']:
        last_known_values['real_hp'] = real_hp
        last_known_values['max_hp'] = max_hp
        real_hp = real_hp / 65535 if real_hp is not None else None
        root.after(0, lambda: hp_label.config(text=f"Real HP: {real_hp:.2f} | Max HP: {max_hp}" if real_hp is not None and max_hp is not None else "Real HP: N/A | Max HP: N/A"))

    if sickness != last_known_values['sickness']:
        last_known_values['sickness'] = sickness
        sickness_status = 'Poison' if sickness == 1 else 'Disease' if sickness == 2 else 'None'
        root.after(0, lambda: sickness_label.config(text=f"Sickness: {sickness_status}"))

def read_and_update_position():
    """Reads and updates position X and Y."""
    pos_x = read_memory(0xBF2C58)  # Reverted PosX memory address to the correct one
    pos_y = read_memory(0xBF2C50)  # Reverted PosY memory address to the correct one

    if pos_x != last_known_values['pos_x']:
        last_known_values['pos_x'] = pos_x
        root.after(0, lambda: posx_label.config(text=f"PosX: {pos_x}" if pos_x else "PosX: N/A"))

    if pos_y != last_known_values['pos_y']:
        last_known_values['pos_y'] = pos_y
        root.after(0, lambda: posy_label.config(text=f"PosY: {pos_y}" if pos_y else "PosY: N/A"))

def read_and_update_chat_mode():
    """Reads and updates chat open status and mode."""
    chat_open = read_memory(0x9B6998)  # Corrected Chat Open memory address
    mode = read_memory(0xAC1D60)  # Corrected Mode memory address

    if chat_open != last_known_values['chat_open']:
        last_known_values['chat_open'] = chat_open
        root.after(0, lambda: chat_label.config(text=f"Chat Open: {'Yes' if chat_open == 1 else 'No'}"))

    if mode != last_known_values['mode']:
        last_known_values['mode'] = mode
        root.after(0, lambda: mode_label.config(text=f"Mode: {'Attack' if mode == 1 else 'None'}"))

def read_and_update_type():
    """Reads and updates the 'Type' value from memory and updates the GUI."""
    type_val = read_memory(0xBEFA34)  # Reading the type value from memory

    if type_val != last_known_values['type_val']:
        last_known_values['type_val'] = type_val
        type_string = get_type_string(type_val)
        root.after(0, lambda: type_label.config(text=f"Type: {type_string}"))

def get_type_string(val):
    """Maps the memory value to the corresponding type."""
    if val == 0 or val == 65535:
        return "None"
    elif val == 1:
        return "Monster"
    elif val == 2:
        return "NPC"
    elif val == 3:
        return "Player"
    else:
        return "Unknown"

def initialize_memory_reader():
    attach_to_process()
    threading.Thread(target=update_vars, daemon=True).start()
    threading.Thread(target=perform_healing_and_targeting, daemon=True).start()  # Start the healing and targeting thread

# New function: set_hotkey
def set_hotkey(hotkey_name, entry_widget):
    """Updates and saves the hotkey for a given function."""
    new_hotkey = entry_widget.get()
    if new_hotkey:
        config_data[hotkey_name] = new_hotkey
        save_config()

# Hotkey listener
def hotkey_listener():
    global healer_status, targeter_status, walker_status
    while running:  # Ensure the loop stops when the program exits
        if keyboard.is_pressed(config_data['healer_hotkey']):
            healer_status = not healer_status
            root.after(0, lambda: healer_status_label.config(bg="green" if healer_status else "red"))
            root.after(0, lambda: healer_status_label.config(text=f"Healer: {'ON' if healer_status else 'OFF'}"))
            time.sleep(0.2)

        if keyboard.is_pressed(config_data['targeter_hotkey']):
            targeter_status = not targeter_status
            root.after(0, lambda: targeter_status_label.config(bg="green" if targeter_status else "red"))
            root.after(0, lambda: targeter_status_label.config(text=f"Targeter: {'ON' if targeter_status else 'OFF'}"))
            time.sleep(0.2)

        if keyboard.is_pressed(config_data['walker_hotkey']):
            walker_status = not walker_status
            root.after(0, lambda: walker_status_label.config(bg="green" if walker_status else "red"))
            root.after(0, lambda: walker_status_label.config(text=f"Walker: {'ON' if walker_status else 'OFF'}"))
            time.sleep(0.2)

def stop_threads_and_exit():
    """Gracefully stop threads before exiting."""
    global running
    running = False  # Set running to False to stop threads
    root.quit()

def save_window_size_position():
    """Saves the current window size and position to the config."""
    config_data['window_width'] = root.winfo_width()
    config_data['window_height'] = root.winfo_height()
    config_data['window_x'] = root.winfo_x()
    config_data['window_y'] = root.winfo_y()
    save_config()

def kill_rogue_process():
    """Gracefully kill the Project Rogue process."""
    global process_pid
    if process_pid:
        try:
            stop_threads_and_exit()
            proc = psutil.Process(process_pid)
            proc.terminate()
            proc.wait(timeout=5)
        except psutil.NoSuchProcess:
            pass
        except psutil.TimeoutExpired:
            proc.kill()
        except Exception as e:
            print(f"[ERROR]: Failed to kill Project Rogue (PID: {process_pid}): {e}")

# Pot Delay Slider value update function
def update_pot_delay_values():
    """Updates pot delay values and displays the current value next to the slider."""
    config_data['pot_delay'] = pot_delay_slider.get()
    pot_delay_value_label.config(text=f"{config_data['pot_delay']} ms")
    save_config()

# Heal Percent Slider value update function
def update_heal_percent_values():
    """Updates heal percent values and saves config dynamically."""
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
healer_status_label = tk.Label(hotkey_frame, text="Healer: OFF", bg="red", fg="white")
healer_status_label.grid(row=0, column=2)
save_healer_button = tk.Button(hotkey_frame, text="Save Healer Hotkey", command=lambda: set_hotkey('healer_hotkey', healer_hotkey_entry))
save_healer_button.grid(row=0, column=3)

# Targeter Hotkey
targeter_hotkey_label = tk.Label(hotkey_frame, text="Targeter Hotkey:")
targeter_hotkey_label.grid(row=1, column=0, sticky='w')
targeter_hotkey_entry = tk.Entry(hotkey_frame)
targeter_hotkey_entry.insert(0, config_data['targeter_hotkey'])
targeter_hotkey_entry.grid(row=1, column=1)
targeter_status_label = tk.Label(hotkey_frame, text="Targeter: ON", bg="green", fg="white")
targeter_status_label.grid(row=1, column=2)
save_targeter_button = tk.Button(hotkey_frame, text="Save Targeter Hotkey", command=lambda: set_hotkey('targeter_hotkey', targeter_hotkey_entry))
save_targeter_button.grid(row=1, column=3)

# Walker Hotkey
walker_hotkey_label = tk.Label(hotkey_frame, text="Walker Hotkey:")
walker_hotkey_label.grid(row=2, column=0, sticky='w')
walker_hotkey_entry = tk.Entry(hotkey_frame)
walker_hotkey_entry.insert(0, config_data['walker_hotkey'])
walker_hotkey_entry.grid(row=2, column=1)
walker_status_label = tk.Label(hotkey_frame, text="Walker: OFF", bg="red", fg="white")
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

# Heal Percent Slider (now with a max of 98%)
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
threading.Thread(target=initialize_memory_reader, daemon=True).start()
threading.Thread(target=hotkey_listener, daemon=True).start()

root.mainloop()
