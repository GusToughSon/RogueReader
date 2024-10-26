import os
import ctypes
import tkinter as tk
from tkinter import ttk
import threading
import psutil
import pymem
import time
import pickle
import keyboard  # For hotkey detection
import autoit  # Now you can safely import autoit
from concurrent.futures import ThreadPoolExecutor
import sys

CONFIG_FILE = "config.dat"
PROCESS_NAME = "Project Rogue Client.exe"
TARGET_WINDOW_NAME = "Project Rogue"
process_pid = None
pm = None

# Global flag to stop background threads
running = True

# Initialize default values
default_config_data = {
    'pot_delay': 1700,  # Default Pot Delay in milliseconds
    'heal_percent': 97,  # Default Heal Percent
    'healer_hotkey': '`',
    'targeter_hotkey': '-',
    'walker_hotkey': '/',
    'walker_set_hotkey': '}',
    'walker_wipe_hotkey': '{',
    'window_width': 400,  # Default width
    'window_height': 600,  # Default height
    'window_x': 100,  # Default x position
    'window_y': 100,  # Default y position,
    'healer_status': False,  # Default OFF
    'targeter_status': True,  # Default ON
    'walker_status': False,  # Default OFF
    'cure_hotkey': ',',
    'cure_status': True,  # Default ON
}

config_data = default_config_data.copy()  # Start with defaults

# ThreadPool for task execution
executor = ThreadPoolExecutor(max_workers=6)

# Global timestamp for tracking last heal time
last_heal_time = 0

# Determine if the program is frozen (i.e., running as an executable)

def get_resource_path(relative_path):
    """ Get the absolute path to the resource, works for both development and PyInstaller .exe """
    try:
        # PyInstaller stores temp files in _MEIPASS when frozen
        base_path = sys._MEIPASS
    except AttributeError:
        base_path = os.path.abspath(".")

    return os.path.join(base_path, relative_path)

# Load the AutoItX3_x64.dll from the correct location
dll_path = get_resource_path('AutoItX3_x64.dll')  # Correct path, no need for 'autoit/lib' subdirectory
try:
    ctypes.windll.LoadLibrary(dll_path)
    print(f"[DEBUG]: Successfully loaded {dll_path}")
except Exception as e:
    print(f"[ERROR]: Failed to load {dll_path} - {e}")

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

def update_cure_status(new_status):
    """Update cure status dynamically and save to config."""
    config_data['cure_status'] = new_status
    save_config()

def update_targeter_status(new_status):
    """Update targeter status dynamically and save to config."""
    config_data['targeter_status'] = new_status
    save_config()

def update_walker_status(new_status):
    """Update walker status dynamically and save to config."""
    config_data['walker_status'] = new_status
    save_config()

# Function to set a hotkey and save it to the config
# Global dictionary to store hotkey references
hotkey_registry = {}

import tkinter.messagebox as messagebox

def set_hotkey(hotkey_name, entry_widget):
    new_hotkey = entry_widget.get().strip()  # Get the hotkey value and trim any extra spaces
    if new_hotkey:
        try:
            # Validate if it's a valid hotkey
            keyboard.parse_hotkey_combinations(new_hotkey)
        except ValueError as e:
            messagebox.showerror("Invalid Hotkey", f"Hotkey '{new_hotkey}' is not valid. Please try again.")
            return  # Exit the function if the hotkey is invalid

        # Remove the old hotkey listener if it exists
        old_hotkey = hotkey_registry.get(hotkey_name)
        if old_hotkey:
            keyboard.remove_hotkey(old_hotkey)  # Remove the old hotkey binding

        # Update the config_data with the new hotkey
        config_data[hotkey_name] = new_hotkey
        save_config()  # Save the updated config
        print(f"[CONFIG UPDATE]: {hotkey_name} set to {new_hotkey}")

        # Add the new hotkey listener and store the handler in the registry
        hotkey_registry[hotkey_name] = keyboard.add_hotkey(new_hotkey, lambda: hotkey_action(hotkey_name))

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
#            else:
#                print(f"[PROCESS DEBUG]: {PROCESS_NAME} not found. Reattempting connection...")
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
#        print(f"[MEMORY DEBUG]: Failed to read memory at offset {hex(offset)}")
        return None
    except Exception as e:
        print(f"[ERROR]: Failed to read memory at offset {hex(offset)}: {e}")
        return None

