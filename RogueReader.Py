import tkinter as tk
import pymem
import pymem.process
import time
import threading
import psutil  # Required for killing the process
import win32gui  # Required for finding window handles
import win32con  # Required for sending key inputs
import win32api  # Required for sending key events
import struct  # Required for binary read/write
import os  # Required for file operations

# Debugging flag
DEBUG = True  # Set to False to disable debug messages

# Memory offsets
MEMORY_OFFSET_POSX = 0xBF2C58
MEMORY_OFFSET_POSY = 0xBF2C50
MEMORY_OFFSET_SICKNESS = 0xBF0D50
MEMORY_OFFSET_CHAT = 0x9B6998
MEMORY_OFFSET_MODE = 0xAC1D60
MEMORY_OFFSET_TYPE = 0xBEFA34
MEMORY_OFFSET_MAXHP = 0x9BF98C
MEMORY_OFFSET_HP = 0x9BF988

# Define variables to store the memory values
pos_x = 0
pos_y = 0
sickness = 0
chat = 0
mode = 0
type_val = 0
hp = 0
max_hp = 65535  # Assuming MaxHP is a constant value for now
real_hp = 0  # New variable for RealHP

# Config file path
CONFIG_FILE = "slider_config.dat"
DEFAULT_SLEEP_TIME = 0.30  # Default if no config is present
sleep_time = DEFAULT_SLEEP_TIME  # Initial sleep time

# Process information
PROCESS_NAME = "Project Rogue Client.exe"  # Full executable name
PROCESS_PID = 18268  # The specific PID of the process
WINDOW_NAME = "Project Rogue"  # The window title of the game

# Initialize memory reading process (global)
pm = None
process_attached = False  # To track if the process is attached

# Debug function
def debug(message):
    if DEBUG:
        print("[DEBUG]:", message)

# Function to read memory safely
def read_memory(offset):
    global pm
    try:
        base_address = pymem.process.module_from_name(pm.process_handle, PROCESS_NAME).lpBaseOfDll
        value = pm.read_int(base_address + offset)
        debug(f"Read memory from offset {hex(offset)}: {value}")
        return value
    except Exception as e:
        debug(f"Error reading memory at offset {hex(offset)}: {e}")
        return -1

# Function to send keys directly to the Project Rogue window
def control_send_to_game(key):
    try:
        hwnd = win32gui.FindWindow(None, WINDOW_NAME)
        if hwnd != 0:
            debug(f"Sending key '{key}' to window: {WINDOW_NAME}")
            win32api.PostMessage(hwnd, win32con.WM_KEYDOWN, ord(key), 0)  # Send key down
            win32api.PostMessage(hwnd, win32con.WM_KEYUP, ord(key), 0)  # Send key up
        else:
            debug(f"Window '{WINDOW_NAME}' not found.")
    except Exception as e:
        debug(f"Error sending key '{key}' to window '{WINDOW_NAME}': {e}")

# Function to update variables from memory
def update_vars():
    global pos_x, pos_y, sickness, chat, mode, type_val, hp, max_hp, real_hp, sleep_time
    while True:
        if pm and process_attached:  # Check if process is attached
            debug("Updating variables from memory...")
            pos_x = read_memory(MEMORY_OFFSET_POSX)
            pos_y = read_memory(MEMORY_OFFSET_POSY)
            sickness = read_memory(MEMORY_OFFSET_SICKNESS)
            chat = read_memory(MEMORY_OFFSET_CHAT)
            mode = read_memory(MEMORY_OFFSET_MODE)
            type_val = read_memory(MEMORY_OFFSET_TYPE)
            hp = read_memory(MEMORY_OFFSET_HP)
            max_hp = read_memory(MEMORY_OFFSET_MAXHP)

            # Calculate RealHP as hp / 65535
            if hp != -1:
                real_hp = hp / 65535  # Real HP calculation
                debug(f"Calculated Real HP: {real_hp}")
        else:
            debug("Waiting for process to be available or reattach...")
        
        time.sleep(sleep_time)  # Use the dynamically adjustable sleep_time

# Function to get the display string for Sickness
def get_sickness_string(sickness):
    if sickness == 1:
        return "Poison"
    elif sickness == 2:
        return "Disease"
    else:
        return "None"

# Function to get the display string for Mode
def get_mode_string(mode):
    if mode == 0:
        return "None"
    elif mode == 1:
        return "Attack"
    else:
        return "Unknown"

# Function to get the display string for Type
def get_type_string(type_val):
    if type_val == 0 or type_val == 65535:  # Treat 65535 as "None"
        return "None"
    elif type_val == 1:
        return "NPC"
    elif type_val == 2:
        return "Player"
    else:
        return "Unknown"

# Function to update the GUI
def update_gui():
    global pos_x, pos_y, sickness, chat, mode, type_val, real_hp, max_hp
    while True:
        posx_label.config(text=f"Map PosX: {pos_x}")
        posy_label.config(text=f"Map PosY: {pos_y}")
        hp_label.config(text=f"Real HP: {real_hp:.2f}  |  Max HP: {max_hp:.2f}")
        sickness_label.config(text=f"Sickness: {get_sickness_string(sickness)}")
        mode_label.config(text=f"Mode: {get_mode_string(mode)}")
        chat_label.config(text=f"Chat Open: {'Yes' if chat != 0 else 'No'}")
        type_label.config(text=f"Type: {get_type_string(type_val)}")
        time.sleep(0.1)  # Fast GUI updates

