#!/bin/bash

# Ensure mouse and keyboard output files are provided
if [ -z "$1" ] || [ -z "$2" ]; then
  echo "Error: output files for mouse and keyboard counts are required"
  exit 1
fi

mouse_output_file=$1
keyboard_output_file=$2

# Initialize counters
mouse_clicks=0
keyboard_clicks=0

# Function to write counts to files
write_counts() {
  echo "$mouse_clicks" > "$mouse_output_file"
  echo "$keyboard_clicks" > "$keyboard_output_file"
}

# Initialize files with zero counts
write_counts

# Create named pipes for communication
mouse_pipe="/tmp/mouse_events_$$"
keyboard_pipe="/tmp/keyboard_events_$$"
mkfifo "$mouse_pipe" "$keyboard_pipe"

# Function to track X11 mouse and keyboard input events
track_x11_input() {
  # Start xinput in background and redirect to pipes
  xinput --test-xi2 --root | grep -E "EVENT type [36]" | while read -r line; do
    if [[ $line =~ "EVENT type 3" ]] && [[ $line =~ "detail: [13]" ]]; then
      echo "mouse" > "$mouse_pipe"
    elif [[ $line =~ "EVENT type 6" ]] && [[ $line =~ "PRESS" ]]; then
      echo "keyboard" > "$keyboard_pipe"
    fi
  done &
}

# Function to track Wayland mouse and keyboard input events
track_wayland_input() {
  # Start libinput in background and redirect to pipes
  libinput debug-events --show-keycodes | grep -E "(BUTTON_PRESS|KEYBOARD_KEY)" | while read -r line; do
    if [[ $line =~ "BUTTON_PRESS" ]] && [[ $line =~ "27[23]" ]]; then
      echo "mouse" > "$mouse_pipe"
    elif [[ $line =~ "KEYBOARD_KEY" ]] && [[ $line =~ "pressed" ]]; then
      echo "keyboard" > "$keyboard_pipe"
    fi
  done &
}

# Function to read from pipes and update counters
process_events() {
  while true; do
    # Check mouse pipe
    if read -t 0.1 event < "$mouse_pipe" 2>/dev/null; then
      if [[ $event == "mouse" ]]; then
        mouse_clicks=$((mouse_clicks + 1))
        echo "Mouse count $mouse_clicks"
        write_counts
      fi
    fi
    
    # Check keyboard pipe
    if read -t 0.1 event < "$keyboard_pipe" 2>/dev/null; then
      if [[ $event == "keyboard" ]]; then
        keyboard_clicks=$((keyboard_clicks + 1))
        echo "Keyboard count $keyboard_clicks"
        write_counts
      fi
    fi
    
    sleep 0.1
  done
}

# Reset counts every minute
reset_counts() {
  while true; do
    sleep 60
    mouse_clicks=0
    keyboard_clicks=0
    write_counts
    echo "Counts reset"
  done
}

# Cleanup function
cleanup() {
  rm -f "$mouse_pipe" "$keyboard_pipe"
  pkill -P $$
  exit 0
}

# Set up signal handlers
trap cleanup EXIT INT TERM

# Start tracking input and reset counts every minute
if [ -n "$WAYLAND_DISPLAY" ]; then
  track_wayland_input
elif [ -n "$DISPLAY" ]; then
  track_x11_input
else
  echo "Error: Neither Wayland nor X11 display server detected." >&2
  exit 1
fi

# Start background processes
reset_counts &
process_events