# Perform targeting in its own thread
def perform_targeting():
    """Handle targeting in an optimized, non-blocking manner."""
    if not running:
        print("[TARGETING DEBUG]: Exiting perform_targeting as 'running' is set to False.")
        return

    # Check if targeting is enabled at the start to avoid unnecessary operations
    if not config_data['targeter_status']:
#        print("[TARGETING DEBUG]: Targeting is disabled, checking again in 500ms.")
        root.after(500, perform_targeting)  # Schedule the next check
        return

#    print("[TARGETING DEBUG]: Targeting is enabled.")

    if pm is None:
        print("[TARGETING DEBUG]: No process found, attempting to attach...")
        attach_to_process()  # Reconnect if the process is lost

    # Read memory values and handle errors gracefully
    mode = read_memory(0xAC1D70)  # Game mode (1 means in attack mode)
    target_type = read_memory(0xBEFB04)  # Current target type
    chat_open = read_memory(0x9B6998)  # Is the chat window open?
    target_type = read_memory(0xBEFB04)
#   Monster = 1 NPC = 2 Player = 3    
    if target_type == 3:
        print ("[Targeting Debug] pvp says stop")
        root.after(500, perform_targeting) #player targeted retry after 500ms
        
    if mode is None or target_type is None or chat_open is None:
        print("[TARGETING ERROR]: Failed to read one or more memory values, retrying...")
        root.after(500, perform_targeting)  # Retry after 500ms
        return

    # Output current memory values for debugging
#    print(f"[TARGETING DEBUG]: Mode: {mode}, Target Type: {target_type}, Chat Open: {chat_open}")

    # Pause if chat is open (do nothing while chat is open)
    if chat_open == 1:
        print("[TARGETING DEBUG]: Chat window is open, pausing targeting.")
        root.after(500, perform_targeting)  # Retry after 500ms
        return
        


    # If mode is attack (1) and no target or invalid target (65535), send 'Tab' to find a target
    if mode == 1 and (target_type == 0 or target_type == 65535):
        print("[TARGETING DEBUG]: In attack mode with no valid target, sending 'Tab'...")
        control_send_to_project_rogue("{TAB}")


    # Schedule the next targeting check after 500ms
#    print("[TARGETING DEBUG]: Scheduling the next targeting check in 500ms.")
    root.after(500, perform_targeting)

# Curing thread
import time

last_heal_time = 0  # Initial value for global variable

def perform_cure():
    global last_heal_time

    if not running:
        return

    if config_data['cure_status']:
        if pm is None:
            attach_to_process()  # Reconnect if the process is lost

        current_time = time.time() * 1000  # Current time in milliseconds
        pot_delay = config_data['pot_delay']

        # Check if the required pot delay time has passed
        if current_time - last_heal_time >= pot_delay:
            sickness = read_memory(0x9BFB68)
            chat_open = read_memory(0x9B6998)

            # Pause if chat is open
            if chat_open == 1:
                print("[Cure DEBUG]: Chat is open, pausing Cure.")
                root.after(500, perform_cure)  # Reschedule after 500ms
                return

            # Check if healing is required
            if sickness in {1, 2, 65, 66, 98, 8193, 16449}:  # Poisoned
                control_send_to_project_rogue("3")  # Send Cure command
                last_heal_time = current_time
                root.after(50, perform_cure)
            else:
                # Print the sickness value and reschedule the next check
                print(f"Sickness: {sickness}")
                root.after(500, perform_cure)
            return

        # Reschedule the next healing check after 100ms if pot delay hasn't passed
        root.after(100, perform_cure)
    else:
        # If healing is off, reschedule the next check after 500ms
        root.after(500, perform_cure)


# Healing thread
def perform_healing():
    global last_heal_time

    if not running:
        return

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
            sickness = read_memory(0x9BFB68)
            
            # Pause if chat is open
            if chat_open == 1:
#                print("[HEALER DEBUG]: Chat is open, pausing healing.")
                root.after(100, perform_healing)  # Reschedule after 500ms
                return
            if sickness in  (1, 2, 65, 66, 98, 8193, 8257,16449) :