# Function to adjust the sleep time using the slider
def adjust_sleep_time(val):
    global sleep_time
    sleep_time = float(val)
    debug(f"Updated sleep time to {sleep_time} seconds")
    save_slider_value()  # Save the slider value whenever it's adjusted

# Function to save slider value to binary config file
def save_slider_value():
    global sleep_time
    with open(CONFIG_FILE, 'wb') as f:
        packed_data = struct.pack('f', sleep_time)  # Pack as binary float
        f.write(packed_data)
        debug(f"Saved slider value {sleep_time} to {CONFIG_FILE}")

# Function to load slider value from binary config file
def load_slider_value():
    global sleep_time
    if os.path.exists(CONFIG_FILE):
        try:
            with open(CONFIG_FILE, 'rb') as f:
                packed_data = f.read(4)  # Read 4 bytes (float size)
                sleep_time = struct.unpack('f', packed_data)[0]  # Unpack binary data
                debug(f"Loaded slider value {sleep_time} from {CONFIG_FILE}")
        except Exception as e:
            debug(f"Error reading config file {CONFIG_FILE}: {e}")
            sleep_time = DEFAULT_SLEEP_TIME
    else:
        sleep_time = DEFAULT_SLEEP_TIME
        debug(f"No config found. Using default sleep time {DEFAULT_SLEEP_TIME}")

# Function to initialize the process memory reader
def initialize_memory_reader():
    global pm, process_attached
    while True:
        try:
            if not process_attached:  # If not attached, try to attach
                debug(f"Attempting to attach to process: {PROCESS_NAME}")
                pm = pymem.Pymem(PROCESS_NAME)
                process_attached = True
                debug(f"Successfully attached to process {PROCESS_NAME}")
            else:
                if not psutil.pid_exists(pm.process_id):
                    debug(f"Process {PROCESS_NAME} terminated. Attempting to reattach...")
                    process_attached = False
        except pymem.exception.ProcessNotFound:
            debug(f"Could not find process: {PROCESS_NAME}. Retrying...")
            time.sleep(2)  # Retry every 2 seconds
        except Exception as e:
            debug(f"Error initializing memory reader: {e}")
            root.quit()

# Function to kill the Project Rogue process
def kill_rogue_process():
    try:
        proc = psutil.Process(PROCESS_PID)  # Get the process by PID
        debug(f"Attempting to kill process with PID {PROCESS_PID}")
        proc.terminate()  # Terminate the process
        debug(f"Successfully killed Project Rogue process with PID {PROCESS_PID}")
        tk.messagebox.showinfo("Success", "Project Rogue has been killed.")
    except Exception as e:
        debug(f"Failed to kill process with PID {PROCESS_PID}: {e}")
        tk.messagebox.showerror("Error", f"Failed to kill Project Rogue: {e}")

# GUI setup
root = tk.Tk()
root.title("RogueReader - Memory Values")
root.geometry("400x300+10+10")  # Launch GUI at position (10, 10)

# Labels to display memory values
posx_label = tk.Label(root, text="Map PosX: 0")
posx_label.pack()

posy_label = tk.Label(root, text="Map PosY: 0")
posy_label.pack()

hp_label = tk.Label(root, text="Real HP: 0.00  |  Max HP: 0.00")
hp_label.pack()

sickness_label = tk.Label(root, text="Sickness: None")
sickness_label.pack()

mode_label = tk.Label(root, text="Mode: None")
mode_label.pack()

chat_label = tk.Label(root, text="Chat Open: No")
chat_label.pack()

type_label = tk.Label(root, text="Type: None")
type_label.pack()

# Slider to adjust the sleep time for GUI updates
slider_label = tk.Label(root, text="Adjust Update Speed (Sleep Time in seconds)")
slider_label.pack()

sleep_slider = tk.Scale(root, from_=0.05, to=1.0, orient=tk.HORIZONTAL, resolution=0.01, command=adjust_sleep_time)
sleep_slider.pack()

# Load slider value from config and set the slider to the saved value
load_slider_value()
sleep_slider.set(sleep_time)  # Set the default slider value from config

# Button to toggle debug messages on and off
def toggle_debug():
    global DEBUG
    DEBUG = not DEBUG
    debug_label.config(text=f"Debugging: {'On' if DEBUG else 'Off'}")
    debug(f"Debug mode {'enabled' if DEBUG else 'disabled'}")

debug_label = tk.Label(root, text=f"Debugging: {'On' if DEBUG else 'Off'}")
debug_label.pack()

debug_button = tk.Button(root, text="Toggle Debug", command=toggle_debug)
debug_button.pack()

# Kill Rogue button
kill_button = tk.Button(root, text="Kill Rogue", command=kill_rogue_process)
kill_button.pack()

# Exit button
exit_button = tk.Button(root, text="Exit", command=root.quit)
exit_button.pack()

# Start memory reader in a separate thread so GUI doesn't freeze
threading.Thread(target=initialize_memory_reader, daemon=True).start()

# Start threads for updating values and GUI
threading.Thread(target=update_vars, daemon=True).start()
threading.Thread(target=update_gui, daemon=True).start()

# Start the GUI loop
root.mainloop()
