#!/bin/bash

output_file="/tmp/app_usage.txt"

# Function to get the active window information for Wayland (GNOME/KDE)
get_wayland_active_window() {
  # Detect the Wayland compositor
  if [ -n "$(pgrep -x gnome-shell)" ]; then
    # GNOME Shell (Mutter)
    app_name="gnome-shell"
    echo "[{\"app_name\":\"$app_name\"}]"
  elif [ -n "$(pgrep -x kwin_x11)" ]; then
    # KDE KWin
    app_name="kwin"
    echo "[{\"app_name\":\"$app_name\"}]"
  else
    echo "Error: Unsupported Wayland compositor" >&2
    echo "[{\"app_name\":\"null\"}]"
  fi
}

# Function to get the active window information for X11
get_x11_active_window() {
  window_id=$(xprop -root | awk '/_NET_ACTIVE_WINDOW\(WINDOW\)/{print $NF}')
  if [ -z "$window_id" ]; then
    echo "Error: No active window found." >&2
    echo "[{\"app_name\":\"null\"}]"
  else
    app_name=$(xprop -id "$window_id" WM_CLASS | awk -F '"' '{print $(NF-1)}')
    echo "[{\"app_name\":\"$app_name\"}]"
  fi
}

# Check if running under Wayland or X11
if [ -n "$WAYLAND_DISPLAY" ]; then
  app_usage=$(get_wayland_active_window)
elif [ -n "$DISPLAY" ]; then
  app_usage=$(get_x11_active_window)
else
  echo "Error: Neither Wayland nor X11 display server detected." >&2
  echo "[{\"app_name\":\"null\"}]"
fi

# Save to file
echo "$app_usage" > "$output_file"

# Output the content of the file
cat "$output_file"