#                print("[HEALER IS SICK1]: Healer is Poisoned, pausing healing.")
                root.after(100, perform_healing)  # Reschedule after 500ms
                return

            
            # If memory read fails, skip this cycle
            if real_hp is None or max_hp is None:
#                print("[HEALER IS SICK]: Healer is Errored, pausing healing.")
                root.after(1000, perform_healing)
                return

            # Calculate current HP percentage
            real_hp_scaled = real_hp / 65535
            heal_percent = config_data['heal_percent'] / 100.0  # Convert percentage to a float

            # Check if healing is required
            if real_hp_scaled < (max_hp * heal_percent):
#                print("[HEALER IS Healing]: Healer is healing.")
                control_send_to_project_rogue("2")  # Send heal command
                last_heal_time = current_time

        # Reschedule the next healing check after 500ms
        root.after(500, perform_healing)


#Hotkey Actions
def hotkey_action(hotkey_name):
    if hotkey_name == 'healer_hotkey':
        toggle_healer_status()
    elif hotkey_name == 'cure_hotkey':
        toggle_cure_status()
    elif hotkey_name == 'targeter_hotkey':
        toggle_targeter_status()
    elif hotkey_name == 'walker_hotkey':
        toggle_walker_status()
    elif hotkey_name == 'walker_set_hotkey':
        print("[HOTKEY]: Walker Set triggered")
    elif hotkey_name == 'walker_wipe_hotkey':
        print("[HOTKEY]: Walker Wipe triggered")

def refresh_hotkey_listeners():
    # Remove and rebind all hotkey listeners after changes
    keyboard.clear_all_hotkeys()  # Clear all existing hotkeys
    hotkey_listener()  # Re-register hotkey listener with updated config

def control_send_to_project_rogue(key, retry_count=0, delay=400):
    """Control sends the key to the Project Rogue window using AutoIt's ControlSend, with retries."""
    try:
        if autoit.win_exists(TARGET_WINDOW_NAME):
            chat_open = read_memory(0x9B6998)
            if chat_open == 1:
                print("ControlSend DEBUG Chat open")
                threading.Timer(delay / 400, control_send_to_project_rogue, [key, retry_count - 0, delay]).start()
                return  # Exit if chat is open
            
            try:
                autoit.control_send(TARGET_WINDOW_NAME, "", key)
                print(f"[AUTOIT DEBUG]: Sent {key} to {TARGET_WINDOW_NAME}")
            except autoit.AutoItError as e:
                print(f"[AUTOIT ERROR]: {e}")
                if retry_count > 0:
                    print(f"[AUTOIT DEBUG]: Retrying in 2 seconds... {retry_count} retries left.")
                    root.after(2000, lambda: control_send_to_project_rogue(key, retry_count - 1))
        else:
            print(f"[AUTOIT ERROR]: Window '{TARGET_WINDOW_NAME}' not found.")
            if retry_count > 0:
                print(f"[AUTOIT DEBUG]: Retrying in 2 seconds... {retry_count} retries left.")
                root.after(2000, lambda: control_send_to_project_rogue(key, retry_count - 1))

    except OSError as os_error:
        print(f"[AUTOIT ERROR]: OSError encountered while checking window: {os_error}")
        if retry_count > 0:
            print(f"[AUTOIT DEBUG]: Retrying in 2 seconds... {retry_count} retries left.")
            root.after(2000, lambda: control_send_to_project_rogue(key, retry_count - 1))


# Hotkey listener for toggling status
def hotkey_listener():
    # Toggle healer status hotkey
    keyboard.add_hotkey(config_data['healer_hotkey'], lambda: toggle_healer_status())

    # Toggle targeter status hotkey
    keyboard.add_hotkey(config_data['targeter_hotkey'], lambda: toggle_targeter_status())

    # Toggle walker status hotkey
    keyboard.add_hotkey(config_data['walker_hotkey'], lambda: toggle_walker_status())
    
    # Toggle cure status hotkey
    keyboard.add_hotkey(config_data['cure_hotkey'], lambda: toggle_cure_status())

