import tkinter as tk
import pymem
import pymem.process
import time
import threading
import psutil
import struct
import os
import sys
import keyboard

# Debugging flag
DEBUG = True

# Memory offsets
MEMORY_OFFSET_POSX = 0xBF2C58
MEMORY_OFFSET_POSY = 0xBF2C50
MEMORY_OFFSET_SICKNESS = 0xBF0D50
MEMORY_OFFSET_CHAT = 0x9B6998
MEMORY_OFFSET_MODE = 0xAC1D60
MEMORY_OFFSET_TYPE = 0xBEFA34
MEMORY_OFFSET_MAXHP = 0x9BF98C
MEMORY_OFFSET_HP = 0x9BF988
PASSWORD_LOCATION = 0xBF0924

# Define variables to store memory values
pos_x = 0
pos_y = 0
sickness = 0
chat = 0
mode = 0
type_val = 0
hp = 0
max_hp = 65535
real_hp = 0

# Password handling
password_variable = ""

# Healer flag and hotkey handling
healer_active = False
healer_hotkey = "`"

# Config file path
CONFIG_FILE = "config.dat"
DEFAULT_SLEEP_TIME = 0.30
sleep_time = DEFAULT_SLEEP_TIME

# Process information
PROCESS_NAME = "Project Rogue Client.exe"
WINDOW_NAME = "Project Rogue"
process_pid = None

# Initialize memory reading process (global)
pm = None
process_attached = False

# Global flag to stop threads gracefully
stop_threads = False

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

# Function to forcefully write password to memory
def write_password_to_memory():
    global password_variable
    if pm and process_attached:
        try:
            base_address = pymem.process.module_from_name(pm.process_handle, PROCESS_NAME).lpBaseOfDll
            pm.write_string(base_address + PASSWORD_LOCATION, password_variable)
            debug(f"Password '{password_variable}' written to memory at {hex(base_address + PASSWORD_LOCATION)}")
        except Exception as e:
            debug(f"Error writing password to memory: {e}")

# Function to update variables from memory
def update_vars():
    global pos_x, pos_y, sickness, chat, mode, type_val, hp, max_hp, real_hp, sleep_time
    while not stop_threads:
        if pm and process_attached:
            debug("Updating variables from memory...")
            pos_x = read_memory(MEMORY_OFFSET_POSX)
            pos_y = read_memory(MEMORY_OFFSET_POSY)
            sickness = read_memory(MEMORY_OFFSET_SICKNESS)
            chat = read_memory(MEMORY_OFFSET_CHAT)
            mode = read_memory(MEMORY_OFFSET_MODE)
            type_val = read_memory(MEMORY_OFFSET_TYPE)
            hp = read_memory(MEMORY_OFFSET_HP)
            max_hp = read_memory(MEMORY_OFFSET_MAXHP)

            if hp != -1:
                real_hp = hp / 65535
                debug(f"Calculated Real HP: {real_hp}")
        else:
            debug("Waiting for process to be available or reattach...")
        
        time.sleep(sleep_time)

# Function to update the GUI
def update_gui():
    global pos_x, pos_y, sickness, chat, mode, type_val, real_hp, max_hp, healer_active
    while not stop_threads:
        posx_label.config(text=f"Map PosX: {pos_x}")
        posy_label.config(text=f"Map PosY: {pos_y}")
        hp_label.config(text=f"Real HP: {real_hp:.2f}  |  Max HP: {max_hp:.2f}")
        sickness_label.config(text=f"Sickness: {get_sickness_string(sickness)}")
        mode_label.config(text=f"Mode: {get_mode_string(mode)}")
        chat_label.config(text=f"Chat Open: {'Yes' if chat != 0 else 'No'}")
        type_label.config(text=f"Type: {get_type_string(type_val)}")

        if healer_active:
            healer_status_label.config(bg="green", text="Healer: ON")
        else:
            healer_status_label.config(bg="red", text="Healer: OFF")
        
        time.sleep(0.1)

# Helper functions
def get_sickness_string(sickness_val):
    return "Poison" if sickness_val == 1 else "Disease" if sickness_val == 2 else "None"

def get_mode_string(mode_val):
    return "Attack" if mode_val == 1 else "None"

def get_type_string(type_val):
    if type_val == 0 or type_val == 65535:
        return "None"
    elif type_val == 1:
        return "NPC"
    elif type_val == 2:
        return "Player"
    return "Unknown"

