#!/bin/bash

# Ensure output file is provided
if [ -z "$1" ]; then
  echo "Error: output file argument is required"
  exit 1
fi

output_file=$1

# Function to track input events
track_input() {
  /usr/bin/log stream --predicate 'eventMessage contains "Mouse" or eventMessage contains "Keyboard"' --style json | jq -r 'select(.eventMessage | contains("Mouse") or contains("Keyboard")) | .eventMessage' > "$output_file"
}

track_input
