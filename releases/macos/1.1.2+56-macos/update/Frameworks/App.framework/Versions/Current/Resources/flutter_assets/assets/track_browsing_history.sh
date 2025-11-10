#!/bin/bash

# Define browser process names
BROWSERS=("chrome" "firefox" "brave")

# Loop through all the running processes and check for browsers
for BROWSER in "${BROWSERS[@]}"; do
  # Get the PID of the browser process if it exists
  BROWSER_PID=$(ps aux | grep "$BROWSER" | grep -v 'grep' | awk '{print $2}' | head -n 1)

  if [[ -n "$BROWSER_PID" ]]; then
    # If we found a browser process, extract the command line args to get the window title
    CMDLINE=$(tr '\0' ' ' < /proc/$BROWSER_PID/cmdline)

    # In Chrome, the tab's title or URL is part of the command-line arguments
    if [[ "$BROWSER" == "chrome" ]]; then
      # Chrome: Extract the title or URL from the command line
      TAB_TITLE=$(echo "$CMDLINE" | grep -oP '(?<=--user-data-dir=).+')
      echo "Chrome Tab Title: $TAB_TITLE"
      exit 0
    elif [[ "$BROWSER" == "firefox" ]]; then
      # Firefox: We can attempt to extract something from the command line
      TAB_TITLE=$(echo "$CMDLINE" | grep -oP '(?<=-url ).+')
      echo "Firefox Tab Title: $TAB_TITLE"
      exit 0
    elif [[ "$BROWSER" == "brave" ]]; then
      # Brave: Similar to Chrome, extract title or URL
      TAB_TITLE=$(echo "$CMDLINE" | grep -oP '(?<=--user-data-dir=).+')
      echo "Brave Tab Title: $TAB_TITLE"
      exit 0
    fi
  fi
done

# If no browsers are active or no window title is found, return an empty result
echo ""
