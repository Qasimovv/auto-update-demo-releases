#!/bin/bash

# Output file path
output_file="/tmp/app_usage.txt"

# Capture active application name and window title
app_name=$(osascript -e 'tell application "System Events" to get the name of the first application process whose frontmost is true')

# Save to file
echo "{\"app_name\":\"$app_name\"> "$output_file"

# Output the content of the file
cat "$output_file"