def toggle_healer_status():
    new_status = not config_data['healer_status']
    update_healer_status(new_status)
    root.after(0, lambda: healer_status_label.config(bg="green" if new_status else "red"))
    root.after(0, lambda: healer_status_label.config(text=f"Healer: {'ON' if new_status else 'OFF'}"))

def toggle_cure_status():
    new_status = not config_data['cure_status']
    update_cure_status(new_status)
#    print ("Cure Status Change")
    root.after(0, lambda: cure_status_label.config(bg="green" if new_status else "red"))
    root.after(0, lambda: cure_status_label.config(text=f"Cure: {'ON' if new_status else 'OFF'}"))

def toggle_targeter_status():
    new_status = not config_data['targeter_status']
    update_targeter_status(new_status)
    root.after(0, lambda: targeter_status_label.config(bg="green" if new_status else "red"))
    root.after(0, lambda: targeter_status_label.config(text=f"Targeter: {'ON' if new_status else 'OFF'}"))

def toggle_walker_status():
    new_status = not config_data['walker_status']
    update_walker_status(new_status)
    root.after(0, lambda: walker_status_label.config(bg="green" if new_status else "red"))
    root.after(0, lambda: walker_status_label.config(text=f"Walker: {'ON' if new_status else 'OFF'}"))

# Update memory display in the GUI
def update_memory_display():
    if not running:
        return

    if pm is None:
        attach_to_process()  # Reconnect if the process is lost

    real_hp = read_memory(0x9BF988)
    max_hp = read_memory(0x9BF98C)
    pos_x = read_memory(0xBF2C70)
    pos_y = read_memory(0xBF2C68)
    sickness = read_memory(0x9BFB68)
    chat_open = read_memory(0x9B6998)
    mode = read_memory(0xAC1D70)
    target_type = read_memory(0xBEFB04)

    # Scale HP
    real_hp_scaled = real_hp / 65535 if real_hp else 0

    # Update the GUI elements only if the values have changed
    root.after(0, lambda: hp_label.config(text=f"Real HP: {real_hp_scaled:.2f} | Max HP: {max_hp}" if real_hp and max_hp else "Real HP: N/A | Max HP: N/A"))
    root.after(0, lambda: posx_label.config(text=f"PosX: {pos_x}" if pos_x else "PosX: N/A"))
    root.after(0, lambda: posy_label.config(text=f"PosY: {pos_y}" if pos_y else "PosY: N/A"))
    sickness_status = 'Poison' if sickness == 1 else 'Disease' if sickness == 2 else 'Vampirism' if sickness == 64 else 'Poison' if sickness == 65 else 'Disease' if sickness == 66 else 'Poison' if sickness == 98 else 'Poison' if sickness == 8193 else 'Vamp+Blood' if sickness == 8256 else 'Exhausted' if sickness == 16384 else 'Vamp+Exh' if sickness == 16448 else {sickness}
    root.after(0, lambda: sickness_label.config(text=f"Sickness: {sickness_status}"))
    chat_status = 'Yes' if chat_open == 1 else 'No'
    root.after(0, lambda: chat_label.config(text=f"Chat Open: {chat_status}"))
    mode_status = 'Attack' if mode == 1 else 'None'
    root.after(0, lambda: mode_label.config(text=f"Mode: {mode_status}"))
    target_type_str = "Monster" if target_type == 1 else "NPC" if target_type == 2 else "Player" if target_type == 3 else "None"
    root.after(0, lambda: type_label.config(text=f"Type: {target_type_str}"))

    # Schedule the function to run again after 500 ms (0.5 seconds)
    root.after(500, update_memory_display)

# Exit the script/program and stop all threads
def stop_threads_and_exit():
    global running
    running = False
    print("[EXIT DEBUG]: Stopping all threads...")
    time.sleep(0.3)
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

def gui_start():
    print(f"Start of GUI CODE")
    
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

# Cure Hotkey
cure_hotkey_label = tk.Label(hotkey_frame, text="Cure Hotkey:")
cure_hotkey_label.grid(row=1, column=0, sticky='w')
cure_hotkey_entry = tk.Entry(hotkey_frame)
cure_hotkey_entry.insert(0, config_data['cure_hotkey'])
cure_hotkey_entry.grid(row=1, column=1)
cure_status_label = tk.Label(hotkey_frame, text="Cure: OFF" if not config_data['cure_status'] else "Cure: ON", bg="red" if not config_data['cure_status'] else "green", fg="white")
cure_status_label.grid(row=1, column=2)
save_cure_button = tk.Button(hotkey_frame, text="Save Cure Hotkey", command=lambda: set_hotkey('cure_hotkey', cure_hotkey_entry))
save_cure_button.grid(row=1, column=3)