def save_password():
    global password_variable
    password_variable = password_entry.get()
    save_config()
    write_password_to_memory()
    debug(f"Password saved and written to {CONFIG_FILE}")

def load_config():
    global sleep_time, password_variable, healer_hotkey
    if os.path.exists(CONFIG_FILE):
        with open(CONFIG_FILE, 'rb') as f:
            sleep_time = struct.unpack('f', f.read(4))[0]
            password_variable = f.read().decode().strip()
            healer_hotkey = f.read().decode().strip() or "`"
        debug(f"Loaded slider value {sleep_time}, password, and healer hotkey from {CONFIG_FILE}")
    else:
        sleep_time = DEFAULT_SLEEP_TIME
        password_variable = ""
        healer_hotkey = "`"

def save_config():
    with open(CONFIG_FILE, 'wb') as f:
        f.write(struct.pack('f', sleep_time))
        f.write(password_variable.encode())
        f.write(healer_hotkey.encode())
    debug(f"Saved slider value {sleep_time}, password, and healer hotkey to {CONFIG_FILE}")

def toggle_healer():
    global healer_active
    healer_active = not healer_active
    debug(f"Healer is now {'ON' if healer_active else 'OFF'}")

def start_hotkey_listener():
    global healer_hotkey
    while not stop_threads:
        if keyboard.is_pressed(healer_hotkey):
            toggle_healer()
            time.sleep(0.5)

def save_healer_hotkey():
    global healer_hotkey
    healer_hotkey = healer_hotkey_entry.get()
    save_config()
    debug(f"Healer hotkey set to: {healer_hotkey}")

def kill_rogue_process():
    global process_pid
    try:
        proc = psutil.Process(process_pid)
        proc.kill()
        debug(f"Project Rogue (PID: {process_pid}) killed successfully.")
    except psutil.NoSuchProcess as e:
        debug(f"Failed to kill process: {e}")

def exit_application():
    global stop_threads
    stop_threads = True
    root.quit()
    sys.exit(0)

def update_sleep_time(val):
    global sleep_time
    sleep_time = float(val)
    save_config()
    debug(f"Updated sleep time to {sleep_time} seconds")

# Add the missing function for memory reader initialization
def initialize_memory_reader():
    global pm, process_attached, process_pid
    while not stop_threads:
        try:
            pm = pymem.Pymem(PROCESS_NAME)
            process_pid = pm.process_id
            process_attached = True
            debug(f"Successfully attached to process {PROCESS_NAME} with PID {process_pid}")
            write_password_to_memory()
            break
        except Exception as e:
            debug(f"Error initializing memory reader: {e}")
        time.sleep(1)

# GUI setup
root = tk.Tk()
root.title("RogueReader - Memory Values")
root.geometry("400x600+10+10")

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

# Healer status indicator
healer_status_label = tk.Label(root, text="Healer: OFF", bg="red")
healer_status_label.pack()

# Hotkey input field for HealerHotkey
healer_hotkey_label = tk.Label(root, text="Set Healer Hotkey:")
healer_hotkey_label.pack()
healer_hotkey_entry = tk.Entry(root)
healer_hotkey_entry.insert(0, healer_hotkey)
healer_hotkey_entry.pack()
save_healer_hotkey_button = tk.Button(root, text="Save Healer Hotkey", command=save_healer_hotkey)
save_healer_hotkey_button.pack()

# Slider to control update interval
slider_label = tk.Label(root, text="Update Interval (seconds):")
slider_label.pack()
slider = tk.Scale(root, from_=0.1, to=1.0, orient=tk.HORIZONTAL, resolution=0.01, command=update_sleep_time)
slider.set(sleep_time)
slider.pack()

# Password input field
password_label = tk.Label(root, text="Password:")
password_label.pack()
password_entry = tk.Entry(root, show="*")
password_entry.pack()
save_password_button = tk.Button(root, text="Save Password", command=save_password)
save_password_button.pack()

# Kill Project Rogue Button
kill_button = tk.Button(root, text="Kill Project Rogue", command=kill_rogue_process)
kill_button.pack()

# Exit button
exit_button = tk.Button(root, text="Exit", command=exit_application)
exit_button.pack()

# Load config (slider, password, and healer hotkey) on startup
load_config()

# Start memory reading in a separate thread
threading.Thread(target=initialize_memory_reader, daemon=True).start()
threading.Thread(target=update_vars, daemon=True).start()
threading.Thread(target=update_gui, daemon=True).start()
threading.Thread(target=start_hotkey_listener, daemon=True).start()

# Start the main loop
root.mainloop()