# Targeter Hotkey
targeter_hotkey_label = tk.Label(hotkey_frame, text="Targeter Hotkey:")
targeter_hotkey_label.grid(row=2, column=0, sticky='w')
targeter_hotkey_entry = tk.Entry(hotkey_frame)
targeter_hotkey_entry.insert(0, config_data['targeter_hotkey'])
targeter_hotkey_entry.grid(row=2, column=1)
targeter_status_label = tk.Label(hotkey_frame, text="Targeter: OFF" if not config_data['targeter_status'] else "Targeter: ON", bg="red" if not config_data['targeter_status'] else "green", fg="white")
targeter_status_label.grid(row=2, column=2)
save_targeter_button = tk.Button(hotkey_frame, text="Save Targeter Hotkey", command=lambda: set_hotkey('targeter_hotkey', targeter_hotkey_entry))
save_targeter_button.grid(row=2, column=3)

# Walker Hotkey
walker_hotkey_label = tk.Label(hotkey_frame, text="Walker Hotkey:")
walker_hotkey_label.grid(row=3, column=0, sticky='w')
walker_hotkey_entry = tk.Entry(hotkey_frame)
walker_hotkey_entry.insert(0, config_data['walker_hotkey'])
walker_hotkey_entry.grid(row=3, column=1)
walker_status_label = tk.Label(hotkey_frame, text="Walker: OFF" if not config_data['walker_status'] else "Walker: ON", bg="red" if not config_data['walker_status'] else "green", fg="white")
walker_status_label.grid(row=3, column=2)
save_walker_button = tk.Button(hotkey_frame, text="Save Walker Hotkey", command=lambda: set_hotkey('walker_hotkey', walker_hotkey_entry))
save_walker_button.grid(row=3, column=3)

# WalkerSet Hotkey
walkerset_hotkey_label = tk.Label(hotkey_frame, text="WalkerSet Hotkey:")
walkerset_hotkey_label.grid(row=4, column=0, sticky='w')
walkerset_hotkey_entry = tk.Entry(hotkey_frame)
walkerset_hotkey_entry.insert(0, config_data['walker_set_hotkey'])
walkerset_hotkey_entry.grid(row=4, column=1)
save_walkerset_button = tk.Button(hotkey_frame, text="Save WalkerSet Hotkey", command=lambda: set_hotkey('walker_set_hotkey', walkerset_hotkey_entry))
save_walkerset_button.grid(row=4, column=3)

# WalkerWipe Hotkey
walkerwipe_hotkey_label = tk.Label(hotkey_frame, text="WalkerWipe Hotkey:")
walkerwipe_hotkey_label.grid(row=5, column=0, sticky='w')
walkerwipe_hotkey_entry = tk.Entry(hotkey_frame)
walkerwipe_hotkey_entry.insert(0, config_data['walker_wipe_hotkey'])
walkerwipe_hotkey_entry.grid(row=5, column=1)
save_walkerwipe_button = tk.Button(hotkey_frame, text="Save WalkerWipe Hotkey", command=lambda: set_hotkey('walker_wipe_hotkey', walkerwipe_hotkey_entry))
save_walkerwipe_button.grid(row=5, column=3)

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

# Left side instructions
left_frame = ttk.Frame(root, padding="5")
left_frame.pack(side="left", padx=5, pady=5)

pots_label = tk.Label(left_frame, text="Pots go in #2", font=("Arial", 8))
pots_label.pack(side="top", pady=5)

cures_label = tk.Label(left_frame, text="GREATER Cures in #3", font=("Arial", 8))
cures_label.pack(side="top", pady=5)

thanks_label = tk.Label(left_frame, text="Thanks GusToughSon", font=("Arial", 8))
thanks_label.pack(side="top", pady=5)

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
threading.Thread(target=perform_cure).start()  # cure thread

root.mainloop()